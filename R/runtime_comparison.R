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
                 t= numeric(),
                 rmse = numeric())
k<-10
layers<- 5

model_size <- c(1:40)*25
model_size <- c(10,20)

run <- rep(T,4)

for( j in 1:length(model_size)){
  for(i in c(1:k)){ 
    
    #data generation
  
    v<- sample(c(3:100),1)
    data <- sim_data(v = 20,
                     r = sample(c(1:v),1),
                     n = 2000, 
                     s = 0.3)
    
    #temporary data frame
    df_times<- data.frame(size = rep(model_size[j],4),
                          package = rep("NA",4),
                          t= rep(NA,4),
                          rmse= rep(NA,4))
    
  
    # cito
    if(run[1]){
      
      start_t <- Sys.time()
      fit<- cito::dnn(Y~. , data = data[1:1000,],
                                                 plot=F, verbose= F, epochs= 64L,
                                                 hidden = rep(model_size[j],layers),
                                                 optimizer = "sgd")
      end_t <- Sys.time()
      df_times$package[1] <- "cito"
      df_times$t[1] <- as.numeric(difftime(end_t,start_t,units = "secs"))
      df_times$rmse[1] <- sqrt(mean((predict(fit, data[1001:2000,]) - data$Y[1001:2000])^2))
      
      
    }
    # cito on GPU
    if(run[2]){
    
      start_t <- Sys.time()
      fit<- cito::dnn(
                       Y~. , data = data[1:1000,],
                       plot=F, verbose= F, epochs= 64L,
                       hidden = rep(model_size[j],layers),
                       optimizer = "sgd",
                       device = "cuda")
      
      end_t <- Sys.time()
      df_times$package[2] <- "cito_gpu"
      df_times$t[2] <- as.numeric(difftime(end_t,start_t,units = "secs"))
      df_times$rmse[2] <- sqrt(mean((predict(fit, data[1001:2000,]) - data$Y[1001:2000])^2))
      
    }
    #brulee
    if (run[3]){
      start_t <- Sys.time()
      fit <- brulee::brulee_mlp(
                                Y~. , data = data[1:1000,],
                                hidden_units = rep(model_size[j],layers),
                                stop_iter = 64L,validation = 0,
                                optimizer= "SGD",
                                batch_size = 32L,
                                epochs= 64L, penalty = 0)
      end_t <- Sys.time()
      df_times$package[3] <- "brulee"
      df_times$t[3] <- as.numeric(difftime(end_t,start_t,units = "secs"))
      df_times$rmse[3] <- sqrt(mean(unlist(predict(fit, data[1001:2000,]) - data$Y[1001:2000])^2))
    }
    
    #neuralnet
    if(run[4]){
      start_t <- Sys.time()
      fit<- neuralnet::neuralnet(Y~. , data = data[1:1000,],
                                  hidden = rep(model_size[j],layers),
                                  stepmax = 64,
                                  threshold = 0.5)
      end_t <- Sys.time()
      df_times$package[4] <- "neuralnet"
      df_times$t[4] <- as.numeric(difftime(end_t,start_t,units = "secs"))
      

       df_times$rmse[4] <- tryCatch(expr={sqrt(mean((predict(fit, data[1001:2000,]) - data$Y[1001:2000])^2))},error= function(e) return(NA))
      }

    print(j)
    df<- rbind(df,df_times)
  }
  
  for ( i in c(1:4)){ 
    if(mean(tail(df$t[which(df$package== "cito")],n=k))>100) run[1] <- F
    if(mean(tail(df$t[which(df$package== "cito_gpu")],n=k))>100) run[2] <- F
    if(mean(tail(df$t[which(df$package== "brulee")],n=k))>100) run[3] <- F
    if(mean(tail(df$t[which(df$package== "neuralnet")],n=k))>100) run[4] <- F
    
    
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
                     n = 2000, 
                     s = abs(rnorm(mean=0,sd=0.4,n=1)))
    
    
    start_t <- Sys.time()
    tf_data <- h2o::as.h2o(data[1:1000,])
    fit<- h2o::h2o.deeplearning(y = "Y", 
                                training_frame = tf_data,
                                epochs = 64, stopping_rounds=64,regression_stop=0,
                                hidden= rep(model_size[j],layers),
                                activation= "Tanh",
                                #unfortunately necessary since training is not stable 
                                #with Rectifier as activation
                                mini_batch_size = 32)
    end_t <- Sys.time()
    
    
    v_data <- h2o::as.h2o(data[1001:2000,])
    
    
    
    df_times$t[i] <- as.numeric(difftime(end_t,start_t,units = "secs"))
    df_times$rmse <- sqrt(mean(unlist(h2o::h2o.predict(fit, v_data) - data$Y[1001:2000])^2))
    
    
  }
  print(j)
  df<- rbind(df,df_times)
  if(mean(df_times$t) >105) break
}
 h2o::h2o.shutdown(prompt=F)

 
 saveRDS(df)
 
 d<- df[-which(is.na(df$t)),]
 d<- aggregate(x=df$t,     
               by = list(df$size,df$package),
               FUN = mean)
 
 
 colnames(d) <- c("size","Package","t")
 
 d$Package[which(d$Package=="cito_gpu")]<- "cito GPU"
 
 time_plot<- ggplot(d, aes(x=size, y=t, group=Package,color= Package)) +
   geom_line(size=1) +ylim(0,100) +theme_classic()+
   theme(legend.key.size = unit(1, 'cm'),legend.text = element_text(size=16))+
   ylab("time in seconds")+
   xlab("nodes in each layer")+ 
   theme(axis.text=element_text(size=16),
 axis.title=element_text(size=16),
 legend.title=element_text(size=16,face="bold"),
 panel.border = element_rect(colour = "black", fill=NA, size=0.9))

 
 d<-df
 d$package[which(d$package=="cito_gpu")]<- "cito GPU" 
 rmse_plot <- ggplot(d[!is.na(d$rmse),],aes(x= package, y= rmse,fill = package)) +
   geom_boxplot(color= "black") +
   theme_classic()+ 
   theme(legend.position = "none",
  axis.text=element_text(size=16),
  axis.title=element_text(size=16),
  legend.title=element_text(size=16,face="bold"),
  panel.border = element_rect(colour = "black", fill=NA, size=0.9))
         
   
 
 
 plot_grid(time_plot,rmse_plot,nrow = 2,rel_heights = c(2,1.2),
           labels=c("A", "B"))
 
 d<- df[-which(is.na(df$t)),]
 d<- aggregate(x=df$rmse,     
               by = list(df$size,df$package),
               FUN = mean)
 
 
 colnames(d) <- c("size","Package","RMSE")
 
 d$Package[which(d$Package=="cito_gpu")]<- "cito GPU"
 
 ggplot(d, aes(x=size, y=t, group=Package,color= Package)) +
   geom_line(size=1) +theme_classic()+
   theme(legend.key.size = unit(1, 'cm'),legend.text = element_text(size=16))+
   ylab("time in seconds")+
   xlab("nodes in each layer")+ 
   theme(axis.text=element_text(size=16),
         axis.title=element_text(size=16),
         legend.title=element_text(size=16,face="bold"),
         panel.border = element_rect(colour = "black", fill=NA, size=0.9))
 
 