# COVID-19 Canada Open Data Working Group - API Testing #
# Author: Jean-Paul R. Soucy #

# Compare consistency of data obtained as CSV files from the GitHub repository (https://github.com/ishaberry/Covid19Canada)
# with data obtained as JSON files from the API (http://api.opencovid.ca/ | documentation: https://opencovid.ca/api/)

# load libraries
library(dplyr) # data manipulation
library(purrr) # data manipulation
library(jsonlite) # fromJSON
library(compareDF) # compare_DF

# function: check if identical
check_identical <- function(x, y) {
  if (identical(x, y)) {
    cat("Data frames are identical.", fill = TRUE)
  } else {
    stop("Data frames are not identical.")
  }
}

# read update date of dataset
update_date <- format(as.Date(readLines("https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/update_time.txt")), "%d-%m-%Y")

# define datasets
ts_data <- c("active", "cases", "mortality", "recovered", "testing")
ts_data_hr <- c("cases", "mortality")

# compare individual-level data

## cases
dat_gh <- read.csv("https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/cases.csv", stringsAsFactors = FALSE)
dat_api <- fromJSON("http://api.opencovid.ca/individual?stat=cases")$cases %>%
  select(names(dat_gh)) %>%
  mutate(
    method_note = as.integer(ifelse(method_note == "NULL", NA, method_note)),
    across(!method_note, ~{ifelse(.x == "NULL", "", .x)})
  )
check_identical(dat_gh, dat_api)

## mortality
dat_gh <- read.csv("https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/mortality.csv", stringsAsFactors = FALSE)
dat_api <- fromJSON("http://api.opencovid.ca/individual?stat=mortality")$mortality %>%
  select(names(dat_gh)) %>%
  mutate(
    case_id = as.integer(ifelse(case_id == "NULL", NA, case_id)),
    across(!case_id, ~{ifelse(.x == "NULL", "", .x)})
  )
check_identical(dat_gh, dat_api)

# compare time series data

## Canada
dat_api <- fromJSON("http://api.opencovid.ca/timeseries?loc=canada")
for (ts in ts_data) {
  
  dat_gh <- read.csv(paste0("https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_canada/", ts, "_timeseries_canada.csv"), stringsAsFactors = FALSE)
  dat_api_ts <- dat_api[[ts]] %>%
    select(names(dat_gh)) %>%
    mutate(
      across(everything(), ~{ifelse(.x == "NULL", "", .x)})
    )
  check_identical(dat_gh, dat_api_ts)
  
}

## provinces
dat_api <- fromJSON("http://api.opencovid.ca/timeseries?loc=prov")
for (ts in ts_data) {
  
  dat_gh <- read.csv(paste0("https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_prov/", ts, "_timeseries_prov.csv"), stringsAsFactors = FALSE)
  dat_api_ts <- dat_api[[ts]] %>%
    select(names(dat_gh)) %>%
    mutate(
      across(everything(), ~{ifelse(.x == "NULL", "", .x)})
    )
  check_identical(dat_gh, dat_api_ts)
  
}

## health regions
dat_api <- fromJSON("http://api.opencovid.ca/timeseries?loc=hr")
for (ts in ts_data_hr) {
  
  dat_gh <- read.csv(paste0("https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_hr/", ts, "_timeseries_hr.csv"), stringsAsFactors = FALSE)
  dat_api_ts <- dat_api[[ts]] %>%
    select(names(dat_gh)) %>%
    mutate(
      across(everything(), ~{ifelse(.x == "NULL", "", .x)})
    )
  check_identical(dat_gh, dat_api_ts)
  
}

# summaries

## Canada
for (ts in ts_data) {
  
  assign(paste0("ts_", ts),
         read.csv(paste0("https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_canada/", ts, "_timeseries_canada.csv"), stringsAsFactors = FALSE) %>%
           {if (ts == "active") select(., -starts_with("cumulative")) else .} %>%
           rename_with(.fn = ~{"date"}, .cols = starts_with("date_"))
  )
  
}
dat_gh <- mget(paste0("ts_", ts_data)) %>% 
  reduce(full_join, by = c("province", "date")) %>%
  filter(date == update_date)
dat_api <- fromJSON("http://api.opencovid.ca/summary?loc=canada")$summary %>%
  as.data.frame %>%
  select(names(dat_gh)) %>%
  mutate(
    across(where(is.numeric), as.integer),
    across(where(negate(is.integer)), ~{ifelse(.x == "NULL", "", .x)})
  )
check_identical(dat_gh, dat_api)

# provinces
for (ts in ts_data) {
  
  assign(paste0("ts_", ts),
         read.csv(paste0("https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_prov/", ts, "_timeseries_prov.csv"), stringsAsFactors = FALSE) %>%
           {if (ts == "active") select(., -starts_with("cumulative")) else .} %>%
           rename_with(.fn = ~{"date"}, .cols = starts_with("date_"))
  )
  
}
dat_gh <- mget(paste0("ts_", ts_data)) %>% 
  reduce(full_join, by = c("province", "date")) %>%
  mutate(
    across(matches("cases$|deaths$|recovered$|testing$"), ~{as.integer(ifelse(is.na(.x), 0, .x))}),
    across(where(negate(is.integer)), ~{ifelse(is.na(.x), "", .x)})
  ) %>%
  filter(date == update_date)
dat_api <- fromJSON("http://api.opencovid.ca/summary?loc=prov")$summary %>%
  as.data.frame %>%
  select(names(dat_gh)) %>%
  mutate(
    across(matches("cases$|deaths$|recovered$|testing$"), ~{as.integer(ifelse(.x == "NULL", 0, .x))}),
    across(where(negate(is.integer)), ~{ifelse(.x == "NULL", "", .x)})
  )
check_identical(dat_gh, dat_api)

## health regions
for (ts in ts_data_hr) {
  
  assign(paste0("ts_", ts),
         read.csv(paste0("https://raw.githubusercontent.com/ishaberry/Covid19Canada/master/timeseries_hr/", ts, "_timeseries_hr.csv"), stringsAsFactors = FALSE) %>%
           {if (ts == "active") select(., -starts_with("cumulative")) else .} %>%
           rename_with(.fn = ~{"date"}, .cols = starts_with("date_"))
  )
  
}
dat_gh <- mget(paste0("ts_", ts_data_hr)) %>% 
  reduce(full_join, by = c("province", "health_region", "date")) %>%
  mutate(
    across(matches("cases$|deaths$|recovered$|testing$"), ~{as.integer(ifelse(is.na(.x), 0, .x))}),
    across(where(negate(is.integer)), ~{ifelse(is.na(.x), "", .x)})
  ) %>%
  filter(date == update_date)
dat_api <- fromJSON("http://api.opencovid.ca/summary?loc=hr")$summary %>%
  as.data.frame %>%
  select(names(dat_gh)) %>%
  mutate(
    across(matches("cases$|deaths$|recovered$|testing$"), ~{as.integer(ifelse(.x == "NULL", 0, .x))}),
    across(where(negate(is.integer)), ~{ifelse(.x == "NULL", "", .x)})
  )
check_identical(dat_gh, dat_api)

# version
dat_gh <- readLines("https://github.com/ishaberry/Covid19Canada/raw/master/update_time.txt")
dat_api <- fromJSON("http://api.opencovid.ca/version")$version
check_identical(dat_gh, dat_api)