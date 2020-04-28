
R + H2O Training Pipeline and REST API
=====================================

## Objective of this project
The main point of this repository is to raise a REST API completely from scratch using H2O and the R language.

Thus, the objective of this repository is to empower developers in R and other data scientists to raise this type of service in their infrastructure and allow the use of R and H2O in production. This project has some limitations that can be seen below.

##  Objects and Folders
The project is organized as follows:

 - `src`: Main script for model training and model serialization
 - `api`: Files regarding the endpoint and prediction functions
 - `data`: Raw data for training
 - `logs`: Stores the training log and API logs        
 - `models`: Main folder where the serialized models are stored

## Bank Layman Brothers Loan API
The scenario where will be to build a REST API that will receive some pieces of information about some customers and will perform the probability of a consumer enter in default situation with their loan.

The [data is stored in Github](https://github.com/fclesio/learning-space/blob/master/Datasets/02%20-%20Classification/default_credit_card.csv) and has the following fields:

  - `ID`: Customer ID
  - `LIMIT_BAL`:  Balance limit for the customer
  - `SEX`:  Customer gender
  - `EDUCATION `:  Customer education
  - `MARRIAGE`:  Informs if the customer is married or not
  - `AGE`:  Customer age in the moment of loan
  - `PAY_0 ... PAY_6`:  Values of payments for the loan (principal)
  - `BILL_AMT1...BILL_AMT6`:  Bill amount
  - `PAY_AMT1...PAY_AMT6`:  Amount paid
  - `DEFAULT`: Informs if the customer entered in default or not

##  Before execution
Due to some limitations of R language to establishing the file paths (absolute/relative paths) I included all paths directly in the code (not ideal).

Said that those paths **should be changed for your local directory before run**. The files that need to be changed are:
  - `src/gbm-layman-brothers.r` - line: 11
  - `api/endpoint.r` - line: 7
  - `api/api.r` - line: 10

## Training Pipeline
There's some alternatives to run a `R` command from terminal. The most elegant way to run a R script in a _bash_ call it's the following one that [I unshamelessly took from the Stack Overflow](https://stackoverflow.com/questions/18306362/run-r-script-from-command-line).

After the paths being changed, to execute the training just run the following line in terminal:

  - `$ R < /<<YOUR-PATH>>/r-prediction-rest-api/src/gbm-layman-brothers.R --no-save`

This script will run a training pipeline using [AutoML in H2O](http://docs.h2o.ai/h2o/latest-stable/h2o-docs/automl.html), generate the logs in `logs` folder, pick the best model and save it (serialize it) in `models` folder.

## Start the REST API from command line
Unfortunately due to the fact that H2O.ai do not have an option to set a name directly in [AutoML models](http://docs.h2o.ai/h2o/latest-stable/h2o-docs/automl.html) in the moment of serialization (`model_id` field) you will need to take the name of the file and change it in the `api/api.r` file in the line `21` and put the name of your file.

After your model being serialized and change this line, you should run the following command in terminal:<

  - `$ R < /<<YOUR-PATH>>/r-prediction-rest-api/api/endpoint.R --no-save`  

## API Swagger for testing
After your API just started, you can click in the following link and test the Swagger API with the values for each field:
  - `http://127.0.0.1:8000/__swagger__/`

## API request via curl
Default FALSE:
  - `$ curl -X POST "http://127.0.0.1:8000/prediction?PAY_AMT6=0&PAY_AMT5=0&PAY_AMT4=0&PAY_AMT3=0&PAY_AMT2=689&PAY_AMT1=0&BILL_AMT6=0&BILL_AMT5=0&BILL_AMT4=0&BILL_AMT3=689&BILL_AMT2=3102&BILL_AMT1=3913&PAY_6=-2&PAY_5=-2&PAY_4=-1&PAY_3=-1&PAY_2=2&PAY_0=2&AGE=24&MARRIAGE=1&EDUCATION=2&SEX=2&LIMIT_BAL=20000" -H  "accept: application/json"`

Default TRUE:
  - `$ curl -X POST "http://127.0.0.1:8000/prediction?PAY_AMT6=5000&PAY_AMT5=1000&PAY_AMT4=1000&PAY_AMT3=1000&PAY_AMT2=1500&PAY_AMT1=1518&BILL_AMT6=15549&BILL_AMT5=14948&BILL_AMT4=14331&BILL_AMT3=13559&BILL_AMT2=14027&BILL_AMT1=29239&PAY_6=0&PAY_5=0&PAY_4=0&PAY_3=0&PAY_2=0&PAY_0=0&AGE=34&MARRIAGE=2&EDUCATION=2&SEX=2&LIMIT_BAL=90000" -H  "accept: application/json"`

## See the logs
If you want to see the logs, just tail those logs using the following commands:
  - Training Pipeline: `$ training_pipeline_auto_ml.log`  

  - API Predictions: `$ tail -F api_predictions.log`

## Limitations
A more attentive developer will notice that he does not have some important limitations in the project such as: (1) considering sex as an independent variable, (2) logs outside a standard format, (3) no test cases, (4) fine tuning of the algorithm.

This happens due to the fact that the point here is to make a REST API from scratch using only R as the language, so here the point will be to start very simple and with limitations and it is up to the developer to adjust to his taste.

Another important point is that R is not a general programming language, at best R is a scientific programming language through scripting. This implies that the language has numerous inherent limitations by design.

## TODO
  - Error handling
  - API security headers
  - Enhance logging for predictions
  - Have some bindings between IP and model requests
  - Docker image
