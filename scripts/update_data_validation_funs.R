# Functions for: COVID-19 Canada Open Data Working Group Data Update Validation Script #
# Author: Jean-Paul R. Soucy #

## FUNCTIONS FOR LOADING DATA ##

# define data directories
data_dirs <- "timeseries_canada|timeseries_prov|timeseries_hr|timeseries_hr_sk_new|official_datasets"

# download current data from GitHub repository
download_current_data <- function() {
  
  # download current data from GitHub
  temp <- tempfile()
  tempd <- tempdir()
  download.file("https://github.com/ccodwg/Covid19Canada/archive/master.zip", temp, mode = "wb")
  unzip(temp, exdir = tempd)
  
  # load files from specified directories
  old_files <- list.files(
    path = tempd,
    pattern = data_dirs,
    full.names = TRUE,
    recursive = TRUE)
  invisible(list2env(
    lapply(setNames(old_files, make.names(paste0("old_", sub(".csv", "", basename(old_files))))), 
           read.csv, stringsAsFactors = FALSE), envir = .GlobalEnv))
  
  # load update time
  assign("old_update_time", readLines(paste(tempd, "Covid19Canada-master", "update_time.txt", sep = "/")),
         envir = .GlobalEnv)
  
  # clean up
  unlink(temp)
  unlink(paste(tempd, "Covid19Canada-master", sep = "/"), recursive = TRUE)
  
}

# load new data from local drive
load_new_data <- function() {
 
  # load files from specified directories
  new_files <- list.files(path = ".", pattern = data_dirs, full.names = TRUE, recursive = TRUE)
  invisible(list2env(
    lapply(setNames(new_files, make.names(sub(".csv", "", basename(new_files)))), 
           read.csv, stringsAsFactors = FALSE), envir = .GlobalEnv))
  
  # load update time
  assign("update_time", readLines("update_time.txt"), envir = .GlobalEnv)
  assign("update_date", as.Date(update_time), envir = .GlobalEnv)
   
}

# convert all dates to ISO 8601
convert_dates <- function() {
  for (df in names(which(unlist(eapply(.GlobalEnv, is.data.frame))))) {
    assign(df, get(df) %>%
             mutate(
               across(starts_with("date_"), as.Date, format = "%d-%m-%Y")),
           envir = .GlobalEnv)}
}

## FUNCTIONS FOR SUMMARIZING DATA ##

# define data types
types <- c("cases", "mortality", "recovered", "testing", "vaccine_distribution", "vaccine_administration", "vaccine_completion", "vaccine_additionaldoses")
types_vals <- c("cases", "deaths", "recovered", "testing", "dvaccine", "avaccine", "cvaccine", "additionaldosesvaccine")
types_names <- c("Cases", "Deaths", "Recovered", "Testing", "Vaccine distribution", "Vaccine administration", "Vaccine completion", "Vaccine additional doses")
types_hr <- c("cases", "mortality")

# summarize Canada-wide daily and cumulative numbers
summary_today_overall <- function() {
  
  cat("Old data:", old_update_time, fill = TRUE)
  cat("New data:", update_time, "\n", fill = TRUE)
  for (i in 1:length(types)) {
    # get values
    df <- get(ls(pattern = paste0("^", types[i], "_timeseries_canada"), name = ".GlobalEnv"))
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
    # print summary
    cat(types_names[i], ": ",
        format(daily_today, big.mark = ",", scientific = FALSE),
        " (today) / ",
        formatC(comp_to_7day, big.mark = ",", digits = 0, format = "d", flag = "+"),
        "% compared to 7-day average (",
        format(daily_7day, big.mark = ",", digits = 0, scientific = FALSE),
        ") / ",
        format(cumulative_today, big.mark = ",", scientific = FALSE),
        " (cumulative)",
        sep = "", fill = TRUE)
  }
  cat("\n", fill = TRUE) # blank line
}

# summarize provincial daily numbers by metric
summary_today_by_metric <- function() {
  
  for (i in 1:length(types)) {
    # print metric name
    cat(types_names[i], "...\n", sep = "", fill = TRUE)
    # get values
    df <- get(ls(pattern = paste0("^", types[i], "_timeseries_prov"), name = ".GlobalEnv"))
    date_col <- grep("^date_", names(df), value = TRUE)
    val_col <- types_vals[i]
    df <- df %>%
      # filter to most recent day
      filter(!!sym(date_col) == update_date) %>%
      # select province name and metric value
      transmute(province, value_daily = !!sym(val_col)) %>%
      # arrange by descending order of value
      arrange(desc(value_daily)) %>%
      # format values
      mutate(value_daily = format(value_daily, big.mark = ","))
    # print summary
    print(df, row.names = FALSE)
    cat("\n", fill = TRUE) # blank line
  }
}

# provincial data
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

# health region data
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