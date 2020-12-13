# Functions for: COVID-19 Canada Open Data Working Group Official Dataset Download and Compatibility Script #
# Author: Jean-Paul R. Soucy #

# import functions from update_data.R
source("scripts/update_data_funs.R")

# convert official Saskatchewan dataset: new health region boundaries
convert_official_sk_new_hr <- function() {
  ### grab URL for newest SK case dataset
  sk_cases_url <- paste0("https://dashboard.saskatchewan.ca", read_html("https://dashboard.saskatchewan.ca/health-wellness/covid-19/cases") %>% html_node("body") %>% as.character %>% str_extract("(?<=href=\").*(?=\">CSV)"))
  
  ### download current SK dataset
  dat <- read.csv(sk_cases_url,
                  stringsAsFactors = FALSE)
  
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
    ### arrange data
    arrange(province, health_region, date) %>%
    ### fix NAs in cumulative_cases
    fill(cumulative_cases, .direction = "up")
  
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
  write.csv(cases_timeseries_hr, "official_datasets/sk/sk_new_hr_cases_timeseries_hr.csv", row.names = FALSE)
  write.csv(cases_timeseries_prov, "official_datasets/sk/sk_new_hr_cases_timeseries_prov.csv", row.names = FALSE)
  write.csv(mortality_timeseries_hr, "official_datasets/sk/sk_new_hr_mortality_timeseries_hr.csv", row.names = FALSE)
  write.csv(mortality_timeseries_prov, "official_datasets/sk/sk_new_hr_mortality_timeseries_prov.csv", row.names = FALSE)
}

# official Saskatchewan dataset: old health region boundaries (no longer updated)
convert_official_sk_data_old_hr <- function() {
  
  ### download final SK dataset with old health region boundaries
  dat <- read.csv("https://drive.google.com/uc?id=1AZ4miZ8sqTs4QzsyaWQjhDAL_NdlljRf&authuser=2&export=download",
                  stringsAsFactors = FALSE)
  
  ### convert data to CCODWG dataset format
}