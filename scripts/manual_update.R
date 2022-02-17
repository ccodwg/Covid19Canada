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
library(lubridate)
library(reticulate)

# source Python code
source_python("scripts/manual_update.py")

copy_cells <- function(sheet, read_cells, write_cells) {
  # read cells
  vals <- range_read(
    ss = "1dTfl_3Zwf7HgRFfwqjsOlvHyDh-sCwgly2YDdHTKaSU",
    sheet = sheet,
    range = read_cells,
    col_types = "c",
    col_names = "val"
  )
  # write cells
  range_write(
    ss = "1dTfl_3Zwf7HgRFfwqjsOlvHyDh-sCwgly2YDdHTKaSU",
    data = vals,
    sheet = sheet,
    range = write_cells,
    col_names = FALSE,
    reformat = FALSE
  )
}

# set today's date
date_today <- as.Date(with_tz(Sys.time(), "America/Toronto"))

# Ontario PHUs #

# Hastings Prince Edward (HPE)
if (!weekdays(date_today) %in% c("Monday", "Wednesday", "Friday")) {
  copy_cells("cases_timeseries_hr", "F50", "D50")
  copy_cells("mortality_timeseries_hr", "F50", "D50")
  copy_cells("recovered_timeseries_phu", "F12", "D12")
}

# Kingston Frontenac Lennox & Addington (KFL)
if (!weekdays(date_today) %in% c("Monday", "Wednesday", "Friday")) {
  copy_cells("cases_timeseries_hr", "F52", "D52")
  copy_cells("mortality_timeseries_hr", "F52", "D52")
  copy_cells("recovered_timeseries_phu", "F14", "D14")
}

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

# Saskatchewan #

# Update SK with old values
copy_cells("cases_timeseries_hr", "F96:F102", "D96:D102")
copy_cells("mortality_timeseries_hr", "F96:F102", "D96:D102")
copy_cells("recovered_timeseries_prov", "E14", "C14")
copy_cells("testing_timeseries_prov", "E14", "C14")
copy_cells("vaccine_administration_timeseries_prov", "E13", "C13")
copy_cells("vaccine_completion_timeseries_prov", "E13", "C13")
copy_cells("vaccine_additional_doses_timeseries_prov", "E13", "C13")
