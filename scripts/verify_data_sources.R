# Check for missing/incorrect values indicating broken data sources in the CCODWG Google Sheets #
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
verify_data_sources <- function(ss, sheet, loc = c("prov", "hr"), exclude_manual = TRUE) {
  # verify args
  match.arg(loc, choices = c("prov", "hr"), several.ok = FALSE)
  # define cells to read
  if (loc == "prov") {
    range <- c("A:D")
  } else {
    range <- c("A:E")
  }
  # read cells
  dat <- range_read(ss = ss, sheet = sheet, range = range, col_types = "c")
  
  # for recovered_timeseries_prov, drop "Ontario"
  # this value will always be blank until all automated + manual values for recovered_timeseries_phu are available
  # if automated values from recovered_timeseries_phu are blank, they will be flagged anyway
  if (sheet == "recovered_timeseries_prov")
    dat <- dat %>%
    filter(province != "Ontario")
  
  # drop cells labelled "MANUAL" (if exclude_manual == TRUE)
  if (exclude_manual) {
    dat <- dat %>% filter(!grepl("^MANUAL", CALCULATION_NOTES))
  }
  # drop cells with manual values provided
  dat <- dat %>% filter(is.na(!!sym(date_today_manual)))
  # rename columns
  if (loc == "prov") {
    dat <- dat %>%
      transmute(location = province, value = !!sym(date_today))
  } else {
    dat <- dat %>%
      transmute(location = paste(province, health_region, sep = " - "), value = !!sym(date_today))
  }
  # find blank values
  blanks <- dat %>% filter(is.na(value))
  # find zeroes
  zeros <- dat %>% filter(value == "0")
  if (nrow(zeros) > 0) {
    # read full spreadsheet
    dat <- read_sheet(ss = ss, sheet = sheet, col_types = "c")
    if (loc == "prov") {
      dat <- dat %>%
        # rename columns
        mutate(location = province) %>%
        # drop unneeded columns
        select(-c("province", "CALCULATION_NOTES", all_of(date_today_manual)))
    } else {
      dat <- dat %>%
        # rename columns
        mutate(location = paste(province, health_region, sep = " - ")) %>%
        # drop unneeded columns
        select(-c("province", "health_region", "CALCULATION_NOTES", all_of(date_today_manual)))
    }
    # check zeros
    dat <- dat %>%
      # filter to rows in zeros
      filter(location %in% zeros$location) %>%
      # convert columns to integer
      mutate(across(!location, as.integer)) %>%
      # calculate row sums
      group_by(location) %>%
      mutate(row_sum = rowSums(across(where(is.integer))))
    # filter to zeros where not all values are 0
    zeros <- zeros %>% filter(dat$row_sum != 0)
  }
  # report results
  if (nrow(blanks) == 0 & nrow(zeros) == 0) {
    cat(sheet, ": No issues to report", sep = "", fill = TRUE)
  } else {
    # report blanks
    if (nrow(blanks) != 0) {
      results <<- paste0(results, sheet, ": blanks\n", paste(blanks$location, collapse = "\n"), "\n\n")
    }
    # report zeros
    if (nrow(zeros) != 0) {
      results <<- paste0(results, sheet, ": zeros\n", paste(zeros$location, collapse = "\n"), "\n\n")
    }
  }
}

# blank results body
results <- ""

# run for health region data
hr_sheets <- c("cases_timeseries_hr", "mortality_timeseries_hr", "recovered_timeseries_phu")
for (s in hr_sheets) {
  verify_data_sources(ss, sheet = s, loc = "hr", exclude_manual = TRUE)
}

# run for provincial data
prov_sheets <- c("recovered_timeseries_prov", "testing_timeseries_prov", "vaccine_distribution_timeseries_prov",
             "vaccine_administration_timeseries_prov", "vaccine_completion_timeseries_prov", "vaccine_additional_doses_timeseries_prov")
for (s in prov_sheets) {
  verify_data_sources(ss, sheet = s, loc = "prov", exclude_manual = TRUE)
}

# send email (if anything to report)
if (results == "") {
  cat("No blanks or zeros detected. Exiting script...", fill = TRUE)
} else {
  results <<- paste0("Summary of blank and/or zero values\n", results)
  cat("Sending email...", fill = TRUE)
  Covid19CanadaETL::send_email(subject = "CCODWG Update - blanks and/or zeros values", body = results)
}
