library("neuralnet")
library("brulee")
library("h2o")
library("cito")
library("ggplot2")
library("rbenchmark")



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

df <- data.frame(mae = numeric(),
                 rmse = numeric(),
                 package = character(),
                 t= numeric())
k<-10
model_size <- c(1:80)*10

run <- rep(T,4)

for( j in 1:length(model_size)){
  for(i in c(1:k)){

    #data generation

    data <- sim_data(v = 20,
                     r = sample(c(1:20),1),
                     n = 1000,
                     s = abs(rnorm(mean=0,sd=0.4,n=1)))

    #temporary data frame
    df_times<- data.frame(size = rep(model_size[j],4),
                          package = rep("NA",4),
                          t= rep(NA,4))




    # cito
    if(run[1]){
      t <- rbenchmark::benchmark(fit<- cito::dnn(Y~. , data = data,
                                                 plot=F, verbose= F, epochs= 64L,
                                                 hidden = rep(model_size[j],10),
                                                 optimizer = "sgd"),
                                 replications = 1)
      df_times$package[1] <- "cito"
      df_times$t[1] <- t$elapsed[1]
      if(t$elapsed[1]>110) run[1]<-F
    }
    # cito on GPU
    if(run[2]){
      t <- rbenchmark::benchmark(fit<- cito::dnn(
        Y~. , data = data,
        plot=F, verbose= F, epochs= 64L,
        hidden = rep(model_size[j],10),
        optimizer = "sgd",
        device = "cuda"),
        replications = 1)
      df_times$package[2] <- "cito_gpu"
      df_times$t[2] <- t$elapsed[1]
      if(t$elapsed[1]>110) run[2]<-F
    }
    #brulee
    if(run[3]){
      t <- rbenchmark::benchmark(fit <- brulee::brulee_mlp(
        Y~. , data = data,
        hidden_units = rep(model_size[j],10),
        stop_iter = 64L,validation = 0,
        optimizer= "SGD",
        batch_size = 32L,
        epochs= 64L, penalty = 0), replications = 1)
      df_times$package[3] <- "brulee"
      df_times$t[3] <- t$elapsed[1]
      if(t$elapsed[1]>110) run[3]<-F
    }
    #neuralnet
    if(run[4]){
      t <- rbenchmark::benchmark(fit<- neuralnet::neuralnet(Y~. , data = data[1:800,],
                                                            hidden = rep(model_size[j],10),
                                                            stepmax = 64,
                                                            threshold = 0.5),
                                 replications = 1)
      df_times$package[4] <- "neuralnet"
      df_times$t[4] <- t$elapsed[1]
      if(t$elapsed[1]>110) run[4]<-F
    }

    print(j)
    df<- rbind(df,df_times)
  }

}




h2o::h2o.init()

for(j in c(1:length(model_size))){
  df_times<- data.frame(size = rep(model_size[j],k),
                        package = rep("h2o",k),
                        t= rep(NA,k))

  for(i in c(1:k)){
    #data generation

    data <- sim_data(v = 20,
                     r = sample(c(1:20),1),
                     n = 1000,
                     s = abs(rnorm(mean=0,sd=0.4,n=1)))


    t <- rbenchmark::benchmark({
      tf_data <- h2o::as.h2o(data)
      fit<- h2o::h2o.deeplearning(y = "Y",
                                  training_frame = tf_data,
                                  epochs = 64, stopping_rounds=64,regression_stop=0,
                                  hidden= rep(model_size[j],10),
                                  activation= "Tanh",
                                  #unfortunately necessary since training is not stable
                                  #with Rectifier as activation
                                  mini_batch_size = 32)
    },replications =1)

    df_times$t[i] <- t$elapsed[1]



  }
  print(j)
  df<- rbind(df,df_times)
  if(mean(df_times$t) >105) break
}
h2o::h2o.shutdown(prompt=F)


d<- df[-which(is.na(df$t)),]
d<- aggregate(x=df$t,
              by = list(df$size,df$package),
              FUN = mean)


colnames(d) <- c("size","Package","t")

d$Package[which(d$Package=="cito_gpu")]<- "cito GPU"

ggplot(d, aes(x=size, y=t, group=Package,color= Package)) +
  geom_line(size=1) +ylim(0,100) +theme_classic()+
  theme(legend.key.size = unit(1, 'cm'),legend.text = element_text(size=16))+
  ylab("time in seconds")+
  xlab("nodes in each layer")+
  theme(axis.text=element_text(size=12),
        axis.title=element_text(size=12),
        legend.title=element_text(size=16,face="bold"))






