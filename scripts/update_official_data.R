# COVID-19 Canada Open Data Working Group Official Dataset Download and Compatibility Script #
# Author: Jean-Paul R. Soucy #

# Download official COVID-19 datasets and convert them to a compatible format.
# This will allow these datasets to be used as drop-in replacements
# for portions of COVID-19 Canada Open Data Working Group dataset.

# Note: This script assumes the working directory is set to the root directory of the project
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# load libraries
library(dplyr) # data manipulation
library(tidyr) # data manipulation
library(lubridate) # better dates
# devtools::install_github("jeanpaulrsoucy/Covid19CanadaData")
library(Covid19CanadaData) # load official datasets

# load functions
source("scripts/update_official_data_funs.R")

# official Quebec dataset (incomplete, testing only)
convert_official_qc()

# official Saskatchewan dataset: new health region boundaries
convert_official_sk_new_hr()

# combined dataset: CCODWG dataset 
combine_ccodwg_official_sk_new_hr(stat = "cases", loc = "hr")
combine_ccodwg_official_sk_new_hr(stat = "mortality", loc = "hr")