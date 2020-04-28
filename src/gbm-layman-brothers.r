if (!require('logger')) install.packages('logger'); library('logger')


start_time_pipeline <- Sys.time()
log_debug('Training pipeline start time - {start_time_pipeline}')

# Local directories 
ROOT_DIR <- getwd()

PROJECT_DIR <- 
  'Documents/github/r-prediction-rest-api'

DATA_DIR <- 'data'
MODELS_DIR <- 'models'
API_DIR <- 'api'
LOGS_DIR <- 'logs'

get_artifact_path <- function(file_name,
                              artifact_dir,
                              root_dir=ROOT_DIR,
                              project_dir=PROJECT_DIR){
  artifact_path <- 
    file.path(root_dir,
              project_dir,
              artifact_dir,
              file_name)
  
  return (artifact_path)
}


logging_file_path <- 
  get_artifact_path("training_pipeline_auto_ml.log", LOGS_DIR)

log_appender(appender_file(logging_file_path))
log_layout(layout_glue_colors)
log_threshold(DEBUG)

log_info('Start logging')

r_version <- R.Version()$version.string
log_debug('R Version: {r_version}')

session_info_os <- sessionInfo()$running
log_debug('Session Info OS: {session_info_os}')


log_info('Instantiate function to install dependencies')
install_dependencies <- function(){
  
  package_url_logger <- 'https://cran.rstudio.com/bin/macosx/el-capitan/contrib/3.6/logger_0.1.tgz'
  package_url_h2o <- 'https://cran.rstudio.com/bin/macosx/el-capitan/contrib/3.6/h2o_3.30.0.1.tgz'
  package_url_cluster <- 'https://cran.rstudio.com/bin/macosx/el-capitan/contrib/3.6/cluster_2.1.0.tgz'
  package_url_dplyr <- 'https://cran.rstudio.com/bin/macosx/el-capitan/contrib/3.6/dplyr_0.8.5.tgz'
  package_url_tidyverse <- 'https://cran.rstudio.com/bin/macosx/el-capitan/contrib/3.6/tidyverse_1.3.0.tgz'
  
  log_debug('logger CRAN URL: {package_url_logger}')
  log_debug('h2o CRAN URL: {package_url_h2o}')
  log_debug('cluster CRAN URL: {package_url_cluster}')
  log_debug('dplyr CRAN URL: {package_url_dplyr}')
  log_debug('tidyverse CRAN URL: {package_url_tidyverse}')
  
  packages_urls <- c(
    package_url_logger,
    package_url_dplyr,
    package_url_cluster,
    package_url_tidyverse,
    package_url_h2o
  )
  
  for(url in packages_urls)
  {for(package_url in url)
    log_info('Installing {} package')
    {install.packages(package_url, repos=NULL, type='source')}
    log_info('Package {package_url} installation finished')
    }
}

log_info('Start installing dependencies')
install_dependencies()
log_info('Dependencies installed')

packageVersion_logger <- packageVersion('logger')[1]
packageVersion_h2o <- packageVersion('h2o')[1]
packageVersion_cluster <- packageVersion('cluster')[1]
packageVersion_dplyr <- packageVersion('dplyr')[1]
packageVersion_tidyverse <- packageVersion('tidyverse')[1]

log_debug('logger Version: {packageVersion_logger}')
log_debug('h2o Version: {packageVersion_h2o}')
log_debug('cluster Version: {packageVersion_cluster}')
log_debug('dplyr Version: {packageVersion_dplyr}')
log_debug('tidyverse Version: {packageVersion_tidyverse}')


log_info('Loading packages')
packages <- c(
  "logger",
  "h2o",
  "cluster",
  "dplyr",
  "tidyverse")
invisible(lapply(packages, library, character.only = TRUE))
log_info('Packages loaded')


session_info_base_packages <- sessionInfo()$basePkgs
log_info('Session Info Base Packages: {session_info_base_packages}')

session_info_loaded_packages <- sessionInfo()$loadedOnly
log_debug('Session Info Loaded Packages: {session_info_loaded_packages}')


log_info('Initializing H2O')
host = "localhost"
host_port = 54321
cpus = -1
memory_size = "7g"

log_debug('H2O Cluster host: {host}')
log_debug('H2O Cluster host port: {host_port}')
log_debug('H2O Cluster Number CPUs: {cpus}')
log_debug('H2O Cluster Memory Size allocated: {memory_size}')
  
h2o.init(
  ip = host,
  port = host_port,
  nthreads = cpus,
  max_mem_size = memory_size
)

cluster_status <- h2o.clusterStatus()
log_debug('H2O Cluster Status Info: {cluster_status}')


log_debug('Load data')
layman_brothers_url = 
  "https://raw.githubusercontent.com/fclesio/learning-space/master/Datasets/02%20-%20Classification/default_credit_card.csv"

layman_brothers.hex = h2o.importFile(path = layman_brothers_url,
                                     destination_frame = "layman_brothers.hex")
log_debug('Data loaded')

log_debug('Transform default variable to factor')
layman_brothers.hex$DEFAULT = as.factor(layman_brothers.hex$DEFAULT)


log_debug('Construct test and train sets using sampling')
layman_brothers.split <- h2o.splitFrame(data = layman_brothers.hex,
                                        ratios = 0.90, seed =42)

layman_brothers.train <- layman_brothers.split[[1]]
layman_brothers.test <- layman_brothers.split[[2]]

qty_samples_train <- nrow(layman_brothers.train)
qty_samples_test <- nrow(layman_brothers.test)

log_debug('Training set with {qty_samples_train} records')
log_debug('Test set with {qty_samples_test} records')

log_debug('Set predictor and response variables')
y = "DEFAULT"

x = c(
  "LIMIT_BAL"
  ,"SEX"
  ,"EDUCATION"
  ,"MARRIAGE"
  ,"AGE"
  ,"PAY_0"
  ,"PAY_2"
  ,"PAY_3"
  ,"PAY_4"
  ,"PAY_5"
  ,"PAY_6"
  ,"BILL_AMT1"
  ,"BILL_AMT2"
  ,"BILL_AMT3"
  ,"BILL_AMT4"
  ,"BILL_AMT5"
  ,"BILL_AMT6"
  ,"PAY_AMT1"
  ,"PAY_AMT2"
  ,"PAY_AMT3"
  ,"PAY_AMT4"
  ,"PAY_AMT5"
  ,"PAY_AMT6")



log_debug('Run AutoML for model training')
start_time <- Sys.time()

aml <- 
  h2o.automl(x=x,
             y=y,
             training_frame = layman_brothers.train,
             validation_frame = layman_brothers.test,
             max_models = 3,
             nfolds = 5,
             stopping_metric = c("AUC"),
             project_name = "estatidados-auto-ml",
             sort_metric = c("AUC"),
             verbosity = "warn",
             seed = 42
             )

end_time <- Sys.time()
log_debug('AutoML training ended')


time_elapsed <- end_time - start_time
log_debug('Time elapsed - {time_elapsed}')


lb <- aml@leaderboard

for (model_auto_ml in 1:nrow(lb)){
  auto_ml_model_id <- 
    as.list(lb$model_id)[model_auto_ml][1]
  
  auto_ml_auc <- 
    as.list(lb$auc)[model_auto_ml][1]

  auto_ml_logloss <- 
    as.list(lb$logloss)[model_auto_ml][1]
  
  auto_ml_aucpr <- 
    as.list(lb$aucpr)[model_auto_ml][1]
  
  auto_ml_mean_per_class_error <- 
    as.list(lb$mean_per_class_error)[model_auto_ml][1]
  
  auto_ml_rmse <- 
    as.list(lb$rmse)[model_auto_ml][1]
  
  auto_ml_mse <- 
    as.list(lb$mse)[model_auto_ml][1]

  log_info("AutoML - model_id: {auto_ml_model_id} - auc: {auto_ml_auc} - logloss: {auto_ml_logloss} - aucpr: {auto_ml_aucpr} - mean_per_class_error: {auto_ml_mean_per_class_error} - rmse: {auto_ml_rmse} - mse: {auto_ml_mse}")
  
}


log_info("AutoML Winning Model - model_id: {aml@leader@model_id} - algorithm: {aml@leader@algorithm} - seed: {aml@leader@parameters$seed} - metalearner_nfolds: {aml@leader@parameters$metalearner_nfolds} - training_frame: {aml@leader@parameters$training_frame} - validation_frame: {aml@leader@parameters$validation_frame}")
model_file_path <- 
  get_artifact_path("", MODELS_DIR)
log_info("Model destination path: {model_file_path}")

model_path <- h2o.saveModel(object=aml@leader,
                            path=model_file_path,
                            force=TRUE)
log_info("Model artifact path: {model_path}")


end_time_pipeline <- Sys.time()
log_debug('Training pipeline end time - {end_time_pipeline}')

time_elapsed_pipeline <- end_time_pipeline - start_time_pipeline
log_debug('Training pipeline time elapsed - {time_elapsed_pipeline[1]} mins')
log_debug('Training pipeline finished')

# References
# [0] - Dataset: https://archive.ics.uci.edu/ml/datasets/Heterogeneity+Activity+Recognition
# [1] - https://towardsdatascience.com/an-efficient-way-to-install-and-load-r-packages-bc53247f058d
# [2] - https://stackoverflow.com/questions/15956183/how-to-save-a-data-frame-as-csv-to-a-user-selected-location-using-tcltk
# [3] - https://stackoverflow.com/questions/13110076/function-to-concatenate-paths
# [4] - http://docs.h2o.ai/h2o/latest-stable/h2o-docs/productionizing.html
# [5] - http://manishbarnwal.com/blog/2016/10/05/install_a_package_particular_version_in_R/
# [6] - https://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them
# [7] - https://rstudio.github.io/packrat/
# [8] - https://daroczig.github.io/logger/
# [9] - https://stackoverflow.com/questions/2031163/when-to-use-the-different-log-levels
# [10] - https://stackoverflow.com/questions/12193779/how-to-write-trycatch-in-r
# [11] - http://adv-r.had.co.nz/Exceptions-Debugging.html
# [12] - https://stackoverflow.com/questions/1815606/determine-path-of-the-executing-script
# [13] - https://www.r-bloggers.com/best-practices-for-logging-computational-systems-in-r-and-python/
# [14] - https://www.r-bloggers.com/5-ways-to-measure-running-time-of-r-code/
# [15] - http://docs.h2o.ai/h2o/latest-stable/h2o-docs/automl.html
# [16] - http://docs.h2o.ai/h2o/latest-stable/h2o-docs/parameters.html
# [17] - https://socialsciences.mcmaster.ca/jfox/Books/Companion/appendices/Appendix-Cox-Regression.pdf
