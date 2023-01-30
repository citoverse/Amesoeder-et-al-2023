library("neuralnet")
library("brulee")
library("h2o")
library("cito")
library("ggplot2")
library("rbenchmark")
set.seed(42)



sim_data<- function(v,n, s){
  data<- matrix(runif(n*v),ncol=v,nrow= n)
  true_f<- runif(-1,1,n=v)
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
k<-20
layers<- 5

model_size <- c(1:20)*50

run <- rep(T,5)

h2o::h2o.init()
for( j in 1:length(model_size)){
  for(i in c(1:k)){ 
    
    #data generation
    data <- sim_data(v = 20,
                     n = 2000, 
                     s = 0.3)
    
    #temporary data frame
    df_times<- data.frame(size = rep(model_size[j],5),
                          package = rep("NA",5),
                          t= rep(NA,5),
                          rmse= rep(NA,5))
    
    
    # # cito
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
    
    #h2p
    if(run[5]) {
      
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
      
      df_times$package[5] <- "h2o"
      df_times$t[5] <- as.numeric(difftime(end_t,start_t,units = "secs"))
      df_times$rmse[5] <- tryCatch(expr={sqrt(mean(unlist(h2o::h2o.predict(fit, v_data) - data$Y[1001:2000])^2))},error= function(e) return(NA))
      
    }

    print(j)
    df<- rbind(df,df_times)
    print(df, max = 100)
    
    saveRDS(df, "results/runtime_results.RDS")
  }
  
  for ( i in c(1:4)){
    if(mean(tail(df$t[which(df$package== "cito")],n=k), na.rm = TRUE)>250) run[1] <- F
    if(mean(tail(df$t[which(df$package== "cito_gpu")],n=k), na.rm = TRUE)>250) run[2] <- F
    if(mean(tail(df$t[which(df$package== "brulee")],n=k), na.rm = TRUE)>250) run[3] <- F
    if(mean(tail(df$t[which(df$package== "neuralnet")],n=k), na.rm = TRUE)>250) run[4] <- F
    if(mean(tail(df$t[which(df$package== "h2o")],n=k), na.rm = TRUE)>250) run[5] <- F
    }
  
  
}

h2o::h2o.shutdown(prompt=F)
