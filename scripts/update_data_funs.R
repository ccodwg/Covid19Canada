# Functions for: COVID-19 Canada Open Data Working Group Data Update Script #
# Author: Jean-Paul R. Soucy #

# define data downloading functions

## quickly load Google Sheets data
sheets_load <- function(files, file, sheet = NULL) {
  id <- files %>%
    filter(name == file) %>%
    pull(id)
  if (!is.null(sheet)) {
    read_sheet(
      ss = id,
      sheet = sheet,
      col_types = "c" # don't mangle dates
    )
  } else {
    read_sheet(
      ss = id,
      col_types = "c" # don't mangle dates
    )
  }
}

# define functions for time series data

## create time series (cases, mortality, recovered, testing)
create_ts <- function(dat,
                      stat = c("cases", "mortality", "recovered", "testing", "vaccine_administration", "vaccine_distribution", "vaccine_completion", "vaccine_additionaldoses"),
                      loc = c("canada", "prov", "hr"),
                      date_min) {
  
  
  ### check statistic
  match.arg(stat,
            choices = c("cases", "mortality", "recovered", "testing", "vaccine_administration", "vaccine_distribution", "vaccine_completion", "vaccine_additionaldoses"),
            several.ok = FALSE)
  
  ### check spatial scale
  match.arg(loc,
            choices = c("canada", "prov", "hr"),
            several.ok = FALSE)
  
  ### define variable names based on stat
  switch(
    stat,
    "cases" = {var_date <- "date_report"; var_val <- "cases"; var_val_cum <- "cumulative_cases"},
    "mortality" = {var_date <- "date_death_report"; var_val <- "deaths"; var_val_cum <- "cumulative_deaths"},
    "recovered" = {var_date <- "date_recovered"; var_val <- "recovered"; var_val_cum <- "cumulative_recovered"},
    "testing" = {var_date <- "date_testing"; var_val <- "testing"; var_val_cum <- "cumulative_testing"},
    "vaccine_administration" = {var_date <- "date_vaccine_administered"; var_val <- "avaccine"; var_val_cum <- "cumulative_avaccine"},
    "vaccine_distribution" = {var_date <- "date_vaccine_distributed"; var_val <- "dvaccine"; var_val_cum <- "cumulative_dvaccine"},
    "vaccine_completion" = {var_date <- "date_vaccine_completed"; var_val <- "cvaccine"; var_val_cum <- "cumulative_cvaccine"},
    "vaccine_additionaldoses" = {var_date <- "date_vaccine_additionaldoses"; var_val <- "additionaldosesvaccine"; var_val_cum <- "cumulative_additionaldosesvaccine"}
  )
  
  ### build time series
  if (stat %in% c("cases", "mortality")) {
    ### build health region time series as baseline
    dat <- dat %>%
      select(province, health_region, !!sym(var_date), !!sym(var_val_cum)) %>%
      arrange(province, health_region, !!sym(var_date)) %>%
      group_by(province, health_region, !!sym(var_date)) %>%
      replace_na(
        as.list(setNames(0, var_val_cum))
      ) %>%
      summarize(
        !!sym(var_val_cum) := sum(!!sym(var_val_cum)),
        .groups = "drop_last"
      ) %>%
      right_join(
        tibble(
          province = map_hr %>% select(province) %>% pull %>% rep(each = length(seq.Date(from = date_min, to = update_date, by = "day"))),
          health_region = map_hr %>% select(health_region) %>% pull %>% rep(each = length(seq.Date(from = date_min, to = update_date, by = "day"))),
          !!var_date := seq.Date(from = date_min, to = update_date, by = "day") %>% rep(times = nrow(map_hr)),
        ),
        by = c("province", "health_region", var_date)
      ) %>%
      arrange(province, health_region, !!sym(var_date)) %>%
      mutate(
        !!sym(var_val) := !!sym(var_val_cum) - lag(!!sym(var_val_cum), n = 1, default = 0)
      ) %>%
      ungroup
    if (loc == "hr") {
      ### health region time series
      return(
        dat %>%
          select(province, health_region, !!sym(var_date), !!sym(var_val), !!sym(var_val_cum))
      )
    } else if (loc == "prov") {
      ### provincial time series
      return(
        dat %>%
          select(province, !!sym(var_date), !!sym(var_val), !!sym(var_val_cum)) %>%
          group_by(province, !!sym(var_date)) %>%
          summarize(
            !!sym(var_val) := sum(!!sym(var_val)),
            !!sym(var_val_cum) := sum(!!sym(var_val_cum)),
            .groups = "drop"
            )
      )
    } else if (loc == "canada") {
      ### Canadian time series
      return(
        dat %>%
          select(province, !!sym(var_date), !!sym(var_val), !!sym(var_val_cum)) %>%
          mutate(province = "Canada") %>%
          group_by(province, !!sym(var_date)) %>%
          summarize(
            !!sym(var_val) := sum(!!sym(var_val)),
            !!sym(var_val_cum) := sum(!!sym(var_val_cum)),
            .groups = "drop"
          )
      )
    }
  } else if (stat %in% c("recovered", "testing", "vaccine_administration", "vaccine_distribution", "vaccine_completion", "vaccine_additionaldoses")) {
    ### build provincial time series as baseline
    dat <- dat %>%
      select(province, !!sym(var_date), !!sym(var_val_cum)) %>%
      arrange(province, !!sym(var_date)) %>%
      group_by(province, !!sym(var_date)) %>%
      replace_na(
        as.list(setNames(0, var_val_cum))
      ) %>%
      summarize(
        !!sym(var_val_cum) := sum(!!sym(var_val_cum)),
        .groups = "drop_last"
      ) %>%
      right_join(
        tibble(
          province = map_prov %>% select(province) %>% pull %>% rep(each = length(seq.Date(from = date_min, to = update_date, by = "day"))),
          !!var_date := seq.Date(from = date_min, to = update_date, by = "day") %>% rep(times = nrow(map_prov)),
        ),
        by = c("province", var_date)
      ) %>%
      arrange(province, !!sym(var_date)) %>%
      mutate(
        !!sym(var_val) := !!sym(var_val_cum) - lag(!!sym(var_val_cum), n = 1, default = 0)
      ) %>%
      ungroup
    ### remove "Repatriated"
    if (stat %in%  c("vaccine_administration", "vaccine_distribution", "vaccine_completion", "vaccine_additionaldoses")) {
      dat <- dat %>%
        filter(province != "Repatriated")
    }
    if (loc == "hr") {
      ### health region time series
      stop("Recovered/testing/vaccine health region time series not currently supported.")
    } else if (loc == "prov") {
      return(
        dat %>%
          select(province, !!sym(var_date), !!sym(var_val), !!sym(var_val_cum))
        )
    } else if (loc == "canada") {
      ### Canadian time series
      return(
        dat %>%
          select(province, !!sym(var_date), !!sym(var_val), !!sym(var_val_cum)) %>%
          mutate(province = "Canada") %>%
          group_by(province, !!sym(var_date)) %>%
          summarize(
            !!sym(var_val) := sum(!!sym(var_val)),
            !!sym(var_val_cum) := sum(!!sym(var_val_cum)),
            .groups = "drop"
            )
      )
    }
  }
}

## create time series (active cases)
create_ts_active <- function(dat_cases, dat_recovered, dat_mortality, loc) {
  
  ### check spatial scale
  match.arg(loc,
            choices = c("canada", "prov", "hr"),
            several.ok = FALSE)
  
  ### create active case time series
  if (loc == "hr") {
    stop("Active cases health region time series not currently supported.")
  } else if (loc %in% c("prov", "canada")) {
    ### provincial and Canadian time series are constructed in the same way
    left_join(
      dat_cases %>% rename(date_active = date_report) %>% select(-cases),
      dat_recovered %>% rename(date_active = date_recovered) %>% select(-recovered),
      by = c("province", "date_active")
    ) %>%
      left_join(
        dat_mortality %>% rename(date_active = date_death_report) %>% select(-deaths),
        by = c("province", "date_active")
      ) %>%
      ### replace NA with 0 (cases can't have NA because this time series starts first)
      replace_na(list(cumulative_recovered = 0, cumulative_deaths = 0)) %>%
      ### arrange
      arrange(province, date_active) %>%
      ### calculate active cases
      mutate(active_cases = cumulative_cases - cumulative_recovered - cumulative_deaths) %>%
      group_by(province) %>%
      mutate(active_cases_change = active_cases - lag(active_cases, n = 1, default = 0)) %>%
      ungroup %>%
      select(province, date_active, cumulative_cases, cumulative_recovered, cumulative_deaths, active_cases, active_cases_change) %>%
      return
  }
}