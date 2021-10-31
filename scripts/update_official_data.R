# COVID-19 Canada Open Data Working Group Official Dataset Download and Compatibility Script #
# Author: Jean-Paul R. Soucy #

# Download official COVID-19 datasets and convert them to a compatible format.
# This will allow these datasets to be used as drop-in replacements
# for portions of COVID-19 Canada Open Data Working Group dataset.

# Note: This script assumes the working directory is set to the root directory of the project
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# Authentication: You must authenticate your Google account before running the rest of the script.
# You may be asked to give "Tidyverse API Packages" read/write access to your Google account.

# authenticate your Google account before running the rest of the script
library(googledrive) # interface with Google Drive
library(googlesheets4) # read from Google Sheets
if (file.exists("email.txt")) {
  # automatically read account name from email.txt, if present
  drive_auth(readLines("email.txt"))
  gs4_auth(readLines("email.txt"))
} else {
  # otherwise, prompt for authentication
  drive_auth()
  gs4_auth()
}

# load libraries
library(dplyr) # data manipulation
library(tidyr) # data manipulation
library(lubridate) # better dates
# devtools::install_github("jeanpaulrsoucy/Covid19CanadaData")
library(Covid19CanadaData) # load official datasets

# load functions
source("scripts/update_data_funs.R")
source("scripts/update_official_data_funs.R")

# list files in Google Drive data folder
files <- drive_ls("Provincial_List/Automation")

# official Quebec dataset (incomplete, testing only)
convert_official_qc()

# NT sub health-region cases and active cases
update_nt_subhr()

# official Saskatchewan dataset: new health region boundaries
convert_official_sk_new_hr()

# combined dataset: CCODWG dataset 
combine_ccodwg_official_sk_new_hr(stat = "cases", loc = "hr")
combine_ccodwg_official_sk_new_hr(stat = "mortality", loc = "hr")