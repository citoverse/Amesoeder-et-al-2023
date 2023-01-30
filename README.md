Results
================

## cito: An R package for training neural networks using torch

This repository contains the code to reproduce the results in Amesöder
et al., ‘cito: An R package for training neural networks using torch’

### Benchmarking of runtime and error

Setup: 5 hidden layers, nodes per layer were increased from 50 to 1,000
with a stepsize of 50. Dataset contained 20 predictors (sampled from a
uniform distribution (0,1)) with 2,000 observations (1,000 were used for
training and 1,000 for evaluation (RMSE)). Each step (number of nodes)
were replicated 20 times.

To run the benchmarking:

Results:

<figure>
<img src="figures/fig-Fig_1-1.png" id="fig-Fig_1"
alt="Figure  1: Comparison of different deep learning packages (brulee, h2o, neuralnet, and cito (CPU and GPU)) on different network sizes on an Intel Xeon 6128 and a Nvidia RTX 2080ti. The networks consist of five equally sized layers (50 to 1000 nodes with a step size of 50) and are trained on a simulated data set with 1000 observations. Panel (A) shows the runtime of the different packages and panel (B) shows the average root mean square error (RMSE) of the models on a holdout of size 1000 observations (RMSE was averaged over different network sizes). Each network was trained 20 times (the dataset was resampled each time)." />
<figcaption aria-hidden="true"><strong>Figure </strong> 1: Comparison of
different deep learning packages (brulee, h2o, neuralnet, and cito (CPU
and GPU)) on different network sizes on an Intel Xeon 6128 and a Nvidia
RTX 2080ti. The networks consist of five equally sized layers (50 to
1000 nodes with a step size of 50) and are trained on a simulated data
set with 1000 observations. Panel (A) shows the runtime of the different
packages and panel (B) shows the average root mean square error (RMSE)
of the models on a holdout of size 1000 observations (RMSE was averaged
over different network sizes). Each network was trained 20 times (the
dataset was resampled each time).</figcaption>
</figure>

### Predictions and xAI

Data and code to prepare the data can be found and downloaded at
[Angelov 2020](https://doi.org/10.5281/zenodo.4048271)

To train the model run:

Results:

<figure>
<img src="figures/fig-Fig_3-1.png" id="fig-Fig_3"
alt="Figure  2: Predictions for the African elephant from a DNN trained by cito. Panel (A) shows the predicted probability of occurrence of the African elephant. Panel (B) shows the accumulated local effect plot (ALE), i.e. the change of the predicted occurrence probability in response to the Bioclim variable 8 (mean temperature of the wettest quarter)." />
<figcaption aria-hidden="true"><strong>Figure </strong> 2: Predictions
for the African elephant from a DNN trained by cito. Panel (A) shows the
predicted probability of occurrence of the African elephant. Panel (B)
shows the accumulated local effect plot (ALE), i.e. the change of the
predicted occurrence probability in response to the Bioclim variable 8
(mean temperature of the wettest quarter).</figcaption>
</figure>

### Session info

    R version 4.2.2 Patched (2022-11-10 r83330)
    Platform: x86_64-pc-linux-gnu (64-bit)
    Running under: Ubuntu 18.04.6 LTS

    Matrix products: default
    BLAS:   /usr/lib/x86_64-linux-gnu/openblas/libblas.so.3
    LAPACK: /usr/lib/x86_64-linux-gnu/libopenblasp-r0.2.20.so

    locale:
     [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
     [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
     [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
     [7] LC_PAPER=en_US.UTF-8       LC_NAME=C                 
     [9] LC_ADDRESS=C               LC_TELEPHONE=C            
    [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       

    attached base packages:
    [1] stats     graphics  grDevices utils     datasets  methods   base     

    other attached packages:
     [1] h2o_3.38.0.1        brulee_0.2.0        neuralnet_1.44.2   
     [4] maptools_1.1-4      latticeExtra_0.6-30 lattice_0.20-45    
     [7] rsample_1.1.1       raster_3.5-21       sp_1.5-0           
    [10] cito_1.0.1          gridExtra_2.3       forcats_0.5.1      
    [13] stringr_1.4.0       dplyr_1.0.9         purrr_0.3.4        
    [16] readr_2.1.2         tidyr_1.2.0         tibble_3.1.7       
    [19] ggplot2_3.3.6       tidyverse_1.3.1    

    loaded via a namespace (and not attached):
     [1] bitops_1.0-7       fs_1.5.2           lubridate_1.8.0    bit64_4.0.5       
     [5] RColorBrewer_1.1-3 httr_1.4.3         tools_4.2.2        backports_1.4.1   
     [9] utf8_1.2.2         R6_2.5.1           DBI_1.1.3          colorspace_2.0-3  
    [13] withr_2.5.0        tidyselect_1.1.2   processx_3.6.1     bit_4.0.4         
    [17] compiler_4.2.2     cli_3.6.0          rvest_1.0.2        xml2_1.3.3        
    [21] labeling_0.4.2     scales_1.2.0       checkmate_2.1.0    callr_3.7.0       
    [25] digest_0.6.29      foreign_0.8-82     rmarkdown_2.14     coro_1.0.2        
    [29] jpeg_0.1-9         pkgconfig_2.0.3    htmltools_0.5.2    parallelly_1.32.0 
    [33] dbplyr_2.2.1       fastmap_1.1.0      rlang_1.0.6        readxl_1.4.0      
    [37] torch_0.9.1        rstudioapi_0.13    farver_2.1.0       generics_0.1.2    
    [41] jsonlite_1.8.0     RCurl_1.98-1.9     magrittr_2.0.3     interp_1.1-2      
    [45] Rcpp_1.0.8.3       munsell_0.5.0      fansi_1.0.3        lifecycle_1.0.3   
    [49] furrr_0.3.1        terra_1.5-34       stringi_1.7.6      yaml_2.3.5        
    [53] grid_4.2.2         parallel_4.2.2     listenv_0.8.0      crayon_1.5.1      
    [57] deldir_1.0-6       haven_2.5.0        hms_1.1.1          knitr_1.39        
    [61] ps_1.7.1           pillar_1.7.0       codetools_0.2-18   reprex_2.0.1      
    [65] glue_1.6.2         evaluate_0.15      modelr_0.1.8       vctrs_0.5.2       
    [69] png_0.1-7          tzdb_0.3.0         cellranger_1.1.0   gtable_0.3.0      
    [73] future_1.26.1      assertthat_0.2.1   xfun_0.31          broom_1.0.0       
    [77] globals_0.15.1     ellipsis_0.3.2    
