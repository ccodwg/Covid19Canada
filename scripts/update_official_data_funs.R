# Functions for: COVID-19 Canada Open Data Working Group Official Dataset Download and Compatibility Script #
# Author: Jean-Paul R. Soucy #

# import functions from update_data.R
source("scripts/update_data_funs.R")

# convert official Saskatchewan dataset: new health region boundaries
convert_official_sk_new_hr <- function() {
  
  ### download current SK dataset
  dat <- Covid19CanadaData::dl_current("61cfdd06-7749-4ae6-9975-d8b4f10d5651")
  
  ### convert data to CCODWG dataset format
  dat <- dat %>%
    ### convert date variable
    mutate(Date = as.Date(Date, "%Y/%m/%d")) %>%
    ### create province variable
    mutate(province = "Saskatchewan") %>%
    ### rename variables
    rename(
      date = Date,
      health_region = Region,
      cases = New.Cases,
      cumulative_cases = Total.Cases,
      active_cases = Active.Cases,
      hosp = Inpatient.Hospitalizations, # does not include icu
      icu = ICU.Hospitalizations,
      recovered = Recovered.Cases,
      cumulative_deaths = Deaths
    ) %>%
    ### merge subzone data into one line per health region
    ### see https://www.saskatchewan.ca/government/health-care-administration-and-provider-resources/treatment-procedures-and-guidelines/emerging-public-health-issues/2019-novel-coronavirus/cases-and-risk-of-covid-19-in-saskatchewan/index-of-communities
    group_by(date, province, health_region) %>%
    summarize(
      cases = sum(cases, na.rm = TRUE),
      across(c(cumulative_cases, active_cases, hosp,
               icu, recovered, cumulative_deaths),
             function(x) {
               ifelse(
                 all(is.na(x)), 0, max(x, na.rm = TRUE)
               )
             }),
      .groups = "drop"
    ) %>%
    ### arrange data
    arrange(province, health_region, date)
  
  ### create cases time series - health region
  cases_timeseries_hr <- dat %>%
    ### rename date variable
    rename(date_report = date) %>%
    ### select variables
    select(
      province, health_region, date_report,
      cases, cumulative_cases
    )
  
  ### create cases time series - provincial
  cases_timeseries_prov <- cases_timeseries_hr %>%
    select(-health_region) %>%
    group_by(province, date_report) %>%
    summarize(
      cases = sum(cases),
      cumulative_cases = sum(cumulative_cases),
      .groups = "drop"
    )
  
  ### create mortality time series - health region
  mortality_timeseries_hr <- dat %>%
    ### rename date variable
    rename(date_death_report = date) %>%
    ### calculate daily deaths
    group_by(province, health_region) %>%
    mutate(deaths = c(0, diff(cumulative_deaths))) %>% # 0 deaths occured on 2020-08-04 (first day of the time series)
    ungroup %>%
    ### select variables
    select(
      province, health_region, date_death_report,
      deaths, cumulative_deaths
    )
  
  ### create mortality time series - provincial
  mortality_timeseries_prov <- mortality_timeseries_hr %>%
    select(-health_region) %>%
    group_by(province, date_death_report) %>%
    summarize(
      deaths = sum(deaths),
      cumulative_deaths = sum(cumulative_deaths),
      .groups = "drop"
    )
  
  ### convert dates to non-standard date format for writing
  convert_dates("cases_timeseries_hr", "cases_timeseries_prov",
                "mortality_timeseries_hr", "mortality_timeseries_prov",
                date_format_out = "%d-%m-%Y")
  
  ### write generated files
  write.csv(cases_timeseries_hr, "official_datasets/sk/timeseries_hr/sk_new_cases_timeseries_hr.csv", row.names = FALSE)
  write.csv(cases_timeseries_prov, "official_datasets/sk/timeseries_prov/sk_new_cases_timeseries_prov.csv", row.names = FALSE)
  write.csv(mortality_timeseries_hr, "official_datasets/sk/timeseries_hr/sk_new_mortality_timeseries_hr.csv", row.names = FALSE)
  write.csv(mortality_timeseries_prov, "official_datasets/sk/timeseries_prov/sk_new_mortality_timeseries_prov.csv", row.names = FALSE)
}

# combine CCODWG dataset (before 2020-08-04) & official Saskatchewan dataset (new health region boundaries, 2020-08-04 and after)
combine_ccodwg_official_sk_new_hr <- function(stat = c("cases", "mortality"), loc = c("prov", "hr")) {
    
    ### check statistic
    match.arg(stat,
              choices = c("cases", "mortality"),
              several.ok = FALSE)
    
    ### check spatial scale
    match.arg(loc,
              choices = c("prov", "hr"),
              several.ok = FALSE)
    
    ### load CCODWG dataset
    switch(
      paste(stat, loc),
      "cases prov" = {path_ccodwg <- "timeseries_prov/cases_timeseries_prov.csv"},
      "cases hr" = {path_ccodwg <- "timeseries_hr/cases_timeseries_hr.csv"},
      "mortality prov" = {path_ccodwg <- "timeseries_prov/mortality_timeseries_prov.csv"},
      "mortality hr" = {path_ccodwg <- "timeseries_hr/mortality_timeseries_hr.csv"}
    )
    dat_ccodwg <- read.csv(path_ccodwg,
                           stringsAsFactors = FALSE)
    
    ### load SK official dataset (new health region boundaries)
    switch(
      paste(stat, loc),
      "cases prov" = {path_official <- "official_datasets/sk/timeseries_prov/sk_new_cases_timeseries_prov.csv"; var_date <- "date_report"},
      "cases hr" = {path_official <- "official_datasets/sk/timeseries_hr/sk_new_cases_timeseries_hr.csv"; var_date <- "date_report"},
      "mortality prov" = {path_official <- "official_datasets/sk/timeseries_prov/sk_new_mortality_timeseries_prov.csv"; var_date <- "date_death_report"},
      "mortality hr" = {path_official <- "official_datasets/sk/timeseries_hr/sk_new_mortality_timeseries_hr.csv"; var_date <- "date_death_report"}
    )
    dat_official <- read.csv(path_official,
                             stringsAsFactors = FALSE)
    
    ### convert dates to standard format for manipulation
    convert_dates("dat_ccodwg", "dat_official",
                  date_format_out = "%Y-%m-%d")
    
    ### get minimum date of official dataset
    date_official_min <- min(dat_official[, var_date])
    
    ### combine data
    dat_combined <- bind_rows(
      dat_ccodwg %>%
        filter(province != "Saskatchewan"),
      dat_official
    ) %>%
      ### dataset begins on first date of official dataset
      filter(!!sym(var_date) >= date_official_min)
    
    ### arrange data
    if (loc == "prov") {
      dat_combined <- dat_combined %>%
        arrange(province, !!sym(var_date))
    } else if (loc == "hr") {
      dat_combined <- dat_combined %>%
        arrange(province, health_region, !!sym(var_date))
    }
    
    ### convert dates to non-standard date format for writing
    convert_dates("dat_combined",
                  date_format_out = "%d-%m-%Y")
    
    ### write generated file
    out_name <- paste0("timeseries_hr_sk_new/sk_new_", stat, "_timeseries_", loc, "_combined.csv")
    write.csv(dat_combined, out_name, row.names = FALSE)
}

# convert official Saskatchewan dataset: old health region boundaries (no longer updated)
convert_official_sk_data_old_hr <- function() {
  
  ### download final SK dataset with old health region boundaries
  dat <- read.csv("https://drive.google.com/uc?id=1AZ4miZ8sqTs4QzsyaWQjhDAL_NdlljRf&authuser=2&export=download",
                  stringsAsFactors = FALSE)
  
  ### convert data to CCODWG dataset format
}