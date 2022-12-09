
library(mlr)
library(iml)
library(lime)
library(dplyr)
library(rsample)
library(latticeExtra)
library(sp)
library(ggplot2)
library(maptools)



# Get and prepare data ----------------------------------------------------
set.seed(42)

# this function downloads and stores the data, and to make the rest of the script reproducible (GBIF data can be updated with new observations) we are loading a stored static dataset
# occ_data_raw <-
#   get_benchmarking_data("Loxodonta africana", limit = 1000)
# saveRDS(occ_data_raw, file = "occ_data_raw.RDS")
occ_data_raw <- readRDS("occ_data_raw.RDS")

occ_data <- occ_data_raw$df_data

occ_data$label <- as.factor(occ_data$label)

coordinates_df <- rbind(occ_data_raw$raster_data$coords_presence,
                        occ_data_raw$raster_data$background)

occ_data <-
  normalizeFeatures(occ_data, method = "standardize")

occ_data <- cbind(occ_data, coordinates_df)
occ_data <- na.omit(occ_data)

# Split data for machine learning -----------------------------------------

set.seed(42)
train_test_split <- initial_split(occ_data, prop = 0.7)
data_train <- training(train_test_split)
data_test  <- testing(train_test_split)
data_train$x <- NULL
data_train$y <- NULL
data_test_subset <- data_test %>% filter(label == 1)

# Train model -------------------------------------------------------------

task <-
  makeClassifTask(id = "model", data = data_train, target = "label")
lrn <- makeLearner("classif.randomForest", predict.type = "prob")
mod <- train(lrn, task)
pred <- predict(mod, newdata=data_test)
VIMP <- as.data.frame(getFeatureImportance(mod)$res)

# Top n important variables
top_n(VIMP, n=5, importance) %>%
  ggplot(., aes(x=reorder(variable,importance), y=importance))+
  geom_bar(stat='identity')+ coord_flip() + xlab("")

# Performance
performance(pred, measures=auc)

# ALE plot
predictor <-
  Predictor$new(mod, data = data_train, class = 1, y = "label")
ale <- FeatureEffect$new(predictor, feature = "bio16")
ale$plot() +
  theme_minimal() +
  ggtitle("ALE Feature Effect") +
  xlab("Precipitation of Wettest Quarter")

# Generate explanations ---------------------------------------------------
# resampling
sample_data <- withr::with_seed(10, sample_n(data_test_subset, 3))
sample_data_coords <- dplyr::select(sample_data, c("x", "y"))
sample_data$x <- NULL
sample_data$y <- NULL


set.seed(42)
explainer <- lime(data_train, mod)
set.seed(42)
explanation <-
  lime::explain(sample_data,
                explainer,
                n_labels = 1,
                n_features = 5)
plot_features(explanation)

customPredictFun <- function(model, data) {
  v <- predict(model, data, type = "prob")
  v <- as.data.frame(v)
  colnames(v) <- c("absence", "presence")
  return(v$presence)
}

# we are loading the raster for reproducibility purposes
# normalized_raster <- RStoolbox::normImage(occ_data_raw$raster_data$climate_variables)
# saveRDS(normalized_raster, file = "normalized_raster.RDS")
normalized_raster <- readRDS("data/normalized_raster.RDS")

pr <-
  dismo::predict(normalized_raster,
                 mlr::getLearnerModel(mod, TRUE),
                 fun = customPredictFun)

hab = 
  spplot(pr)
