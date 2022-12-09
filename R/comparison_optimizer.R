library(cito)
library(rbenchmark)
library(ggplot2)
library(cowplot)
library(ggpubr)
library(foreach)
library(doParallel)

cl <- makeCluster(20)
registerDoParallel(cl)

sim_data<- function(v,n,r,s){
  
  data<- matrix(runif(n*v),ncol=v,nrow= n)
  
  true_f<- rep(0,v)
  
  true_f[sample(c(1:v),r,replace=F)]<- runif(-1,1,n=r)
  
  Y <- apply(data,1,function(x) { (sum(x * true_f)) + rnorm(mean=0,sd=s,n=1)})
  
  
  df<- as.data.frame(data)
  df<- data.frame(scale(df,center= T, scale= T))
  df$Y<- Y
  
  return(df)
}


k<-400
perf<- data.frame(mae = numeric(), 
                  rmse = numeric(),
                  optimizer = character(),
                  t= numeric())
opt <- c("adam", "adadelta", "adagrad", "rmsprop", "rprop", "sgd")

perf <- foreach(i = c(1:k),.combine=rbind) %dopar% {

  v<- sample(c(2:30),1)
  data <- sim_data(v= v,
                  r= sample(c(1:v),1),
                  n= 1000, 
                  s= abs(rnorm(mean=0,sd=0.4,n=1)))
  
  p<- data.frame(mae = rep(NA,6), 
                 rmse = rep(NA,6),
                 optimizer = rep("na",6),
                 t= rep(NA,6))
  
  for(o in c(1:length(opt))){
    a<- rbenchmark::benchmark(fit <- cito::dnn(Y~., data= data[1:800,], optimizer = opt[o],epochs= 32,loss= "mse",plot=F,verbose=F),replications = 1)
    p$mae[o] <- mean(abs(data$Y[801:1000] - predict(fit,data[801:1000,])))
    p$rmse[ o] <- sqrt(mean((data$Y[801:1000] - predict(fit,data[801:1000,]))^2))
    p$optimizer[o]<-opt[o] 
    p$t[o]<- a$elapsed[1]
  
  }
  p
}

perf$optimizer<- toupper(perf$optimizer)

rt <- ggplot(perf, aes(x=optimizer, y = t,fill = optimizer)) +
  theme_classic() + 
  geom_boxplot() +
  xlab("Optimizer") +
  ylab("time in s") + 
  stat_density(geom="line",position="identity")

mae <- ggplot(perf, aes(x=mae, color=optimizer)) + 
  geom_density(show.legend = F) + 
  theme_classic()+
  xlab("Mean Absolute Error") +
  stat_density(geom="line",position="identity") +
  theme(axis.title.y=element_blank(), axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),text = element_text(size = 17),
        legend.position = c(0.87, 0.5))

mae

tt<- sapply(opt, function(x) mean(perf$t[which(perf$optimizer == x)]))
tt<- round(tt,digits = 1)  
tt  

