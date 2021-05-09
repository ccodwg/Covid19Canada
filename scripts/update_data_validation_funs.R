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
  cat("Vaccine administration today:", vaccine_administration_timeseries_canada %>% filter(date_vaccine_administered == update_date) %>% pull(avaccine), fill = TRUE)
  cat("Total vaccine administration:", vaccine_administration_timeseries_canada %>% filter(date_vaccine_administered == update_date) %>% pull(cumulative_avaccine), fill = TRUE)
  cat("Vaccine distribution today:", vaccine_distribution_timeseries_canada %>% filter(date_vaccine_distributed == update_date) %>% pull(dvaccine), fill = TRUE)
  cat("Total vaccine distribution:", vaccine_distribution_timeseries_canada %>% filter(date_vaccine_distributed == update_date) %>% pull(cumulative_dvaccine), fill = TRUE)
  cat("Vaccine completion today:", vaccine_completion_timeseries_canada %>% filter(date_vaccine_completed == update_date) %>% pull(cvaccine), fill = TRUE)
  cat("Total vaccine completion:", vaccine_completion_timeseries_canada %>% filter(date_vaccine_completed == update_date) %>% pull(cumulative_cvaccine), fill = TRUE)
}

# define functions for individual-level data

## check IDs
check_ids <- function(type) {
  
  cat("\nChecking IDs in", type, "data...", fill = TRUE)
  
  ### match argument
  match.arg(type, choices = c("cases", "mortality"))
  
  ### load data
  dat <- get(type)
  
  ## rename ID columns
  dat <- dat %>%
    {if (type == "cases") rename(., id = case_id) else if (type == "mortality") rename(., id = death_id)} %>%
    {if (type == "cases") rename(., province_id = provincial_case_id) else if (type == "mortality") rename(., province_id = province_death_id)}
  
  
  # check national IDs
  tab_national <- table(dat$id)
  if (max(tab_national) > 1) {
    cat(bgRed(paste0("Duplicate national IDs in ", type, ".csv: ",
                     paste(names(tab_national[tab_national > 1]), collapse = ", "))), sep = "", fill = TRUE)
  } else {
    cat(green(paste0("No duplicate national IDs are present in ", type, ".csv.")), fill = TRUE)
  }
  
  ## check provincial IDs within provinces
  ## ...
  
}


## check dates
check_dates <- function(type) {
  
  cat("\nChecking dates in", type, "data...", fill = TRUE)
  
  ### match argument
  match.arg(type, choices = c("cases", "mortality"), several.ok = FALSE)
  
  ### load data
  dat <- get(type)
  
  ## rename date columns
  dat <- dat %>%
    {if (type == "cases") rename(., date = date_report) else if (type == "mortality") rename(., date = date_death_report)} %>%
    {if (type == "cases") rename(., week = report_week) %>% mutate(., week = as.Date(week, "%d-%m-%Y")) else .}
  
  ## check there are no dates in the future
  bad_dates <- dat %>% filter(date > update_date) %>% pull(date) %>% unique
  if (length(bad_dates) == 0) {
    cat(green(paste0("No future dates are present in ", type, ".csv.")), fill = TRUE)
  } else {
    cat(bgRed(paste0("Future dates are present in ", type, ".csv: ",
                     paste(bad_dates, collapse = ", "))), sep = "", fill = TRUE)
  }
  
  ## check there are no mismatches between date and week
  ## ...
  
}

## check health region names in case and mortality data
check_hr <- function(type) {
  
  cat("\nChecking health region names in", type, "data...", fill = TRUE)
  
  ### match argument
  match.arg(type, choices = c("cases", "mortality"))
  
  ### load data
  dat <- get(type)
  
  ### check health regions
  bad_hr <- dat %>%
    select(health_region) %>%
    distinct %>%
    filter(!health_region %in% c(hr_map$health_region, "Not Reported"))
  
  ### report results
  if (nrow(bad_hr) == 0) {
    cat(green(paste0("All health region names in ", type, ".csv are valid.")), fill = TRUE)
  } else {
    ### report invalid health regions
    cat(bgRed(paste0("Invalid health region names in ", type, ".csv: ",
              paste(bad_hr[, "health_region"], collapse = ", "))), sep = "", fill = TRUE)
  }
  
}

## check sexes in case and mortality data
check_sexes <- function(type) {
  
  cat("\nChecking sexes in", type, "data...", fill = TRUE)
  
  ### match argument
  match.arg(type, choices = c("cases", "mortality"))
  
  ### load data
  if (type == "cases") {
    dat <- bind_rows(cases_2020, cases_2021_1, cases_2021_2)
  } else if (type == "mortality") {
    dat <- bind_rows(mortality_2020, mortality_2021)
  }
  
  ## check sexes
  new_sexes <- dat %>%
    filter(!sex %in% c("Male", "Female", "Not Reported", "Transgender")) %>%
    pull(sex) %>%
    unique
  if (length(new_sexes) == 0) {
    cat(green("No new sexes."), fill = TRUE)
  } else {
    ### report new ages
    cat(bgRed("New sexes:", paste(new_sexes, collapse = ", ")), fill = TRUE)
  }
  
}

## check ages in case and mortality data
check_ages <- function(type) {
  
  cat("\nChecking ages in", type, "data...", fill = TRUE)
  
  ### match argument
  match.arg(type, choices = c("cases", "mortality"))
  
  ### load data
  if (type == "cases") {
    dat <- bind_rows(cases_2020, cases_2021_1, cases_2021_2)
  } else if (type == "mortality") {
    dat <- bind_rows(mortality_2020, mortality_2021)
  }
  age_map <- get(paste0("age_map_", type))
  age_levels <- unique(age_map$age_display)
  
  ### transform age map=
  age_map <- setNames(age_map$age_display, age_map$age) # to pass to recode()
  
  ### transform case data
  dat <- dat %>%
    select(case_id, age) %>%
    mutate(
      age_map = factor(
        recode(age, !!!age_map),
        age_levels
      )
    )
  
  ### check for new ages
  if (sum(is.na(dat$age_map)) == 0) {
    cat(green("No new ages."), fill = TRUE)
  } else {
    ### report new ages
    cat(bgRed("New ages:", paste(unique(dat[is.na(dat$age_map), "age"]), collapse = ", ")), fill = TRUE)
  }
  
}

## call all individual-level data validation functions
check_individual_data <- function(type) {
  
  ### match argument
  match.arg(type, choices = c("cases", "mortality"))
  
  ## check IDs
  check_ids(type)
  
  ## check dates
  check_dates(type)
  
  ## check health region names
  check_hr(type)
  
  ## check sexes
  check_sexes(type)
  
  ## check ages
  check_ages(type)
  
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
report_zeros_negatives <- function(report_non_zero = FALSE, report_hr = FALSE) {
  
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
  if (report_non_zero) {
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
  if (report_non_zero) {
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
  if (report_non_zero) {
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
  if (report_non_zero) {
    cat(green("Provinces reporting > 0 testing today:", paste0(provs_non_0, collapse = ", "), "\n"), fill = TRUE) 
  }
  
}