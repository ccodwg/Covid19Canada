# COVID-19 Canada Open Data Working Group Data Update Script #
# Author: Jean-Paul R. Soucy #

# Download and process updated COVID-19 Canada data files from Google Drive

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

# load functions
source("scripts/update_data_funs.R")

# list files in Google Drive data folder
files <- drive_ls("ccodwg/data")

# update time: current date and time in America/Toronto time zone
update_time <- with_tz(Sys.time(), tzone = "America/Toronto") %>%
  format.Date("%Y-%m-%d %H:%M %Z")
update_date <- as.Date(update_time)
cat(paste0(update_time, "\n"), file = "update_time.txt") # write update_time

# define files and variables
ds <- matrix(
  c(
    "cases_cum", "cases_timeseries_hr", "cases", "date_report", "cumulative_cases", "hr,prov,canada", "cases_ts_hr,cases_ts_prov,cases_ts_canada", "timeseries_hr/cases_timeseries_hr.csv,timeseries_prov/cases_timeseries_prov.csv,timeseries_canada/cases_timeseries_canada.csv",
    "mortality_cum", "mortality_timeseries_hr", "mortality", "date_death_report", "cumulative_deaths", "hr,prov,canada", "mortality_ts_hr,mortality_ts_prov,mortality_ts_canada", "timeseries_hr/mortality_timeseries_hr.csv,timeseries_prov/mortality_timeseries_prov.csv,timeseries_canada/mortality_timeseries_canada.csv",
    "recovered_cum", "recovered_timeseries_prov", "recovered", "date_recovered", "cumulative_recovered", "prov,canada", "recovered_ts_prov,recovered_ts_canada", "timeseries_prov/recovered_timeseries_prov.csv,timeseries_canada/recovered_timeseries_canada.csv",
    "testing_cum", "testing_timeseries_prov", "testing", "date_testing", "cumulative_testing", "prov,canada", "testing_ts_prov,testing_ts_canada", "timeseries_prov/testing_timeseries_prov.csv,timeseries_canada/testing_timeseries_canada.csv",
    "vaccine_distribution_cum", "vaccine_distribution_timeseries_prov", "vaccine_distribution", "date_vaccine_distributed", "cumulative_dvaccine", "prov,canada", "vaccine_distribution_ts_prov,vaccine_distribution_ts_canada", "timeseries_prov/vaccine_distribution_timeseries_prov.csv,timeseries_canada/vaccine_distribution_timeseries_canada.csv",
    "vaccine_administration_cum", "vaccine_administration_timeseries_prov", "vaccine_administration", "date_vaccine_administered", "cumulative_avaccine", "prov,canada", "vaccine_administration_ts_prov,vaccine_administration_ts_canada", "timeseries_prov/vaccine_administration_timeseries_prov.csv,timeseries_canada/vaccine_administration_timeseries_canada.csv",
    "vaccine_completion_cum", "vaccine_completion_timeseries_prov", "vaccine_completion", "date_vaccine_completed", "cumulative_cvaccine", "prov,canada", "vaccine_completion_ts_prov,vaccine_completion_ts_canada", "timeseries_prov/vaccine_completion_timeseries_prov.csv,timeseries_canada/vaccine_completion_timeseries_canada.csv",
    "vaccine_additionaldoses_cum", "vaccine_additional_doses_timeseries_prov", "vaccine_additionaldoses", "date_vaccine_additionaldoses", "cumulative_additionaldosesvaccine", "prov,canada", "vaccine_additionaldoses_ts_prov,vaccine_additionaldoses_ts_canada", "timeseries_prov/vaccine_additionaldoses_timeseries_prov.csv,timeseries_canada/vaccine_additionaldoses_timeseries_canada.csv"
  ),
  ncol = 8,
  byrow = TRUE,
  dimnames = list(NULL, c("file", "drive_name", "val", "var_date", "var_val", "geo", "ts_name", "file_path"))
)
ds <- as.data.frame(ds)

# add phu_recovered to ds (for merging manual column/adding columns for tomorrow)
ds <- ds %>%
  bind_rows(
    data.frame(
      file = "recovered_phu_cum",
      drive_name = "recovered_timeseries_phu",
      var_date = "date_recovered",
      var_val = "cumulative_recovered"
    )
  )

# download sheets, merge in manual column, add columns for tomorrow and upload, process data
for (i in 1:nrow(ds)) {
  
  # define sheet
  var_date <- ds[i, "var_date"]
  var_val <- ds[i, "var_val"]
  
  # download sheet
  assign(ds[i, "file"], {
    sheets_load(files, "covid19", ds[i, "drive_name"])})
  dat <- get(ds[i, "file"])
  
  # merge in today's manual column, if present (replace today's value if the manual value is defined)
  # will have already been merged in if this is not the first time running the script today
  col_manual <- paste0(update_date, "_manual")
  if (col_manual %in% names(dat)) {
    dat <- dat %>%
      # merge in manual data, if given
      mutate(!!sym(as.character(update_date)) := case_when(
        !is.na(!!sym(col_manual)) ~ !!sym(col_manual),
        TRUE ~ !!sym(as.character(update_date))
      )) %>%
      # drop manual column after merge
      select(-!!sym(col_manual))
  }
  
  # add columns for tomorrow (if not present already) and upload to Google Sheets
  col_tomorrow <- as.character(update_date + 1)
  col_tomorrow_manual <- paste0(col_tomorrow, "_manual")
  if (!col_tomorrow %in% names(dat) & !col_tomorrow_manual %in% names(dat)) {
    dat <- dat %>%
      tibble::add_column(
        tibble(
          !!sym(col_tomorrow_manual) := NA,
          !!sym(col_tomorrow) := NA),
        .before = as.character(update_date)
      )
  }
  sheets_upload(dat, files, "covid19", ds[i, "drive_name"])
  
  # process data for update script
  assign(ds[i, "file"], {
    dat %>%
      # delete calculation notes column
      select(-any_of("CALCULATION_NOTES")) %>%
      # delete tomorrow's columns
      select(-any_of(c(col_tomorrow, col_tomorrow_manual))) %>%
      pivot_longer(
        cols = -any_of(c("province", "health_region")),
        names_to = var_date,
        values_to = var_val) %>%
      mutate(
        !!sym(var_date) := as.Date(!!sym(var_date)),
        !!sym(var_val) := as.numeric(!!sym(var_val))
      ) # %>%
      # filter(!is.na(!!sym(var_val)))
    })
}

# remove phu_recovered (not needed)
rm(recovered_phu_cum)
ds <- ds[ds$file != "recovered_phu_cum", ]

# load other files

## province names and short names
map_prov <- read.csv("other/prov_map.csv",
                     stringsAsFactors = FALSE)

## health regions
map_hr <- read.csv("other/hr_map.csv",
                   stringsAsFactors = FALSE)

# define parameters

## provinces and health regions
provs <- map_prov$province
hrs <- map_hr$health_region

## min dates
ds$min_date <- as.Date(apply(ds, MARGIN = 1, FUN = function(x) {
  min(get(x["file"])[[x["var_date"]]])}), origin = "1970-01-01")

## one line per output file
ds <- ds %>%
  separate_rows(geo, ts_name, file_path, sep = ",")

# create time series

## regular time series
for (i in 1:nrow(ds)) {
  assign(ds[[i, "ts_name"]],
    create_ts(get(ds[[i, "file"]]), ds[[i, "val"]], ds[[i, "geo"]], ds[[i, "min_date"]]))
}

## add legacy "testing_info" column
testing_ts_prov <- testing_ts_prov %>%
  left_join(
    read.csv("https://raw.githubusercontent.com/ccodwg/Covid19Canada/master/timeseries_prov/testing_timeseries_prov.csv", stringsAsFactors = FALSE) %>%
      select(province, date_testing, testing_info) %>%
      mutate(date_testing = as.Date(date_testing, "%d-%m-%Y")),
    by = c("province", "date_testing")
  ) %>%
  replace_na(list(testing_info = ""))
testing_ts_canada <- testing_ts_canada %>%
  left_join(
    read.csv("https://raw.githubusercontent.com/ccodwg/Covid19Canada/master/timeseries_canada/testing_timeseries_canada.csv", stringsAsFactors = FALSE) %>%
      select(province, date_testing, testing_info) %>%
      mutate(date_testing = as.Date(date_testing, "%d-%m-%Y")),
    by = c("province", "date_testing")
  ) %>%
  replace_na(list(testing_info = ""))

## active cases time series
active_ts_prov <- create_ts_active(cases_ts_prov, recovered_ts_prov, mortality_ts_prov, "prov")
active_ts_canada <- create_ts_active(cases_ts_canada, recovered_ts_canada, mortality_ts_canada, "canada")

# write time series files

## add active cases to ds
ds <- ds %>%
  bind_rows(
    ds,
    data.frame(
      ts_name = c("active_ts_prov", "active_ts_canada"),
      file_path = c("timeseries_prov/active_timeseries_prov.csv", "timeseries_canada/active_timeseries_canada.csv")))

## write files
for (i in 1:nrow(ds)) {
  file_out <- get(ds[[i, "ts_name"]]) %>%
    mutate(across(matches("^date_|_week$"), format.Date, format = "%d-%m-%Y"))
  write.csv(file_out, ds[[i, "file_path"]], row.names = FALSE)
}
