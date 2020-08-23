# COVID-19 Canada Open Data Working Group Data Update Script #
# Author: Jean-Paul R. Soucy #

# Download and process updated COVID-19 Canada data files from Google Sheets
# Spreadsheet link: https://docs.google.com/spreadsheets/u/1/d/1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo

# Note: This script assumes the working directory is set to the root directory of the project
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# load libraries
library(dplyr) # data manipulation
library(tidyr) # data manipulation

# read update time from public recovered sheet
update_time <- read.csv("https://docs.google.com/spreadsheets/u/1/d/1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo/export?format=csv&id=1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo&gid=2036294689",
                        header = FALSE, stringsAsFactors = FALSE)[1, 1] %>%
  sub("Last update: ", "", .) %>%
  {paste0(as.Date(sub(",*$", "", .), "%d %B %Y"), sub(".*,", "", .))}

# download files from public sheets and process
cases <- read.csv("https://docs.google.com/spreadsheets/u/1/d/1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo/export?format=csv&id=1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo&gid=942958991",
                  header = TRUE,
                  stringsAsFactors = FALSE,
                  skip = 3)
mortality <- read.csv("https://docs.google.com/spreadsheets/u/0/d/1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo/export?format=csv&id=1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo&gid=823945927",
                      header = TRUE,
                      stringsAsFactors = FALSE,
                      skip = 3)
recovered_cum <- read.csv("https://docs.google.com/spreadsheets/u/1/d/1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo/export?format=csv&id=1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo&gid=2036294689",
                          header = TRUE,
                          stringsAsFactors = FALSE,
                          skip = 3)[, 1:3]
testing_cum <- read.csv("https://docs.google.com/spreadsheets/u/1/d/1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo/export?format=csv&id=1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo&gid=2106589546",
                        header = TRUE,
                        stringsAsFactors = FALSE,
                        skip = 3)[, 1:4]
codebook <- read.csv("https://docs.google.com/spreadsheets/u/1/d/1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo/export?format=csv&id=1D6okqtBS3S2NRC7GFVHzaZ67DuTw7LX49-fqSLwJyeo&gid=0",
                     header = TRUE,
                     stringsAsFactors = FALSE,
                     skip = 2)

# write files and update time
write.csv(cases, "cases.csv", row.names = FALSE)
write.csv(mortality, "mortality.csv", row.names = FALSE)
write.csv(recovered_cum, "recovered_cumulative.csv", row.names = FALSE)
write.csv(testing_cum, "testing_cumulative.csv", row.names = FALSE)
write.csv(codebook, "codebook.csv", row.names = FALSE)
cat(paste0(update_time, "\n"), file = "update_time.txt")

# create time series of cases

## define provinces (alphabetical order)
provinces_repatriated <- c("Alberta", "BC", "Manitoba", "New Brunswick", "NL", "Nova Scotia", "Nunavut", "NWT", "Ontario", "PEI", "Repatriated", "Quebec", "Saskatchewan", "Yukon")
provinces <- c("Alberta", "BC", "Manitoba", "New Brunswick", "NL", "Nova Scotia", "Nunavut", "NWT", "Ontario", "PEI", "Quebec", "Saskatchewan", "Yukon")

## convert cases to standard date format for data manipulation
cases <- cases %>%
  mutate(date_report = as.Date(date_report, "%d-%m-%Y"))

## define min and max dates
min_date_cases <- min(cases$date_report, na.rm = TRUE)
max_date_cases <- max(cases$date_report, na.rm = TRUE)

## create time series by province
cases_ts <- cases %>%
  group_by(province, date_report) %>%
  summarise(cases = n(), .groups = "drop_last") %>%
  right_join(
    data.frame(
      "province" = rep(provinces_repatriated, each = as.integer(max_date_cases - min_date_cases) + 1),
      "date_report" = seq.Date(from = min_date_cases, to = max_date_cases, by = "day"),
      stringsAsFactors = FALSE
    ), by = c("province", "date_report")) %>%
  arrange(province, date_report) %>%
  replace_na(list(cases = 0)) %>%
  mutate(cumulative_cases = cumsum(cases)) %>%
  ### return to non-standard date format for saving
  mutate(
    date_report = format(date_report, "%d-%m-%Y")
  )

## create time series by health region
cases_ts_hr <- cases %>%
  group_by(province, health_region, date_report) %>%
  summarise(cases = n(), .groups = "drop_last") %>%
  right_join(
    data.frame(
      slice({
        distinct(select(., province, health_region))
      }, rep(1:n(), each = length(seq.Date(from = min_date_cases, to = max_date_cases, by = "day")))),
      date_report = seq.Date(from = min_date_cases, to = max_date_cases, by = "day"),
      stringsAsFactors = FALSE
    ), by = c("province", "health_region", "date_report")) %>%
  arrange(province, health_region, date_report) %>%
  replace_na(list(cases = 0)) %>%
  mutate(cumulative_cases = cumsum(cases)) %>%
  ### return to non-standard date format for saving
  mutate(
    date_report = format(date_report, "%d-%m-%Y")
  )

# create time series of mortality

## convert mortality to standard date format
mortality <- mortality %>%
  mutate(date_death_report = as.Date(date_death_report, "%d-%m-%Y"))

## define min and max dates
min_date_mortality <- min(mortality$date_death_report, na.rm = TRUE)
max_date_mortality <- max(mortality$date_death_report, na.rm = TRUE)

## create time series by province
mortality_ts <- mortality %>%
  group_by(province, date_death_report) %>%
  summarise(deaths = n(), .groups = "drop_last") %>%
  right_join(
    data.frame(
      "province" = rep(provinces, each = as.integer(max_date_mortality - min_date_mortality) + 1),
      "date_death_report" = seq.Date(from = min_date_mortality, to = max_date_mortality, by = "day"),
      stringsAsFactors = FALSE
    ), by = c("province", "date_death_report")) %>%
  arrange(province, date_death_report) %>%
  replace_na(list(deaths = 0)) %>%
  mutate(cumulative_deaths = cumsum(deaths)) %>%
  ### return to non-standard date format for saving
  mutate(
    date_death_report = format(date_death_report, "%d-%m-%Y")
  )

## create time series by health region
mortality_ts_hr <- mortality %>%
  group_by(province, health_region, date_death_report) %>%
  summarise(deaths = n(), .groups = "drop_last") %>%
  right_join(
    data.frame(
      slice({
        distinct(select(., province, health_region))
      }, rep(1:n(), each = length(seq.Date(from = min_date_mortality, to = max_date_mortality, by = "day")))),
      date_death_report = seq.Date(from = min_date_mortality, to = max_date_mortality, by = "day"),
      stringsAsFactors = FALSE
    ), by = c("province", "health_region", "date_death_report")) %>%
  arrange(province, health_region, date_death_report) %>%
  replace_na(list(deaths = 0)) %>%
  mutate(cumulative_deaths = cumsum(deaths)) %>%
  ### return to non-standard date format for saving
  mutate(
    date_death_report = format(date_death_report, "%d-%m-%Y")
  )

# create full time series of recovered

## convert recovered to standard date format
recovered_cum <- recovered_cum %>%
  mutate(date_recovered = as.Date(date_recovered, "%d-%m-%Y"))

## define min and max dates
min_date_recovered <- min(recovered_cum$date_recovered, na.rm = TRUE)
max_date_recovered <- max(recovered_cum$date_recovered, na.rm = TRUE)

## create time series by province
recovered_ts <- recovered_cum %>%
  group_by(province, date_recovered) %>%
  right_join(
    data.frame(
      "province" = rep(c(provinces, "Repatriated"), each = as.integer(max_date_recovered - min_date_recovered) + 1),
      "date_recovered" = seq.Date(from = min_date_recovered, to = max_date_recovered, by = "day"),
      stringsAsFactors = FALSE
    ), by = c("province", "date_recovered")) %>%
  arrange(province, date_recovered) %>%
  replace_na(list(cumulative_recovered = 0)) %>%
  ### calculate daily number of tests
  group_by(province) %>%
  mutate(
    recovered = c(cumulative_recovered[1], diff(cumulative_recovered))
  ) %>%
  select(province, date_recovered, recovered, cumulative_recovered) %>%
  ### return to non-standard date format for saving
  mutate(
    date_recovered = format(date_recovered, "%d-%m-%Y")
  )

# create full time series of testing

## convert testing to standard date format
testing_cum <- testing_cum %>%
  mutate(date_testing = as.Date(date_testing, "%d-%m-%Y"))

## define min and max dates
min_date_testing <- min(testing_cum$date_testing, na.rm = TRUE)
max_date_testing <- max(testing_cum$date_testing, na.rm = TRUE)

## create time series by province
testing_ts <- testing_cum %>%
  group_by(province, date_testing) %>%
  right_join(
    data.frame(
      "province" = rep(provinces, each = as.integer(max_date_testing - min_date_testing) + 1),
      "date_testing" = seq.Date(from = min_date_testing, to = max_date_testing, by = "day"),
      stringsAsFactors = FALSE
    ), by = c("province", "date_testing")) %>%
  arrange(province, date_testing) %>%
  replace_na(list(cumulative_testing = 0)) %>%
  ### calculate daily number of tests
  group_by(province) %>%
  mutate(
    testing = c(cumulative_testing[1], diff(cumulative_testing))
  ) %>%
  select(province, date_testing, testing, cumulative_testing, testing_info) %>%
  ### return to non-standard date format for saving
  mutate(
    date_testing = format(date_testing, "%d-%m-%Y")
  )

# create time series of active cases

## join cases and recovered
active_ts <- left_join(
  cases_ts %>% rename(date = date_report) %>% select(-cases),
  recovered_ts %>% rename(date = date_recovered) %>% select(-recovered),
  by = c("province", "date")
) %>%
  left_join(
    mortality_ts %>% rename(date = date_death_report) %>% select(-deaths),
    by = c("province", "date")
  ) %>%
  ## replace recovered = NA with 0
  replace_na(list(cumulative_recovered = 0, cumulative_deaths = 0)) %>%
  ## calculate active cases
  mutate(active_cases = cumulative_cases - cumulative_recovered - cumulative_deaths) %>%
  group_by(province) %>%
  mutate(active_cases_change = c(active_cases[1], diff(active_cases))) %>%
  rename(
    date_active = date
  )

# create time series for all of Canada combined

## cases
cases_ts_canada <- cases_ts %>%
  ungroup %>%
  mutate(province = "Canada") %>%
  group_by(province, date_report) %>%
  summarise_all(sum) %>%
  ### keep original order
  arrange(match(date_report, cases_ts$date_report))

## mortality
mortality_ts_canada <- mortality_ts %>%
  ungroup %>%
  mutate(province = "Canada") %>%
  group_by(province, date_death_report) %>%
  summarise_all(sum) %>%
  ### keep original order
  arrange(match(date_death_report, mortality_ts$date_death_report))

## recovered
recovered_ts_canada <- recovered_ts %>%
  ungroup %>%
  mutate(province = "Canada") %>%
  group_by(province, date_recovered) %>%
  summarise_all(sum) %>%
  ### keep original order
  arrange(match(date_recovered, recovered_ts$date_recovered))

## testing
testing_ts_canada <- testing_ts %>%
  ungroup %>%
  mutate(province = "Canada") %>%
  group_by(province, date_testing) %>%
  ### if there is any testing info for any province on a particular day, it will be flagged
  summarise(testing = sum(testing), cumulative_testing = sum(cumulative_testing), testing_info = paste0(unique(testing_info)), .groups = "keep") %>%
  arrange(date_testing, testing_info) %>%
  slice_tail(n = 1) %>%
  ### keep original order
  arrange(match(date_testing, testing_ts$date_testing))

## active cases
active_ts_canada <- active_ts %>%
  ungroup %>%
  mutate(province = "Canada") %>%
  group_by(province, date_active) %>%
  summarise_all(sum) %>%
  ### keep original order
  arrange(match(date_active, active_ts$date_active))

# write generated files
write.csv(cases_ts, "timeseries_prov/cases_timeseries_prov.csv", row.names = FALSE)
write.csv(cases_ts_hr, "timeseries_hr/cases_timeseries_hr.csv", row.names = FALSE)
write.csv(cases_ts_canada, "timeseries_canada/cases_timeseries_canada.csv", row.names = FALSE)
write.csv(mortality_ts, "timeseries_prov/mortality_timeseries_prov.csv", row.names = FALSE)
write.csv(mortality_ts_hr, "timeseries_hr/mortality_timeseries_hr.csv", row.names = FALSE)
write.csv(mortality_ts_canada, "timeseries_canada/mortality_timeseries_canada.csv", row.names = FALSE)
write.csv(recovered_ts, "timeseries_prov/recovered_timeseries_prov.csv", row.names = FALSE)
write.csv(recovered_ts_canada, "timeseries_canada/recovered_timeseries_canada.csv", row.names = FALSE)
write.csv(testing_ts, "timeseries_prov/testing_timeseries_prov.csv", row.names = FALSE)
write.csv(testing_ts_canada, "timeseries_canada/testing_timeseries_canada.csv", row.names = FALSE)
write.csv(active_ts, "timeseries_prov/active_timeseries_prov.csv", row.names = FALSE)
write.csv(active_ts_canada, "timeseries_canada/active_timeseries_canada.csv", row.names = FALSE)