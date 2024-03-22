library(cito)
library(raster)
library(sp)
library(rsample)
library(latticeExtra)
library(sp)
library(ggplot2)
library(maptools)
set.seed(42)
#### African elephant SDM with cito #########
# The following code (loading and processing data) is from Angelov 2020 (see https://zenodo.org/record/4048271)

occ_data_raw <- readRDS("data/occ_data_raw.RDS")
occ_data <- occ_data_raw$df_data
occ_data$label <- as.factor(occ_data$label)
coordinates_df <- rbind(occ_data_raw$raster_data$coords_presence,
                        occ_data_raw$raster_data$background)

occ_data[,-ncol(occ_data)] <- scale(occ_data[,-ncol(occ_data)])
occ_data <- cbind(occ_data)
occ_data <- na.omit(occ_data)
occ_data$label = as.integer(occ_data$label) - 1L

rows = c(sample(rownames(occ_data[occ_data$label==0, ]), 2000), rownames(occ_data[occ_data$label==1, ]))
data = occ_data[rows, ]




##### Cito ######
# Single fit to check for convergence / learning rate
nn.single<- dnn(label~., data = data, 
              hidden = c(50, 50, 50), loss = "binomial",
              epochs = 50, lr = 0.1, 
              batchsize = 300,
              validation = 0.1, 
              shuffle = TRUE, 
              alpha = 0.5, 
              lambda = 0.005,
              early_stopping = 10,
              device = "cuda",
              bootstrap = FALSE)


nn.fit <- dnn(label~., data = data, 
              hidden = c(50, 50, 50), 
              loss = "binomial",
              epochs = 50, 
              lr = 0.1, 
              batchsize = 300,
              validation = 0.1, 
              shuffle = TRUE, 
              alpha = 0.5, 
              lambda = 0.005,
              early_stopping = 10,
              device = "cuda",
              bootstrap = 30L, 
              bootstrap_parallel = 5L)

nn.fit <- continue_training(
  nn.fit, epochs = 150, 
  changed_params = list(lr = 0.05, lr_scheduler = config_lr_scheduler("reduce_on_plateau", patience = 8, factor = 0.8)),
  parallel = 5L,
  device = "cuda")



##### Predictions #########
customPredictFun <- function(model, data) {
  return(apply(predict(model, data), 2:3, mean)[,1])
}

customPredictFunSD <- function(model, data) {
  return(apply(predict(model, data), 2:3, sd)[,1])
}

normalized_raster <- readRDS("data/normalized_raster.RDS")

pr <-
  raster::predict(normalized_raster,
                  nn.fit,
                  fun = customPredictFun)

pr_var <-
  raster::predict(normalized_raster,
                  nn.fit,
                  fun = customPredictFunSD)

summary_nn = summary(nn.fit, device = "cuda")

saveRDS(list(model = nn.fit, pred = pr, pred_var = pr_var, summ = summary_nn), "results/model.RDS")
