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

nn.fit <- dnn(label~., data = data, 
              hidden = c(50, 50, 50), loss = "binomial",
              epochs = 50, lr = 0.1, 
              batchsize = 300,
              validation = 0.1, shuffle = TRUE, 
              alpha = 0.5, lambda = 0.005,
              early_stopping = 10)

nn.fit <- continue_training(
              nn.fit, epochs = 32, changed_params = list(lr = 0.001),
              continue_from = which.min(nn.fit$losses$valid_l))



##### Predictions #########
customPredictFun <- function(model, data) {
  return(predict(model, data)[,1])
}
normalized_raster <- readRDS("data/normalized_raster.RDS")

pr <-
  raster::predict(normalized_raster,
                  nn.fit,
                  fun = customPredictFun)


saveRDS(list(model = nn.fit, pred = pr), "results/model.RDS")
