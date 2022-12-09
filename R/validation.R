library(cito)
library(brulee)
library(ggplot2)

sim_data <- function(v,n,r,s){
  
  data<- matrix(runif(n*v),ncol=v,nrow= n)
  
  true_f<- rep(0,v)
  
  true_f[sample(c(1:v),r,replace=F)]<- runif(-1,1,n=r)
  
  Y <- apply(data,1,function(x) { (sum(x * true_f)) + rnorm(mean=0,sd=s,n=1)})
  
  
  df<- as.data.frame(data)
  df<- data.frame(scale(df,center= T, scale= T))
  df$Y<- Y
  
  return(df)
}

compare_fit<- function(fit1,fit2, data){
  return(c(
    mean(abs(data$Y - predict(fit1,data))), 
    mean(as.matrix(abs(data$Y - predict(fit2,data)))) 
  ,use.names=F))
}
  
k<-500

df<- data.frame(mae_cito=numeric(),
                mae_brulee=numeric())
for( i in c(1:k)){
  
  v<- sample(c(4:30),1)
  data <- sim_data(v = v,
                   r = sample(c(1:v),1),
                   n = 1000,
                   s = abs(rnorm(1,0,0.4)))
  
  
  #without regularization 
  cito.fit <- dnn(Y~., data = data[1:800,], epochs =100, loss= "mse",verbose= F, plot=F)
  brulee.fit<- brulee_mlp(Y~., data = data[1:800,], epochs = 100,hidden_units = rep(10,3),penalty = 0)
  
  df <- rbind.data.frame(df,(compare_fit(cito.fit,brulee.fit, data[801:1000,])))
  
  #with regularization
  cito.fit <- dnn(Y~., data = data[1:800,], epochs =100, loss= "mse",verbose= F, plot=F,lambda=0.01)
  brulee.fit<- brulee_mlp(Y~., data = data[1:800,], epochs = 100,hidden_units = rep(10,3),penalty = 0.01)
  
  df <- rbind.data.frame(df,(compare_fit(cito.fit,brulee.fit, data[801:1000,])))
  
  #with dropout
  cito.fit <- dnn(Y~., data = data[1:800,], epochs =100, loss= "mse",verbose= F, plot=F,dropout=0.2)
  brulee.fit<- brulee_mlp(Y~., data = data[1:800,], epochs = 100,hidden_units = rep(10,3),penalty = 0, dropout=0.2)
  
  df <- rbind.data.frame(df,(compare_fit(cito.fit,brulee.fit, data[801:1000,])))
  
  
}



colnames(df)<- c("mae_cito","mae_brulee")

diff<-data.frame(diff= df$mae_brulee-df$mae_cito)




ggplot(diff,aes(x=diff)) + 
  geom_histogram(bins=40,fill = "gray",color= "black") +
  theme_classic() + 
  geom_vline(xintercept =0,color= "red") +
  xlab("Difference in mean absolute error of cito and brulee")
