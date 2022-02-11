# Manual updates to the COVID-19 Canada Open Data Working Group dataset #
# Author: Jean-Paul R. Soucy #

# Note: This script assumes the working directory is set to the root directory of the project
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# Note: This script requires a Python installation with the latest version of the Tableau Scraper
# library installed.
# pip install git+https://github.com/bertrandmartel/tableau-scraping.git#egg=tableauscraper

# Authentication: You must authenticate your Google account before running the rest of the script.
# You may be asked to give "Tidyverse API Packages" read/write access to your Google account.

# authenticate your Google account before running the rest of the script
library(googlesheets4) # read from Google Sheets
if (file.exists("/secrets.json")) {
  # use service account key, if it exists
  gs4_auth(path = "/secrets.json")
} else {
  # otherwise, prompt for authentication
  gs4_auth()
}

# load libraries
library(magrittr)
library(reticulate)

# source Python code
source_python("scripts/manual_update.py")

# Southwestern (SWH)
swh_cases() %>%
  {data.frame(readr::parse_number(as.character(.)))} %>%
  range_write(
    ss = "1dTfl_3Zwf7HgRFfwqjsOlvHyDh-sCwgly2YDdHTKaSU",
    data = .,
    sheet = "cases_timeseries_hr",
    range = "D66",
    col_names = FALSE,
    reformat = FALSE
  )
swh_mortality() %>%
  {data.frame(readr::parse_number(as.character(.)))} %>%
  range_write(
    ss = "1dTfl_3Zwf7HgRFfwqjsOlvHyDh-sCwgly2YDdHTKaSU",
    data = .,
    sheet = "mortality_timeseries_hr",
    range = "D66",
    col_names = FALSE,
    reformat = FALSE
  )
swh_recovered() %>%
  {data.frame(readr::parse_number(as.character(.)))} %>%
  range_write(
    ss = "1dTfl_3Zwf7HgRFfwqjsOlvHyDh-sCwgly2YDdHTKaSU",
    data = .,
    sheet = "recovered_timeseries_phu",
    range = "D28",
    col_names = FALSE,
    reformat = FALSE
  )
