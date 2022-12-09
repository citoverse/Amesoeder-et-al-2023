library(cito)
library(rbenchmark)
library(cowplot)
library(ggplot2)

sim_data <- function(v,n,r,s){
  
  data<- matrix(runif(n*v),ncol=v,nrow= n)
  
  true_f<- rep(0,v)
  
  true_f[sample(c(1:v),r,replace=F)]<- runif(-1,1,n=r)
  
  Y <- apply(data,1,function(x) { (sum(x * true_f)) + rnorm(mean=0,sd=s,n=1)})
  
  
  df<- as.data.frame(data)
  df<- data.frame(scale(df,center = T, scale = T))
  df$Y<- Y
  
  return(df)
}

k <- 30
df_gpu_cpu <- data.frame(cpu = rep(NA,k),
                         gpu = rep(NA, k),
                         samples = rep(NA,k))

for ( i in c(1:k)){ 
  
  data<- sim_data(v= 50,r= 30,n=i*50,s = 0.01)
  
  a <- benchmark(fit <- dnn(Y~.,data=data, hidden= rep(10,3), batchsize = 32,
                            epochs =100, verbose= F, plot=F, device= "cpu"),
                 replications = 1)
  df_gpu_cpu$cpu[i] <-  a$elapsed[1]          
  
  a <- benchmark(fit <- dnn(Y~.,data=data, hidden= rep(10,3), batchsize = 32,
                            epochs =100, verbose= F, plot=F, device= "cuda"),
                 replications =1)
  df_gpu_cpu$gpu[i] <-  a$elapsed[1]          
  
  df_gpu_cpu$samples[i] <- i*50
  
}

df_gpu_cpu2 <- data.frame(cpu = rep(NA,k),
                         gpu = rep(NA, k),
                         samples = rep(NA,k))

for ( i in c(1:k)){ 
  
  data<- sim_data(v= 50,r= 30,n=i*50,s = 0.01)
  
  a <- benchmark(fit <- dnn(Y~.,data=data, hidden= rep(100,3), batchsize = 32,
                            epochs =100, verbose= F, plot=F, device= "cpu"),
                 replications = 1)
  df_gpu_cpu2$cpu[i] <-  a$elapsed[1]          
  
  a <- benchmark(fit <- dnn(Y~.,data=data, hidden= rep(100,3), batchsize = 32,
                            epochs =100, verbose= F, plot=F, device= "cuda"),
                 replications =1)
  df_gpu_cpu2$gpu[i] <-  a$elapsed[1]          
  
  df_gpu_cpu2$samples[i] <- i*50
  
}
df_gpu_cpu3 <- data.frame(cpu = rep(NA,k),
                         gpu = rep(NA, k),
                         samples = rep(NA,k))

for ( i in c(1:k)){ 
  
  data<- sim_data(v= 50,r= 30,n=i*50,s = 0.01)
  
  a <- benchmark(fit <- dnn(Y~.,data=data, hidden= rep(250,3), batchsize = 32,
                            epochs =100, verbose= F, plot=F, device= "cpu"),
                 replications = 1)
  df_gpu_cpu3$cpu[i] <-  a$elapsed[1]          
  
  a <- benchmark(fit <- dnn(Y~.,data=data, hidden= rep(250,3), batchsize = 32,
                            epochs =100, verbose= F, plot=F, device= "cuda"),
                 replications =1)
  df_gpu_cpu3$gpu[i] <-  a$elapsed[1]          
  
  df_gpu_cpu3$samples[i] <- i*50
  
}



p1<- ggplot(data= df_gpu_cpu ) +
  geom_line(aes(y=cpu,x= samples),color= "blue",size=1)+
  geom_point(aes(y=cpu,x= samples)) +
  geom_line(aes(y=gpu,x= samples),color= "red",size=1)+
  geom_point(aes(y=gpu,x= samples))+
  theme_classic()+ 
  ylab("time in seconds")+
  ylim(0,66)

p2<- ggplot(data= df_gpu_cpu2 ) +
  geom_line(aes(y=cpu,x= samples),color= "blue",size=1)+
  geom_point(aes(y=cpu,x= samples)) +
  geom_line(aes(y=gpu,x= samples),color= "red",size=1)+
  geom_point(aes(y=gpu,x= samples))+
  theme_classic(legend.position = c(0.4, 0.9))+ 
  ylab("time in seconds")+
  ylim(0,66)

p3<- ggplot(data= df_gpu_cpu3 ) +
  geom_line(aes(y=cpu,x= samples),color= "blue",size=1)+
  geom_point(aes(y=cpu,x= samples)) +
  geom_line(aes(y=gpu,x= samples),color= "red",size=1)+
  geom_point(aes(y=gpu,x= samples))+
  theme_classic()+ 
  ylab("time in seconds")+
  ylim(0,66) 


plot_grid(p1,p2,p3, labels = c("A","B","C"),nrow = 1)

