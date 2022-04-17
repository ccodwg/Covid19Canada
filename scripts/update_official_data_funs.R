# Functions for: COVID-19 Canada Open Data Working Group Official Dataset Download and Compatibility Script #
# Author: Jean-Paul R. Soucy #

# import functions from update_data.R
source("scripts/update_data_funs.R")

# convert official Quebec dataset
# INSPQ dataset: https://www.inspq.qc.ca/covid-19/donnees
convert_official_qc <- function() {
  
  ## download current QC datasets
  dat <- Covid19CanadaData::dl_dataset("3b93b663-4b3f-43b4-a23d-cbf6d149d2c5") # covid19-hist.csv
  dat2 <- Covid19CanadaData::dl_dataset("b78d46c8-9a56-4b75-94c5-4ace36e014f5") # manual-data.csv
  
  ## convert data into CCODWG dataset format
  dat <- dat %>%
    ### filter out unknown dates
    filter(Date != "Date inconnue") %>%
    ### convert date variable
    mutate(Date = as.Date(Date)) %>%
    ### rename variables (incomplete)
    rename(
      date = Date
    )
  ### dataset2: just keep part of the dataset
  dat2 <- dat2[24:nrow(dat2), 1:5] %>%
    ### rename variables
    rename(
      date = 1,
      hosp = 2,
      icu = 3,
      hosp_old = 4,
      samples_analyzed = 5
    ) %>%
    ### convert date variable
    mutate(date = as.Date(date, "%d/%m/%Y")) %>%
    ### convert integer variables
    mutate(across(c(hosp, icu, hosp_old, samples_analyzed), as.integer))
  
  ## create province-level testing time series
  ## INSPQ data: https://www.inspq.qc.ca/covid-19/donnees
  ## see charts 4.1, 4.2, 4.3 for more info on meaning of each variable
  ## methodology: https://www.inspq.qc.ca/covid-19/donnees/methodologie
  qc_testing_datasets_prov <- dat %>%
    ### filter to Quebec, province-level
    filter(Regroupement == "Région" & Nom == "Ensemble du Québec") %>%
    ### keep necessary variables
    select(date, psi_cum_tes_n, psi_cum_pos_n, psi_cum_inf_n, psi_quo_pos_n,
           psi_quo_inf_n, psi_quo_tes_n, psi_quo_pos_t) %>%
    mutate(province = "Quebec") %>%
    ### rename variables
    rename(
      date = date, # date variable has different meaning depending on column
      cumulative_unique_people_tested = psi_cum_tes_n, # 4.1
      cumulative_unique_people_tested_positive = psi_cum_pos_n, # 4.1
      cumulative_unique_people_tested_negative = psi_cum_inf_n, # 4.1
      unique_people_tested_positive = psi_quo_pos_n, # 4.2
      unique_people_tested_negative = psi_quo_inf_n, # 4.2
      unique_people_tested = psi_quo_tes_n, # 4.2
      unique_people_tested_positivity_percent = psi_quo_pos_t # 4.2
    ) %>%
    ### merge with sample analyzed data
    full_join(
      dat2 %>%
        select(date, samples_analyzed),
      by = "date"
    ) %>%
    ### fill zeros for all columns
    replace_na(list(
      samples_analyzed = 0
    )) %>%
    mutate(unique_people_tested_positivity_percent = as.numeric(ifelse(unique_people_tested_positivity_percent == "         .  ", 0, unique_people_tested_positivity_percent))) %>%
    ### sort by date
    arrange(date) %>%
    ### add cumulative samples analyzed
    mutate(cumulative_samples_analyzed = cumsum(samples_analyzed)) %>%
    ### arrange columns
    select(
      date, province,
      cumulative_unique_people_tested, cumulative_unique_people_tested_positive, cumulative_unique_people_tested_negative, # 4.1
      unique_people_tested, unique_people_tested_positive, unique_people_tested_negative, unique_people_tested_positivity_percent, # 4.2
      samples_analyzed, cumulative_samples_analyzed # 4.3
    )
  
  ### convert dates to non-standard date format for writing
  convert_dates("qc_testing_datasets_prov",
                date_format_out = "%d-%m-%Y")
  
  ### write generated files
  write.csv(qc_testing_datasets_prov, "official_datasets/qc/qc_testing_datasets_prov.csv")
  
}

# convert official PHAC testing (n_tests_completed) province-level dataset
convert_phac_testing_prov <- function() {
  
  # note that PHAC has not reported "n_persons_tested" ("numtested" in the original dataset) since early 2021
  # thus, this value has been excluded from this dataset
  
  # download dataset
  ds <- Covid19CanadaData::dl_dataset("f7db31d0-6504-4a55-86f7-608664517bdb")
  
  # process dataset
  dat <- Covid19CanadaDataProcess::process_dataset(
    uuid = "f7db31d0-6504-4a55-86f7-608664517bdb",
    val = "testing",
    fmt = "prov_ts",
    testing_type = "n_tests_completed",
    ds = ds
  ) %>%
    dplyr::select(-.data$name) %>%
    dplyr::rename(c(
      "n_tests_completed" = "value"),
      "province" = "region") %>%
    dplyr::group_by(.data$province) %>%
    dplyr::mutate(n_tests_completed_daily = c(0, diff(.data$n_tests_completed)))
  
  # save dataset
  write.csv(dat, "official_datasets/can/phac_n_tests_performed_timeseries_prov.csv", row.names = FALSE)
  
}

# update NT sub health-region cases and active cases
update_nt_subhr <- function(update_date, archive_date = NULL) {
  
  # download data
  if (!is.null(archive_date)) {
    # download archived data
    update_date <- as.Date(as.character(archive_date))
    ds <- Covid19CanadaData::dl_archive("9ed0f5cd-2c45-40a1-94c9-25b0c9df8f48",
                                        date = as.character(update_date))[[1]]
  } else {
    # download live dataset
    ds <- Covid19CanadaData::dl_dataset("9ed0f5cd-2c45-40a1-94c9-25b0c9df8f48")
  }
  
  ## cases ##
  
  # process cases
  nt_cases_subhr <- Covid19CanadaDataProcess::process_dataset(
    uuid = "9ed0f5cd-2c45-40a1-94c9-25b0c9df8f48",
    val = "cases",
    fmt = "subhr_cum_current_residents_nonresidents",
    ds = ds
  )
  
  # if nt_cases_subhr is NA, try downloading ds again and try again
  if (identical(nt_cases_subhr, NA)) {
    Sys.sleep(15)
    ds <- Covid19CanadaData::dl_dataset("9ed0f5cd-2c45-40a1-94c9-25b0c9df8f48")
    nt_cases_subhr <- Covid19CanadaDataProcess::process_dataset(
      uuid = "9ed0f5cd-2c45-40a1-94c9-25b0c9df8f48",
      val = "cases",
      fmt = "subhr_cum_current_residents_nonresidents",
      ds = ds
    )
  }
  
  # fix date for archived data
  if (!is.null(archive_date)) {
    nt_cases_subhr$date <- update_date
  }
  
  # if still NA, throw an error
  if (identical(nt_cases_subhr, NA)) {
    stop("Failed to download ds: 9ed0f5cd-2c45-40a1-94c9-25b0c9df8f48.")
  }
  
  # download current sheet
  nt_cases_subhr_old <- Covid19CanadaETL::sheets_load(
    "1RSy3qAqA4jdC4QUVTcSBogIerP7-rNic0H3L5F8_uE0",
    "cases_timeseries_subhr"
  ) %>% dplyr::mutate(date = as.Date(date))
  
  # calculate daily deltas
  nt_cases_subhr_old <- nt_cases_subhr_old %>%
    dplyr::filter(date == as.Date(update_date) - 1)
  nt_cases_subhr$value_daily <- nt_cases_subhr$value - as.integer(nt_cases_subhr_old$value)
  
  # check if new data was acquired successfully
  if (sum(is.na(nt_cases_subhr$value)) > 0 | nrow(nt_cases_subhr) == 0) {
    stop("Failed to process ds: 9ed0f5cd-2c45-40a1-94c9-25b0c9df8f48.")
  } else {
    # remove today's results if re-running
    if (update_date %in% nt_cases_subhr_old$date) {
      nt_cases_subhr_old <- nt_cases_subhr_old %>%
        dplyr::filter(date != update_date)
      sheet_write(
        data = nt_cases_subhr_old,
        ss = "1RSy3qAqA4jdC4QUVTcSBogIerP7-rNic0H3L5F8_uE0",
        sheet = "cases_timeseries_subhr")
    }
    
    # update on Google Sheets
    googlesheets4::sheet_append(
      "1RSy3qAqA4jdC4QUVTcSBogIerP7-rNic0H3L5F8_uE0",
      nt_cases_subhr,
      "cases_timeseries_subhr"
    ) 
  }
  
  ## active cases ##
  
  # process active cases
  nt_active_subhr <- Covid19CanadaDataProcess::process_dataset(
    uuid = "9ed0f5cd-2c45-40a1-94c9-25b0c9df8f48",
    val = "active",
    fmt = "subhr_current",
    ds = ds
  )
  
  # fix date for archived data
  if (!is.null(archive_date)) {
    nt_active_subhr$date <- update_date
  }
  
  # download current sheet
  nt_active_subhr_old <- Covid19CanadaETL::sheets_load(
    "1RSy3qAqA4jdC4QUVTcSBogIerP7-rNic0H3L5F8_uE0",
    "active_timeseries_subhr"
  ) %>% dplyr::mutate(date = as.Date(date))
  
  # remove today's results if re-running
  if (update_date %in% nt_active_subhr_old$date) {
    nt_active_subhr_old <- nt_active_subhr_old %>%
      dplyr::filter(date != update_date)
    sheet_write(
      data = nt_active_subhr_old,
      ss = "1RSy3qAqA4jdC4QUVTcSBogIerP7-rNic0H3L5F8_uE0",
      sheet = "active_timeseries_subhr")
  }
  
  # calculate daily deltas
  nt_active_subhr_old <- nt_active_subhr_old %>%
    dplyr::filter(date == as.Date(update_date) - 1)
  nt_active_subhr$value_daily <- nt_active_subhr$value - as.integer(nt_active_subhr_old$value)
  
  # update on Google Sheets
  googlesheets4::sheet_append(
    "1RSy3qAqA4jdC4QUVTcSBogIerP7-rNic0H3L5F8_uE0",
    nt_active_subhr,
    "active_timeseries_subhr"
  )
  
  ## update datasets ##
  
  # download datasets from Google Sheets
  nt_cases_timeseries_subhr <- Covid19CanadaETL::sheets_load(
    "1RSy3qAqA4jdC4QUVTcSBogIerP7-rNic0H3L5F8_uE0", "cases_timeseries_subhr")
  nt_active_timeseries_subhr <- Covid19CanadaETL::sheets_load(
    "1RSy3qAqA4jdC4QUVTcSBogIerP7-rNic0H3L5F8_uE0", "active_timeseries_subhr")
  
  # write datasets
  write.csv(nt_cases_timeseries_subhr, "official_datasets/nt/nt_cases_timeseries_subhr.csv", row.names = FALSE)
  write.csv(nt_active_timeseries_subhr, "official_datasets/nt/nt_active_timeseries_subhr.csv", row.names = FALSE)
  
}
