# Functions for: COVID-19 Canada Open Data Working Group Data Update Script #
# Author: Jean-Paul R. Soucy #

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
