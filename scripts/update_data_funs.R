# Functions for: COVID-19 Canada Open Data Working Group Data Update Script #
# Author: Jean-Paul R. Soucy #

# define data processing functions

## convert dates dates between %Y-%m-%d format (for data manipulation) and %d-%m-%Y format (for writing)
convert_dates <- function(..., date_format_out = c("%Y-%m-%d", "%d-%m-%Y")) {
  
  ### check date format
  match.arg(date_format_out,
            choices = c("%Y-%m-%d", "%d-%m-%Y"),
            several.ok = FALSE)
  
  ### get object names as a list
  inputs <- unlist(list(...))
  
  ### convert date and write to global environment
  if (date_format_out == "%Y-%m-%d") {
    for (i in inputs) {
      assign(i, get(i) %>%
               mutate(
                 across(starts_with("date_"), as.Date, format = "%d-%m-%Y")),
             envir = .GlobalEnv
      )
    }
  } else if (date_format_out == "%d-%m-%Y") {
    for (i in inputs) {
      assign(i, get(i) %>%
               mutate(
                 across(starts_with("date_"), format.Date, format = "%d-%m-%Y")),
             envir = .GlobalEnv
      )
    }
  }
}

# define functions for individual-level data

## abbreviate source variables in individual-level data and export unique values to an abbreviation table
abbreviate_source <- function(dat, abbrev, var_source) {
  
  # save dataset names
  dat_name <- deparse(substitute(dat))
  abbrev_name <- deparse(substitute(abbrev))
  
  # save dataset column order
  dat_cols <- names(dat)
  
  # generate abbreviations
  
  ## get unique source var values and drop values already in the abbreviation table
  abbrev_new <- dat %>%
    select(province, !!sym(var_source)) %>%
    distinct %>%
    ### join province short names
    left_join(
      map_prov,
      by = "province"
    ) %>%
    ### rename column
    rename(
      var_source_full = !!sym(var_source)
    ) %>%
    ### drop source var values already in the abbreviation table
    filter(!var_source_full %in% (abbrev %>% pull(!!sym(paste0(var_source, "_full")))))
  
  ## check if there are any source var values values to add (otherwise skip to the end)
  if (nrow(abbrev_new) != 0) {
    ## assemble new additions to the abbreviation table
    abbrev_new <- abbrev_new %>%
      ### group by province
      group_by(province) %>%
      ### generate IDs and then abbreviations by province
      mutate(
        var_source_id = row_number() +
          ifelse(
            province %in% (abbrev %>%
                             pull(province)),
            max(
              abbrev %>%
                filter(province == .$province) %>%
                pull(!!sym(paste0(var_source, "_id")))
            ),
            0
          ),
        var_source_short = paste0(province_short, var_source_id)
      ) %>%
      ### drop province_short
      select(-province_short) %>%
      ungroup %>%
      ### rename columns
      rename(
        !!sym(paste0(var_source, "_id")) := var_source_id,
        !!sym(paste0(var_source, "_short")) := var_source_short,
        !!sym(paste0(var_source, "_full")) := var_source_full
      )
    
    ## join new abbreviations to abbreviation table
    abbrev <- bind_rows(abbrev, abbrev_new) %>%
      arrange(province, !!sym(paste0(var_source, "_id")))
    
    ## verify there are no duplicated abbreviations
    if (sum(table(abbrev[, paste0(var_source, "_short")]) > 1) != 0) {
      stop("There are duplicated abbreviations.")
    }
    
    ## verify there are no missing values in the abbreviation table
    if (sum(is.na(abbrev)) != 0) {
      stop("There are missing values in the abbreviation table.")
    }
  }
  
  # data: replace source var with the abbreviated source var
  
  ## column names for join
  join_cols <- setNames(c("province", paste0(var_source, "_full")), c("province", eval(var_source)))
  
  ## join
  dat <- dat %>%
    left_join(
      abbrev %>%
        select(province, !!sym(paste0(var_source, "_short")), !!sym(paste0(var_source, "_full"))),
      by = join_cols
    ) %>%
    ### replace source var with abbreviated source var
    select(-!!sym(var_source)) %>%
    rename(!!sym(var_source) := !!sym(paste0(var_source, "_short"))) %>%
    ### return columns to original order
    select(all_of(dat_cols))
  
  # final file verification before writing
  if (sum(is.na(dat[, var_source])) != 0) {
    stop("Some source vars have not been abbreviated.")
  }
  
  # write data and updated abbreviation table to global environment
  assign(dat_name, dat, envir = .GlobalEnv)
  assign(abbrev_name, abbrev, envir = .GlobalEnv)
  
}

# define functions for time series data

## create time series (cases, mortality, recovered, testing)
create_ts <- function(dat,
                      stat = c("cases", "mortality", "recovered", "testing"),
                      loc = c("canada", "prov", "hr"),
                      date_min) {
  
  
  ### check statistic
  match.arg(stat,
            choices = c("cases", "mortality", "recovered", "testing"),
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
    "testing" = {var_date <- "date_testing"; var_val <- "testing"; var_val_cum <- "cumulative_testing"}
  )
  
  ### keep extra info for later joining (if applicable)
  if (stat == "testing" & loc %in% c("prov", "canada")) {
    dat_testing_info <- dat %>%
      select(province, date_testing, testing_info)
  }
  
  ### build time series
  if (stat %in% c("cases", "mortality")) {
    ### build health region time series as baseline
    dat <- dat %>%
      select(province, health_region, !!sym(var_date)) %>%
      arrange(province, health_region, !!sym(var_date)) %>%
      group_by(province, health_region, !!sym(var_date)) %>%
      summarize(
        !!sym(var_val) := n(),
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
      replace_na(
        as.list(setNames(0, var_val))
      ) %>%
      mutate(
        !!sym(var_val_cum) := cumsum(!!sym(var_val))
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
  } else if (stat %in% c("recovered", "testing")) {
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
    if (loc == "hr") {
      ### health region time series
      stop("Recovered/testing health region time series not currently supported.")
    } else if (loc == "prov") {
      ### provincial time series
      if (stat == "testing") {
        ### add testing_info column
        return(
          dat %>%
            left_join(
              dat_testing_info,
              by = c("province", "date_testing")
            ) %>%
            select(province, date_testing, testing, cumulative_testing, testing_info)
        )
      } else {
        return(
          dat %>%
            select(province, !!sym(var_date), !!sym(var_val), !!sym(var_val_cum))
        )
      }
    } else if (loc == "canada") {
      ### Canadian time series
      if (stat == "testing") {
        ### add testing_info column
        return(
          dat %>%
            select(province, date_testing, testing, cumulative_testing) %>%
            mutate(province = "Canada") %>%
            group_by(province, date_testing) %>%
            summarize(
              testing = sum(testing),
              cumulative_testing = sum(cumulative_testing),
              .groups = "drop"
            ) %>%
            left_join(
              dat_testing_info %>%
                select(date_testing, testing_info) %>%
                filter(testing_info != "") %>%
                distinct,
              by = "date_testing"
            ) %>%
            replace_na(list(testing_info = "")) %>%
            select(province, date_testing, testing, cumulative_testing, testing_info)
        )
      } else {
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