# Functions for: COVID-19 Canada Open Data Working Group Data Update Validation Script #
# Author: Jean-Paul R. Soucy #

## FUNCTIONS FOR LOADING DATA ##

# define data directories
data_dirs <- "timeseries_canada|timeseries_prov|timeseries_hr|timeseries_hr_sk_new|official_datasets"

# download current data from GitHub repository
download_current_data <- function() {
  
  # download current data from GitHub
  tempd <- file.path(tempdir(), "Covid19Canada")
  if (dir.exists(tempd)) {
    unlink(tempd, recursive = TRUE)
  }
  system2(
    command = "git",
    args = c(
      "clone",
      "--quiet",
      "--depth=1",
      "https://github.com/ccodwg/Covid19Canada.git",
      tempd)
  )
  
  # load files from specified directories
  old_files <- list.files(
    path = tempd,
    pattern = data_dirs,
    full.names = TRUE,
    recursive = TRUE)
  invisible(list2env(
    lapply(setNames(old_files, make.names(paste0("old_", sub(".csv", "", basename(old_files))))), 
           function(x) {
             read.csv(x, stringsAsFactors = FALSE) %>%
               mutate(across(matches("^date_|_week$"), as.Date, format = "%d-%m-%Y"))}),
    envir = globalenv()))
  
  # load update time
  assign("old_update_time", readLines(paste(tempd, "update_time.txt", sep = "/")),
         envir = globalenv())
  
  # clean up
  unlink(tempd, recursive = TRUE)
  
}

# load new data from local drive
load_new_data <- function() {
 
  # load files from specified directories
  new_files <- list.files(path = ".", pattern = data_dirs, full.names = TRUE, recursive = TRUE)
  invisible(list2env(
    lapply(setNames(new_files, make.names(sub(".csv", "", basename(new_files)))), 
           function(x) {
             read.csv(x, stringsAsFactors = FALSE) %>%
               mutate(across(matches("^date_|_week$"), as.Date, format = "%d-%m-%Y"))}),
    envir = globalenv()))
  
  # load update time
  update_time <- readLines("update_time.txt")
  assign("update_time", update_time, envir = globalenv())
  assign("update_date", as.Date(update_time), envir = globalenv())
   
}

## FUNCTIONS FOR SUMMARIZING DATA ##

# define data types
types <- c("cases", "mortality", "recovered", "testing", "vaccine_distribution", "vaccine_administration", "vaccine_completion", "vaccine_additionaldoses")
types_vals <- c("cases", "deaths", "recovered", "testing", "dvaccine", "avaccine", "cvaccine", "additionaldosesvaccine")
types_names <- c("Cases", "Deaths", "Recovered", "Testing", "Vaccine distribution", "Vaccine administration", "Vaccine completion", "Vaccine additional doses")
types_names_short <- c("Cases", "Deaths", "Recovered", "Testing", "Vax doses dist.", "Vax doses tot.", "Vax doses 2", "Vax doses add.")
types_hr <- c("cases", "mortality")

# summarize Canada-wide daily and cumulative numbers
summary_today_overall <- function() {
  # print update times
  cat("Old data:", old_update_time, fill = TRUE)
  cat("New data:", update_time, fill = TRUE)
  # create empty summary table
  results <- data.frame(
    type = types_names_short,
    daily = "",
    comp_avg_7_day = "",
    avg_7_day = "",
    cumulative = ""
  )
  for (i in 1:length(types)) {
    # get values
    df <- get(paste0(types[i], "_timeseries_canada"))
    date_col <- grep("^date_", names(df), value = TRUE)
    val_col <- types_vals[i]
    val_cum_col <- paste0("cumulative_", val_col)
    df <- df %>%
      # get last 7 days of data
      filter(!!sym(date_col) >= update_date - 6 & !!sym(date_col) <= update_date) %>%
      transmute(date = !!sym(date_col), value_daily = !!sym(val_col), value_cumulative = !!sym(val_cum_col))
    # calculate values
    daily_today <- df %>% filter(date == update_date) %>% pull(value_daily)
    cumulative_today <- df %>% filter(date == update_date) %>% pull(value_cumulative)
    daily_7day <- df %>% pull(value_daily) %>% mean()
    comp_to_7day <- round((daily_today - daily_7day) / daily_7day * 100, 0)
    
    # fill in summary table
    results[i, "daily"] <- format(daily_today, big.mark = ",", scientific = FALSE)
    results[i, "comp_avg_7_day"] <- paste0(formatC(round(comp_to_7day, 0), big.mark = ",", format = "d", flag = "+"), "%")
    results[i, "avg_7_day"] <- format(round(daily_7day, 0), big.mark = ",", scientific = FALSE)
    results[i, "cumulative"] <- format(cumulative_today, big.mark = ",", scientific = FALSE)
  }
  # print summary table
  pander::pander(
    results,
    style = "simple",
    justify = "lrrrr",
    missing = "MISSING",
    col.names = c("Metric", "Today", "% change", "7-day", "Total"))
}

# summarize provincial daily numbers by metric
summary_today_by_metric <- function() {
  
  for (i in 1:length(types)) {
    # get values
    df <- get(paste0(types[i], "_timeseries_prov"))
    date_col <- grep("^date_", names(df), value = TRUE)
    val_col <- types_vals[i]
    results <- df %>%
      # filter to most recent day
      filter(!!sym(date_col) == update_date) %>%
      # select province name and metric value
      transmute(province, value_daily = !!sym(val_col)) %>%
      # arrange by descending order of value
      arrange(desc(value_daily))
    # print summary
    pander::pander(
      results,
      style = "simple",
      big.mark = ",",
      justify = "lr",
      missing = "MISSING",
      col.names = c(types_names_short[i], "Value"))
  }
}

# check time series
ts_check <- function(loc = c("prov", "hr")) {
  
  # match args
  match.arg(loc, choices = c("prov", "hr"), several.ok = FALSE)
  
  # announce changes
  if (loc == "prov") {
    changes <- "\nChanges to provincial time series...\n"
  } else {
    changes <- "\nChanges to health region time series...\n"
  }
  
  # init report
  report <- changes
  
  # determine data types
  if (loc == "prov") {
    ts_types <- types
  } else {
    ts_types <- types_hr
  }
  
  # loop through data types
  for (type in ts_types) {
    
    # diff data
    old_file <- paste0("old_", type, "_timeseries_", loc)
    new_file <- paste0(type, "_timeseries_", loc)
    var_names <- names(get(new_file))
    date_var <- var_names[grepl("date", var_names)]
    diff <- suppressMessages(compare_df(get(new_file), get(old_file), date_var))$comparison_df
    if (loc == "hr") {
      hr_list <- distinct(select(diff, province, health_region)) # list health regions
    }
    
    # loop through provinces
    for (prov in unique(get(new_file)$province)) {
      # calculate differences
      diff_prov <- diff %>%
        filter(province == prov)
      if (loc == "prov") {
        # report differences
        if (nrow(filter(diff_prov, !!sym(date_var) == update_date & chng_type == "+")) == 0) {
          r <- bgRed(paste0(prov, " ", type, ": no update today?"))
          report <- paste(report, r, sep = "\n")
        } else if (nrow(diff_prov) == 1 & nrow(filter(diff_prov, !(!!sym(date_var) == update_date & chng_type == "+"))) == 0) {
          # don't report successes
        } else {
          diff_prov <- filter(diff_prov, !(!!sym(date_var) == update_date & chng_type == "+"))
          r <- bgBlue(paste0(prov, " ", type, ": regular update and historical modifications (", paste(unique(pull(diff_prov, date_var)), collapse = ", "), ")"))
          report <- paste(report, r, sep = "\n")
        }
      } else {
        # loop through health regions
        for (hr in hr_list %>% filter(province == prov) %>% pull(health_region)) {
          # report differences
          diff_hr <- diff_prov %>%
            filter(health_region == hr)
          if (nrow(filter(diff_hr, !!sym(date_var) == update_date & chng_type == "+")) == 0) {
            r <- bgRed(paste0(hr, " (", prov, ") ", type, ": no update today?"))
            report <- paste(report, r, sep = "\n")
          } else if (nrow(diff_hr) == 1 & nrow(filter(diff_hr, !(!!sym(date_var) == update_date & chng_type == "+"))) == 0) {
            # don't report successes
          } else {
            diff_hr <- filter(diff_hr, !(!!sym(date_var) == update_date & chng_type == "+"))
            r <- bgBlue(paste0(hr, " (", prov, ") ", type, ": regular update and historical modifications (", paste(unique(pull(diff_hr, date_var)), collapse = ", "), ")"))
            report <- paste(report, r, sep = "\n")
          }
        }
      }
    }
  }
  # print nothing if no differences were found
  if (!identical(report, changes)) {
    cat(report, fill = TRUE)
    }
}
