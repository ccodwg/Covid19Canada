# Check if all rows marked manual have been inputed today in the CCODWG Google Sheets #
# Author: Jean-Paul R. Soucy #

# Note: This script assumes the working directory is set to the root directory of the project
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# Authentication: You must authenticate your Google account before running the rest of the script.
# You may be asked to give "Tidyverse API Packages" read/write access to your Google account.
# All the scripts called by this script assume authentication has been already performed.

# authenticate your Google account before running the rest of the script
library(googledrive) # interface with Google Drive
library(googlesheets4) # read from Google Sheets
if (file.exists("/secrets.json")) {
  # use service account key, if it exists
  drive_auth(path = "/secrets.json")
  gs4_auth(path = "/secrets.json")
} else {
  # otherwise, prompt for authentication
  drive_auth()
  gs4_auth()
}

# load functions
source("scripts/conductor_update_nightly_funs.R")

# load libraries
library(lubridate)
library(dplyr)

# get today's date
date_today <- as.character(date(get_time_et()))
date_today_manual <- paste0(date_today, "_manual")

# list files in Google Drive data folder
ss <- drive_ls("ccodwg/data") %>%
  filter(name == "covid19")

# define verification function
verify_manual_data <- function(ss, sheet, loc = c("prov", "hr")) {
  # verify args
  match.arg(loc, choices = c("prov", "hr"), several.ok = FALSE)
  # define cells to read
  if (loc == "prov") {
    range <- c("A:C")
  } else {
    range <- c("A:D")
  }
  # read cells
  dat <- range_read(ss = ss, sheet = sheet, range = range, col_types = "c") %>%
    # keep cells labelled "MANUAL"
    filter(grepl("^MANUAL", CALCULATION_NOTES))
  # check if any manual values
  if (nrow(dat) == 0) {
    return(cat(sheet, ": No manual values required", sep = "", fill = TRUE))
  }
  dat <- dat %>%
    # drop cells with manual values provided
    filter(is.na(!!sym(date_today_manual)))
  # check if any rows remain after filtering those with manual values provided
  if (nrow(dat) == 0) {
    return(cat(sheet, ": All manual values have been provided", sep = "", fill = TRUE))
  }
  # rename columns
  if (loc == "prov") {
    dat <- dat %>%
      {pull(transmute(., location = province))}
  } else {
    dat <- dat %>%
      {pull(transmute(., location = paste(province, health_region, sep = " - ")))}
  }
  # report results
  results <<- paste0(results, sheet, ": Manual values are missing\n", paste(dat, collapse = "\n"), "\n\n")
}

# blank results body
results <- ""

# run for health region data
hr_sheets <- c("cases_timeseries_hr", "mortality_timeseries_hr", "recovered_timeseries_phu")
for (s in hr_sheets) {
  verify_manual_data(ss, sheet = s, loc = "hr")
}

# run for provincial data
prov_sheets <- c("recovered_timeseries_prov", "testing_timeseries_prov", "vaccine_distribution_timeseries_prov",
                 "vaccine_administration_timeseries_prov", "vaccine_completion_timeseries_prov", "vaccine_additional_doses_timeseries_prov")
for (s in prov_sheets) {
  verify_manual_data(ss, sheet = s, loc = "prov")
}

# send email & notification (if anything to report)
if (results == "") {
  cat("No manual values are missing. Exiting script...", fill = TRUE)
} else {
  cat("Sending email...", fill = TRUE)
  send_email(subject = "CCODWG Update - manual values are missing", body = results)
  cat("Sending notification...", fill = TRUE)
  pushover(message = "Attention required.", priority = 1, title = "Manual values are missing")
}