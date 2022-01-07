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
date_today <- date(get_time_et())
date_today_manual <- paste0(date_today, "_manual")
date_yesterday <- as.character(date_today - 1)
date_today <- as.character(date_today)

# list files in Google Drive data folder
ss <- drive_ls("ccodwg/data") %>%
  filter(name == "covid19")

# define verification function
verify_data_sources <- function(ss, sheet, loc = c("prov", "hr"), exclude_manual = TRUE) {
  # verify args
  match.arg(loc, choices = c("prov", "hr"), several.ok = FALSE)
  # define cells to read (values for today and yesterday)
  if (loc == "prov") {
    range <- c("A:E")
  } else {
    range <- c("A:F")
  }
  # read cells
  dat <- range_read(ss = ss, sheet = sheet, range = range, col_types = "c")
  
  # for recovered_timeseries_prov, drop "Ontario"
  # this value will always be blank until all automated + manual values for recovered_timeseries_phu are available
  # if automated values from recovered_timeseries_phu are blank, they will be flagged anyway
  if (sheet == "recovered_timeseries_prov") {
    dat <- dat %>%
      filter(province != "Ontario")
  }
  
  # drop cells labelled "MANUAL" (if exclude_manual == TRUE)
  if (exclude_manual) {
    dat <- dat %>% filter(!grepl("^MANUAL", CALCULATION_NOTES))
  }
  # drop cells with manual values provided
  dat <- dat %>% filter(is.na(!!sym(date_today_manual)))
  # rename columns
  if (loc == "prov") {
    dat <- dat %>%
      transmute(location = province,
                value_today = !!sym(date_today),
                value_yesterday = !!sym(date_yesterday))
  } else {
    dat <- dat %>%
      transmute(location = paste(province, health_region, sep = " - "),
                value_today = !!sym(date_today),
                value_yesterday = !!sym(date_yesterday))
  }
  # find blank values
  blanks <- dat %>% filter(is.na(value_today))
  # find zeroes
  zeros <- dat %>% filter(value_today == "0")
  if (nrow(zeros) > 0) {
    # read full spreadsheet
    dat_full <- read_sheet(ss = ss, sheet = sheet, col_types = "c")
    if (loc == "prov") {
      dat_full <- dat_full %>%
        # rename columns
        mutate(location = province) %>%
        # drop unneeded columns
        select(-c("province", "CALCULATION_NOTES", all_of(date_today_manual)))
    } else {
      dat_full <- dat_full %>%
        # rename columns
        mutate(location = paste(province, health_region, sep = " - ")) %>%
        # drop unneeded columns
        select(-c("province", "health_region", "CALCULATION_NOTES", all_of(date_today_manual)))
    }
    # check zeros
    dat_full <- dat_full %>%
      # filter to rows in zeros
      filter(location %in% zeros$location) %>%
      # convert columns to integer
      mutate(across(!location, as.integer)) %>%
      # calculate row sums
      group_by(location) %>%
      mutate(row_sum = rowSums(across(where(is.integer))))
    # filter to zeros where not all values are 0
    zeros <- zeros %>% filter(dat_full$row_sum != 0)
  }
  # find large cumulative changes
  large_changes <- dat %>%
    # drop locations w/ zeros or blanks
    filter(!location %in% c(zeros$location, blanks$location)) %>%
    # exclude "Not Reported" as these are supposed to change by a lot
    filter(!grepl(" - Not Reported$", .data$location)) %>%
    # convert columns to integer
    mutate(across(!location, as.integer)) %>%
    # calculate % change since yesterday
    mutate(percent_change = (value_today - value_yesterday) / value_yesterday * 100) %>%
    # filter to large changes (>20% in absolute value)
    filter(abs(percent_change) > 20)
  # report results
  if (nrow(blanks) == 0 & nrow(zeros) == 0 & nrow(large_changes) == 0) {
    cat(sheet, ": No issues to report", sep = "", fill = TRUE)
  } else {
    # report blanks
    if (nrow(blanks) != 0) {
      cat(sheet, ": Adding blanks", sep = "", fill = TRUE)
      results <<- paste0(results, sheet, ": blanks\n", paste(blanks$location, collapse = "\n"), "\n\n")
    } else {
      cat(sheet, ": No blanks to report", sep = "", fill = TRUE)
    }
    # report zeros
    if (nrow(zeros) != 0) {
      cat(sheet, ": Adding zeros", sep = "", fill = TRUE)
      results <<- paste0(results, sheet, ": zeros\n", paste(zeros$location, collapse = "\n"), "\n\n")
    } else {
      cat(sheet, ": No zeroes to report", sep = "", fill = TRUE)
    }
    # report large cumulative changes
    if (nrow(large_changes) != 0) {
      cat(sheet, ": Adding large cumulative changes", sep = "", fill = TRUE)
      results <<- paste0(results, sheet, ": large cumulative changes\n", paste(paste0(large_changes$location, " (",  formatC(large_changes$percent_change, big.mark = ",", digits = 0, format = "d", flag = "+"), "%)"), collapse = "\n"), "\n\n")
    } else {
      cat(sheet, ": No large cumulative changes to report", sep = "", fill = TRUE)
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
  cat("No missing and/or incorrect values detected. Exiting script...", fill = TRUE)
} else {
  results <<- paste0("Summary of missing and/or potentially incorrect values\n", results)
  cat("Sending email...", fill = TRUE)
  Covid19CanadaETL::send_email(subject = "CCODWG Update: Missing and/or Incorrect Values", body = results)
  cat("Sending notification...", fill = TRUE)
  Covid19CanadaETL::pushover(message = "Some automated values may require manual correction.", title = "CCODWG Update: Missing and/or Incorrect Values", priority = "0")
}
