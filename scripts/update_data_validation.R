# COVID-19 Canada Open Data Working Group Data Update Validation Script #
# Author: Jean-Paul R. Soucy #

# Compare updated data files (from update_data.R) to the current version in the GitHub repository
# GitHub repository: https://github.com/ishaberry/Covid19Canada

# Note: This script assumes the working directory is set to the root directory
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# load libraries
library(dplyr) # data manipulation
library(stringr) # manipulate strings
library(compareDF) # compare data frames
library(crayon) # colourful output in console

# load current data from GitHub repository
temp <- tempfile()
tempd <- tempdir()
download.file("https://github.com/ishaberry/Covid19Canada/archive/master.zip", temp, mode = "wb")
unzip(temp, exdir = tempd)
old_files <- list.files(path = tempd, pattern = "*.csv", full.names = TRUE, recursive = TRUE)
invisible(list2env(
  lapply(setNames(old_files, make.names(paste0("old_", sub(".csv", "", basename(old_files))))), 
         read.csv, stringsAsFactors = FALSE), envir = .GlobalEnv))

# load new data
new_files <- list.files(path = ".", pattern = "*.csv", full.names = TRUE, recursive = TRUE)
invisible(list2env(
  lapply(setNames(new_files, make.names(sub(".csv", "", basename(new_files)))), 
         read.csv, stringsAsFactors = FALSE), envir = .GlobalEnv))

# load update time
old_update_time <- readLines(paste(tempd, "Covid19Canada-master", "update_time.txt", sep = "/"))
update_time <- readLines("update_time.txt")
update_date <- as.Date(update_time)

# stop running script if old update time and new update time are the same
if (identical(old_update_time, update_time)) stop("Update times for old and new data are the same.")

# convert all dates to ISO 8601
for (df in names(which(unlist(eapply(.GlobalEnv, is.data.frame))))) {
  assign(df, get(df) %>%
           mutate_at(
             vars(contains("date")), as.Date, format = "%d-%m-%Y")
           )
}

# define data types
types <- c("cases", "mortality", "recovered", "testing")
types_hr <- c("cases", "mortality")

# define function to print today's cumulative numbers
print_cumulative_today <- function() {
  
  cat("Old data:", old_update_time, fill = TRUE)
  cat("New data:", update_time, "\n", fill = TRUE)
  cat("Today's cumulative numbers...", fill = TRUE)
  cat("Total cases:", cases_timeseries_canada %>% filter(date_report == update_date) %>% pull(cumulative_cases), fill = TRUE)
  cat("Cases today:", cases_timeseries_canada %>% filter(date_report == update_date) %>% pull(cases), fill = TRUE)
  cat("Total deaths:", mortality_timeseries_canada %>% filter(date_death_report == update_date) %>% pull(cumulative_deaths), fill = TRUE)
  cat("Deaths today:", mortality_timeseries_canada %>% filter(date_death_report == update_date) %>% pull(deaths), fill = TRUE)
  cat("Total recovered:", recovered_timeseries_canada %>% filter(date_recovered == update_date) %>% pull(cumulative_recovered), fill = TRUE)
  cat("Recovered today:", recovered_timeseries_canada %>% filter(date_recovered == update_date) %>% pull(recovered), fill = TRUE)
  cat("Total testing:", testing_timeseries_canada %>% filter(date_testing == update_date) %>% pull(cumulative_testing), fill = TRUE) # number repeats?
  cat("Testing today:", testing_timeseries_canada %>% filter(date_testing == update_date) %>% pull(testing), fill = TRUE) # number repeats?
  
}

# define functions for individual-level data

## check ages in case data
check_ages_cases <- function() {
  
  cat("\nChecking ages in case data...", fill = TRUE)
  
  ### transform age map cases
  age_map_cases <- setNames(age_map_cases$age_display, age_map_cases$age) # to pass to recode()
  
  ### transform case data
  cases <- cases %>%
    select(case_id, age) %>%
    mutate(
      age_map = factor(
        recode(age, !!!age_map_cases),
        c(
          "<20",
          "20-29",
          "30-39",
          "40-49",
          "50-59",
          "60-69",
          "70-79",
          "80-89",
          "90-99",
          "100-109",
          "NR"
        )
      )
    )
  
  ### check for new ages
  if (sum(is.na(cases$age_transform)) == 0) {
    cat(green("No new ages."), fill = TRUE)
  } else {
    ### report new ages
    cat(bgRed("New ages:", paste(unique(cases[is.na(cases$age_map), "age"]), collapse = ", ")), fill = TRUE)
  }
  
}

# define functions for time series data

## Canadian data
ts_canada <- function() {
  
  cat("\nChecking Canada time series...", fill = TRUE)
  
  for (type in types) {
    
    ### diff data
    old_file <- paste0("old_", type, "_timeseries_canada")
    new_file <- paste0(type, "_timeseries_canada")
    var_names <- names(get(new_file))
    date_var <- var_names[grepl("date", var_names)]
    diff <- suppressMessages(compare_df(get(new_file), get(old_file), date_var))$comparison_df
    
    ### report differences
    if (nrow(filter(diff, !!sym(date_var) == update_date & chng_type == "+")) == 0) {
      cat(bgRed(paste0("Canada ", type, ": no update today?")), fill = TRUE)
    } else if (nrow(diff) == 1 & nrow(filter(diff, !(!!sym(date_var) == update_date & chng_type == "+"))) == 0) {
      # cat(green(paste0("Canada ", type, ": regular update.")), fill = TRUE) # don't report successes
    } else {
      diff <- filter(diff, !(!!sym(date_var) == update_date & chng_type == "+"))
      cat(bgBlue(paste0("Canada ", type, ": regular update and historical modifications (", paste(unique(pull(diff, date_var)), collapse = ", "), ")")), fill = TRUE)
    }
    
  }
  
}

## provincial data
ts_prov <- function() {
  
  cat("\nChecking provincial time series...\n", fill = TRUE)
  
  for (type in types) {
  
    ### diff data
    old_file <- paste0("old_", type, "_timeseries_prov")
    new_file <- paste0(type, "_timeseries_prov")
    var_names <- names(get(new_file))
    date_var <- var_names[grepl("date", var_names)]
    diff <- suppressMessages(compare_df(get(new_file), get(old_file), date_var))$comparison_df
    
    ### loop through provinces
    for (prov in unique(get(new_file)$province)) {
      
      ### report differences
      diff_prov <- diff %>%
        filter(province == prov)
      if (nrow(filter(diff_prov, !!sym(date_var) == update_date & chng_type == "+")) == 0) {
        cat(bgRed(paste0(prov, " ", type, ": no update today?")), fill = TRUE)
      } else if (nrow(diff_prov) == 1 & nrow(filter(diff_prov, !(!!sym(date_var) == update_date & chng_type == "+"))) == 0) {
        # cat(green(paste0(prov, " ", type, ": regular update.")), fill = TRUE) # don't report successes
      } else {
        diff_prov <- filter(diff_prov, !(!!sym(date_var) == update_date & chng_type == "+"))
        cat(bgBlue(paste0(prov, " ", type, ": regular update and historical modifications (", paste(unique(pull(diff_prov, date_var)), collapse = ", "), ")")), fill = TRUE)
      }
      
    }
    
  }
  
}

## health region data
### Interpretation note: If the script reports historical modifications for the entire time series back to the beginning,
### it likely means the health region was newly added and the script has assembled a new time series
### for the new health region going back to the beginning (filled with 0s except for the most recent date).
### The new health region is either a misspelling of an existing health region or a "not reported" health region
### for a province that did not previously have this.
ts_hr <- function() {
  
  cat("\nChecking health region time series...\n", fill = TRUE)
  
  for (type in types_hr) {
    
    ### diff data
    old_file <- paste0("old_", type, "_timeseries_hr")
    new_file <- paste0(type, "_timeseries_hr")
    var_names <- names(get(new_file))
    date_var <- var_names[grepl("date", var_names)]
    diff <- suppressMessages(compare_df(get(new_file), get(old_file), date_var))$comparison_df
    hr_list <- distinct(select(diff, province, health_region)) # list health regions
    
    ### loop through provinces
    for (prov in unique(get(new_file)$province)) {
      
      cat("Testing ", type, " from health regions in ", prov, "...\n", sep = "", fill = TRUE)
      diff_prov <- diff %>%
        filter(province == prov)
      
      ### loop through health regions
      for (hr in hr_list %>% filter(province == prov) %>% pull(health_region)) {
        
        ### report differences
        diff_hr <- diff_prov %>%
          filter(health_region == hr)
        if (nrow(filter(diff_hr, !!sym(date_var) == update_date & chng_type == "+")) == 0) {
          if (hr == "Not reported") {
            cat(bgRed(paste0(hr, " (", prov, ") ", type, ": no update today?")), fill = TRUE) 
          } else {
            cat(bgRed(paste0(hr, " (", prov, ") ", type, ": Not Reported series deleted. Did they all get assigned a health region?")), fill = TRUE)
          }
        } else if (nrow(diff_hr) == 1 & nrow(filter(diff_hr, !(!!sym(date_var) == update_date & chng_type == "+"))) == 0) {
          # cat(green(paste0(hr, " (", prov, ") ", type, ": regular update.")), fill = TRUE) # don't report successes
        } else {
          diff_hr <- filter(diff_hr, !(!!sym(date_var) == update_date & chng_type == "+"))
          cat(bgBlue(paste0(hr, " (", prov, ") ", type, ": regular update and historical modifications (", paste(unique(pull(diff_hr, date_var)), collapse = ", "), ")")), fill = TRUE)
        }
        
      }
      
    }
    
  }
  
}

## print today's cumulative numbers and daily changes
print_cumulative_today()

## check ages in individual-level case data
check_ages_cases()

## check Canadian time series
ts_canada()

## check provincial time series
ts_prov()

## check health region time series
ts_hr()

# delete temporary files
unlink(temp) # delete GitHub download
unlink(paste(tempd, "Covid19Canada-master", sep = "/"), recursive = TRUE) # delete unzipped files