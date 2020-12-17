# COVID-19 Canada Open Data Working Group Data Update Script #
# Author: Jean-Paul R. Soucy #

# Download and process updated COVID-19 Canada data files from Google Drive

# Note: This script assumes the working directory is set to the root directory of the project
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# Authentication: You must authenticate your Google account before running the rest of the script. You may be asked to give "Tidyverse API Packages" read/write access to your Google account.

# authenticate your Google account before running the rest of the script
library(googledrive) # interface with Google drive
drive_auth()

# load libraries
library(dplyr) # data manipulation
library(tidyr) # data manipulation
library(lubridate) # better dates

# load functions
source("scripts/update_data_funs.R")

# update time: current date and time in America/Toronto time zone
update_time <- with_tz(Sys.time(), tzone = "America/Toronto") %>%
  format.Date("%Y-%m-%d %H:%M %Z")
update_date <- as.Date(update_time)
cat(paste0(update_time, "\n"), file = "update_time.txt") # write update_time

# list files in Google Drive data folder
files <- drive_ls("Public_List")

# download sheets and copy into project folder
files %>% filter(name == "cases.csv") %>% drive_download(overwrite = TRUE)
files %>% filter(name == "mortality.csv") %>% drive_download(overwrite = TRUE)
files %>% filter(name == "recovered_cumulative.csv") %>% drive_download(overwrite = TRUE)
files %>% filter(name == "testing_cumulative.csv") %>% drive_download(overwrite = TRUE)
files %>% filter(name == "vaccine_administration_cumulative.csv") %>% drive_download(overwrite = TRUE)
files %>% filter(name == "vaccine_distribution_cumulative.csv") %>% drive_download(overwrite = TRUE)

# read downloaded sheets
cases <- read.csv("cases.csv",
                  stringsAsFactors = FALSE)
mortality <- read.csv("mortality.csv",
                      stringsAsFactors = FALSE)
recovered_cum <- read.csv("recovered_cumulative.csv",
                          stringsAsFactors = FALSE)
testing_cum <- read.csv("testing_cumulative.csv",
                        stringsAsFactors = FALSE)
vaccine_administration_cum <- read.csv("vaccine_administration_cumulative.csv",
                                       stringsAsFactors = FALSE)
vaccine_distribution_cum <- read.csv("vaccine_distribution_cumulative.csv",
                                     stringsAsFactors = FALSE)

# load other files

## province names and short names
map_prov <- read.csv("other/prov_map.csv",
                     stringsAsFactors = FALSE)

## health regions
map_hr <- read.csv("other/hr_map.csv",
                   stringsAsFactors = FALSE)

## case_source abbreviation table
cases_case_source <- read.csv("cases_extra/cases_case_source.csv",
                              stringsAsFactors = FALSE,
                              colClasses = c(
                                "province" = "character",
                                "case_source_id" = "integer",
                                "case_source_short" = "character",
                                "case_source_full" = "character"
                              ))

## death_source abbreviation table
mortality_death_source <- read.csv("mortality_extra/mortality_death_source.csv",
                                   stringsAsFactors = FALSE,
                                   colClasses = c(
                                     "province" = "character",
                                     "death_source_id" = "integer",
                                     "death_source_short" = "character",
                                     "death_source_full" = "character"
                                   ))

# convert dates to standard format for manipulation
convert_dates("cases", "mortality", "recovered_cum", "testing_cum", "vaccine_administration_cum", "vaccine_distribution_cum", date_format_out = "%Y-%m-%d")

# define parameters

## provinces and health regions
provs <- map_prov$province
hrs <- map_hr$health_region

## min dates
date_min_cases <- min(cases$date_report)
date_min_mortality <- min(mortality$date_death_report)
date_min_recovered <- min(recovered_cum$date_recovered)
date_min_testing <- min(testing_cum$date_testing)
date_min_vaccine_administration <- min(vaccine_administration_cum$date_vaccine_administered)
date_min_vaccine_distribution <- min(vaccine_distribution_cum$date_vaccine_distributed)

# create time series

## cases time series
cases_ts_hr <- create_ts(cases, "cases", "hr", date_min_cases)
cases_ts_prov <- create_ts(cases, "cases", "prov", date_min_cases)
cases_ts_canada <- create_ts(cases, "cases", "canada", date_min_cases)

## mortality time series
mortality_ts_hr <- create_ts(mortality, "mortality", "hr", date_min_mortality)
mortality_ts_prov <- create_ts(mortality, "mortality", "prov", date_min_mortality)
mortality_ts_canada <- create_ts(mortality, "mortality", "canada", date_min_mortality)

## recovered time series
recovered_ts_prov <- create_ts(recovered_cum, "recovered", "prov", date_min_recovered)
recovered_ts_canada <- create_ts(recovered_cum, "recovered", "canada", date_min_recovered)

## testing time series
testing_ts_prov <- create_ts(testing_cum, "testing", "prov", date_min_testing)
testing_ts_canada <- create_ts(testing_cum, "testing", "canada", date_min_testing)

## active cases time series
active_ts_prov <- create_ts_active(cases_ts_prov, recovered_ts_prov, mortality_ts_prov, "prov")
active_ts_canada <- create_ts_active(cases_ts_canada, recovered_ts_canada, mortality_ts_canada, "canada")

## vaccine administration time series
vaccine_administration_ts_prov <- create_ts(vaccine_administration_cum, "vaccine_administration", "prov", date_min_vaccine_administration)
vaccine_administration_ts_canada <- create_ts(vaccine_administration_cum, "vaccine_administration", "canada", date_min_vaccine_administration)

## vaccine distribution time series
vaccine_distribution_ts_prov <- create_ts(vaccine_distribution_cum, "vaccine_distribution", "prov", date_min_vaccine_distribution)
vaccine_distribution_ts_canada <- create_ts(vaccine_distribution_cum, "vaccine_distribution", "canada", date_min_vaccine_distribution)

# abbreviate "case_source" (cases.csv) and "death_source" (mortality.csv)
abbreviate_source(cases, cases_case_source, "case_source")
abbreviate_source(mortality, mortality_death_source, "death_source")

# convert dates to non-standard date format for writing
convert_dates("cases", "mortality", "recovered_cum", "testing_cum",
              "cases_ts_canada", "mortality_ts_canada", "recovered_ts_canada", "testing_ts_canada", "active_ts_canada",
              "cases_ts_prov", "mortality_ts_prov", "recovered_ts_prov", "testing_ts_prov", "active_ts_prov",
              "cases_ts_hr", "mortality_ts_hr",
              "vaccine_administration_cum", "vaccine_administration_ts_prov", "vaccine_administration_ts_canada",
              "vaccine_distribution_cum", "vaccine_distribution_ts_prov", "vaccine_distribution_ts_canada",
              date_format_out = "%d-%m-%Y")

# write generated files
write.csv(cases, "cases.csv", row.names = FALSE)
write.csv(cases_case_source, "cases_extra/cases_case_source.csv", row.names = FALSE)
write.csv(mortality, "mortality.csv", row.names = FALSE)
write.csv(mortality_death_source, "mortality_extra/mortality_death_source.csv", row.names = FALSE)
write.csv(recovered_cum, "recovered_cumulative.csv", row.names = FALSE)
write.csv(testing_cum, "testing_cumulative.csv", row.names = FALSE)
write.csv(cases_ts_prov, "timeseries_prov/cases_timeseries_prov.csv", row.names = FALSE)
write.csv(cases_ts_hr, "timeseries_hr/cases_timeseries_hr.csv", row.names = FALSE)
write.csv(cases_ts_canada, "timeseries_canada/cases_timeseries_canada.csv", row.names = FALSE)
write.csv(mortality_ts_prov, "timeseries_prov/mortality_timeseries_prov.csv", row.names = FALSE)
write.csv(mortality_ts_hr, "timeseries_hr/mortality_timeseries_hr.csv", row.names = FALSE)
write.csv(mortality_ts_canada, "timeseries_canada/mortality_timeseries_canada.csv", row.names = FALSE)
write.csv(recovered_ts_prov, "timeseries_prov/recovered_timeseries_prov.csv", row.names = FALSE)
write.csv(recovered_ts_canada, "timeseries_canada/recovered_timeseries_canada.csv", row.names = FALSE)
write.csv(testing_ts_prov, "timeseries_prov/testing_timeseries_prov.csv", row.names = FALSE)
write.csv(testing_ts_canada, "timeseries_canada/testing_timeseries_canada.csv", row.names = FALSE)
write.csv(active_ts_prov, "timeseries_prov/active_timeseries_prov.csv", row.names = FALSE)
write.csv(active_ts_canada, "timeseries_canada/active_timeseries_canada.csv", row.names = FALSE)
write.csv(vaccine_administration_cum, "vaccine_administration_cumulative.csv", row.names = FALSE)
write.csv(vaccine_administration_ts_prov, "timeseries_prov/vaccine_administration_timeseries_prov.csv", row.names = FALSE)
write.csv(vaccine_administration_ts_canada, "timeseries_canada/vaccine_administration_timeseries_canada.csv", row.names = FALSE)
write.csv(vaccine_distribution_cum, "vaccine_distribution_cumulative.csv", row.names = FALSE)
write.csv(vaccine_distribution_ts_prov, "timeseries_prov/vaccine_distribution_timeseries_prov.csv", row.names = FALSE)
write.csv(vaccine_distribution_ts_canada, "timeseries_canada/vaccine_distribution_timeseries_canada.csv", row.names = FALSE)