# Functions for: COVID-19 Canada Open Data Working Group Data Update Validation Script #
# Author: Jean-Paul R. Soucy #

# define functions for loading data

## download current data from GitHub repository
download_current_data <- function() {
  
  temp <- tempfile()
  tempd <- tempdir()
  download.file("https://github.com/ccodwg/Covid19Canada/archive/master.zip", temp, mode = "wb")
  unzip(temp, exdir = tempd)
  old_files <- list.files(path = tempd, pattern = "*.csv", full.names = TRUE, recursive = TRUE)
  invisible(list2env(
    lapply(setNames(old_files, make.names(paste0("old_", sub(".csv", "", basename(old_files))))), 
           read.csv, stringsAsFactors = FALSE), envir = .GlobalEnv))
  assign("old_update_time", readLines(paste(tempd, "Covid19Canada-master", "update_time.txt", sep = "/")),
         envir = .GlobalEnv)
  ### delete temporary files
  unlink(temp) # delete GitHub download
  unlink(paste(tempd, "Covid19Canada-master", sep = "/"), recursive = TRUE) # delete unzipped files
  
}

## load new data
load_new_data <- function() {
 
  new_files <- list.files(path = ".", pattern = "*.csv", full.names = TRUE, recursive = TRUE)
  invisible(list2env(
    lapply(setNames(new_files, make.names(sub(".csv", "", basename(new_files)))), 
           read.csv, stringsAsFactors = FALSE), envir = .GlobalEnv))
  assign("update_time", readLines("update_time.txt"), envir = .GlobalEnv)
  assign("update_date", as.Date(update_time), envir = .GlobalEnv)
   
}

## convert all dates to ISO 8601
convert_dates <- function() {
 
  for (df in names(which(unlist(eapply(.GlobalEnv, is.data.frame))))) {
    assign(df, get(df) %>%
             mutate(
               across(starts_with("date_"), as.Date, format = "%d-%m-%Y")),
           envir = .GlobalEnv
    )
  }
   
}

# define data types
types <- c("cases", "mortality", "recovered", "testing")
types_hr <- c("cases", "mortality")

# define function to print today's cumulative numbers
print_summary_today <- function() {
  
  cat("Old data:", old_update_time, fill = TRUE)
  cat("New data:", update_time, "\n", fill = TRUE)
  cat("Today's summary...", fill = TRUE)
  cat("Total cases:", cases_timeseries_canada %>% filter(date_report == update_date) %>% pull(cumulative_cases), fill = TRUE)
  cat("Cases today:", cases_timeseries_canada %>% filter(date_report == update_date) %>% pull(cases), fill = TRUE)
  cat("Total deaths:", mortality_timeseries_canada %>% filter(date_death_report == update_date) %>% pull(cumulative_deaths), fill = TRUE)
  cat("Deaths today:", mortality_timeseries_canada %>% filter(date_death_report == update_date) %>% pull(deaths), fill = TRUE)
  cat("Total recovered:", recovered_timeseries_canada %>% filter(date_recovered == update_date) %>% pull(cumulative_recovered), fill = TRUE)
  cat("Recovered today:", recovered_timeseries_canada %>% filter(date_recovered == update_date) %>% pull(recovered), fill = TRUE)
  cat("Total testing:", testing_timeseries_canada %>% filter(date_testing == update_date) %>% pull(cumulative_testing), fill = TRUE)
  cat("Testing today:", testing_timeseries_canada %>% filter(date_testing == update_date) %>% pull(testing), fill = TRUE)
  cat("Vaccine distribution today:", vaccine_distribution_timeseries_canada %>% filter(date_vaccine_distributed == update_date) %>% pull(dvaccine), fill = TRUE)
  cat("Total vaccine distribution:", vaccine_distribution_timeseries_canada %>% filter(date_vaccine_distributed == update_date) %>% pull(cumulative_dvaccine), fill = TRUE)
  cat("Vaccine administration today:", vaccine_administration_timeseries_canada %>% filter(date_vaccine_administered == update_date) %>% pull(avaccine), fill = TRUE)
  cat("Total vaccine administration:", vaccine_administration_timeseries_canada %>% filter(date_vaccine_administered == update_date) %>% pull(cumulative_avaccine), fill = TRUE)
  cat("Vaccine completion today:", vaccine_completion_timeseries_canada %>% filter(date_vaccine_completed == update_date) %>% pull(cvaccine), fill = TRUE)
  cat("Total vaccine completion:", vaccine_completion_timeseries_canada %>% filter(date_vaccine_completed == update_date) %>% pull(cumulative_cvaccine), fill = TRUE)
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
      
      cat("Checking ", type, " from health regions in ", prov, "...\n", sep = "", fill = TRUE)
      diff_prov <- diff %>%
        filter(province == prov)
      
      ### loop through health regions
      for (hr in hr_list %>% filter(province == prov) %>% pull(health_region)) {
        
        ### report differences
        diff_hr <- diff_prov %>%
          filter(health_region == hr)
        if (nrow(filter(diff_hr, !!sym(date_var) == update_date & chng_type == "+")) == 0) {
            cat(bgRed(paste0(hr, " (", prov, ") ", type, ": no update today?")), fill = TRUE)
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

# report zeros and negatives in time series
report_zeros_negatives <- function(report_positive = FALSE, report_hr = FALSE) {
  
  cat("\nReporting zeros and negatives in time series...\n", fill = TRUE)
  x <- "date_report"
  
  ## function: find locations with 0 on current date
  loc_0 <- function(dat, date_var, value_var, loc_var) {
    dat %>%
      filter(!!sym(date_var) == update_date & !!sym(value_var) == 0) %>%
      pull(!!sym(loc_var))
  }
  
  ## function: find locations with > 0 on current date
  loc_non_0 <- function(dat, date_var, value_var, loc_var) {
    dat %>%
      filter(!!sym(date_var) == update_date & !!sym(value_var) > 0) %>%
      pull(!!sym(loc_var))
  }
  
  loc_negative <- function(dat, date_var, value_var, loc_var) {
    dat %>%
      filter(!!sym(date_var) == update_date & !!sym(value_var) < 0) %>%
      pull(!!sym(loc_var))
  }
  
  ## cases
  provs_negative <- loc_negative(cases_timeseries_prov, "date_report", "cases", "province")
  provs_0 <- loc_0(cases_timeseries_prov, "date_report", "cases", "province")
  provs_non_0 <- loc_non_0(cases_timeseries_prov, "date_report", "cases", "province")
  if (length(provs_negative) > 0) {
    cat(bgRed("Provinces reporting negative cases today:", paste(provs_negative, collapse = ", "), "\n"), fill = TRUE) 
  }
  cat(cyan("Provinces reporting 0 cases today:", paste(provs_0, collapse = ", "), "\n"), fill = TRUE)
  if (report_positive) {
    cat(green("Provinces reporting > 0 cases today:", paste0(provs_non_0, collapse = ", "), "\n"), fill = TRUE) 
  }
  if (report_hr) {
    for (prov in provs_non_0) {
      hr_0 <- cases_timeseries_hr %>%
        filter(province == prov & date_report == update_date & cases == 0) %>%
        pull(health_region)
      cat(cyan(prov, "health regions reporting 0 cases today:", paste(hr_0, collapse = ", "), "\n"), fill = TRUE)
    }
  }
  
  ## mortality
  provs_negative <- loc_negative(mortality_timeseries_prov, "date_death_report", "deaths", "province")
  provs_0 <- loc_0(mortality_timeseries_prov, "date_death_report", "deaths", "province")
  provs_non_0 <- loc_non_0(mortality_timeseries_prov, "date_death_report", "deaths", "province")
  if (length(provs_negative) > 0) {
    cat(bgRed("Provinces reporting negative deaths today:", paste(provs_negative, collapse = ", "), "\n"), fill = TRUE) 
  }
  cat(cyan("Provinces reporting 0 deaths today:", paste(provs_0, collapse = ", "), "\n"), fill = TRUE)
  if (report_positive) {
    cat(green("Provinces reporting > 0 deaths today:", paste0(provs_non_0, collapse = ", "), "\n"), fill = TRUE)
  }
  if (report_hr) {
    for (prov in provs_non_0) {
      hr_0 <- mortality_timeseries_hr %>%
        filter(province == prov & date_death_report == update_date & deaths == 0) %>%
        pull(health_region)
      cat(cyan(prov, "health regions reporting 0 deaths today:", paste(hr_0, collapse = ", "), "\n"), fill = TRUE)
    }
  }
  
  ## recovered
  provs_negative <- loc_negative(recovered_timeseries_prov, "date_recovered", "recovered", "province")
  provs_0 <- loc_0(recovered_timeseries_prov, "date_recovered", "recovered", "province")
  provs_non_0 <- loc_non_0(recovered_timeseries_prov, "date_recovered", "recovered", "province")
  if (length(provs_negative) > 0) {
    cat(bgRed("Provinces reporting negative recovered today:", paste(provs_negative, collapse = ", "), "\n"), fill = TRUE) 
  }
  cat(cyan("Provinces reporting 0 recovered today:", paste(provs_0, collapse = ", "), "\n"), fill = TRUE)
  if (report_positive) {
    cat(green("Provinces reporting > 0 recovered today:", paste0(provs_non_0, collapse = ", "), "\n"), fill = TRUE)
  }
  
  ## testing
  provs_negative <- loc_negative(testing_timeseries_prov, "date_testing", "testing", "province")
  provs_0 <- loc_0(testing_timeseries_prov, "date_testing", "testing", "province")
  provs_non_0 <- loc_non_0(testing_timeseries_prov, "date_testing", "testing", "province")
  if (length(provs_negative) > 0) {
    cat(bgRed("Provinces reporting negative testing today:", paste(provs_negative, collapse = ", "), "\n"), fill = TRUE) 
  }
  cat(cyan("Provinces reporting 0 testing today:", paste(provs_0, collapse = ", "), "\n"), fill = TRUE)
  if (report_positive) {
    cat(green("Provinces reporting > 0 testing today:", paste0(provs_non_0, collapse = ", "), "\n"), fill = TRUE) 
  }
  
  ## vaccine distribution
  provs_negative <- loc_negative(vaccine_distribution_timeseries_prov, "date_vaccine_distributed", "dvaccine", "province")
  provs_0 <- loc_0(vaccine_distribution_timeseries_prov, "date_vaccine_distributed", "dvaccine", "province")
  provs_non_0 <- loc_non_0(vaccine_distribution_timeseries_prov, "date_vaccine_distributed", "dvaccine", "province")
  if (length(provs_negative) > 0) {
    cat(bgRed("Provinces reporting negative vaccine distribution today:", paste(provs_negative, collapse = ", "), "\n"), fill = TRUE) 
  }
  cat(cyan("Provinces reporting 0 vaccine distribution today:", paste(provs_0, collapse = ", "), "\n"), fill = TRUE)
  if (report_positive) {
    cat(green("Provinces reporting > 0 vaccine distribution today:", paste0(provs_non_0, collapse = ", "), "\n"), fill = TRUE) 
  }
  
  ## vaccine administration
  provs_negative <- loc_negative(vaccine_administration_timeseries_prov, "date_vaccine_administered", "avaccine", "province")
  provs_0 <- loc_0(vaccine_administration_timeseries_prov, "date_vaccine_administered", "avaccine", "province")
  provs_non_0 <- loc_non_0(vaccine_administration_timeseries_prov, "date_vaccine_administered", "avaccine", "province")
  if (length(provs_negative) > 0) {
    cat(bgRed("Provinces reporting negative vaccine administration today:", paste(provs_negative, collapse = ", "), "\n"), fill = TRUE) 
  }
  cat(cyan("Provinces reporting 0 vaccine administration today:", paste(provs_0, collapse = ", "), "\n"), fill = TRUE)
  if (report_positive) {
    cat(green("Provinces reporting > 0 vaccine administration today:", paste0(provs_non_0, collapse = ", "), "\n"), fill = TRUE) 
  }
  
  ## vaccine completion
  provs_negative <- loc_negative(vaccine_completion_timeseries_prov, "date_vaccine_completed", "cvaccine", "province")
  provs_0 <- loc_0(vaccine_completion_timeseries_prov, "date_vaccine_completed", "cvaccine", "province")
  provs_non_0 <- loc_non_0(vaccine_completion_timeseries_prov, "date_vaccine_completed", "cvaccine", "province")
  if (length(provs_negative) > 0) {
    cat(bgRed("Provinces reporting negative vaccine completion today:", paste(provs_negative, collapse = ", "), "\n"), fill = TRUE) 
  }
  cat(cyan("Provinces reporting 0 vaccine completion today:", paste(provs_0, collapse = ", "), "\n"), fill = TRUE)
  if (report_positive) {
    cat(green("Provinces reporting > 0 vaccine completion today:", paste0(provs_non_0, collapse = ", "), "\n"), fill = TRUE) 
  }
  
}