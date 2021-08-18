# COVID-19 Canada Open Data Working Group: Mirror datasets in GitHub repository to Google Drive #
# Author: Jean-Paul R. Soucy #

# This script mirrors the datasets in the CCODWG GitHub repository (https://github.com/ccodwg/Covid19Canada) #
# to a Google Drive folder (https://drive.google.com/drive/folders/1He6mPAbolgh7jtsq1zu6LpLQKz34n_nP). #

# Note: This script assumes the working directory is set to the root directory of the project
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# Authentication: You must authenticate your Google account before running the rest of the script.
# You may be asked to give "Tidyverse API Packages" read/write access to your Google account.

# Example of downloading CSVs from Google Sheets hosted on Google Drive
# cases_timeseries_hr: https://docs.google.com/spreadsheets/d/1Ue6HfXbXEQWx6H2eHxORlarU-g9G283iBAsrLA5wg-g/export?format=csv&id=1Ue6HfXbXEQWx6H2eHxORlarU-g9G283iBAsrLA5wg-g
# mortality_timeseries_hr: https://docs.google.com/spreadsheets/d/1yHQ_U5RvyCXdtum0luuDNmANv_t3_lnrQ8KGk41R0zg/export?format=csv&id=1yHQ_U5RvyCXdtum0luuDNmANv_t3_lnrQ8KGk41R0zg

# authenticate your Google account before running the rest of the script
library(googledrive) # interface with Google Drive
if (file.exists("email.txt")) {
  # automatically read account name from email.txt, if present
  drive_auth(readLines("email.txt"))
} else {
  # otherwise, prompt for authentication
  drive_auth()
}

# load libraries
library(dplyr)

# define folders
folders <- c("official_datasets", "other", "timeseries_canada",
             "timeseries_hr", "timeseries_hr_sk_new", "timeseries_prov")

### RAW CSV FORMAT ###

# define folder IDs
folder_ids <- c(
  "1lptRTUZNQcK8fnzgwKwZ14wiiZY86pMM",
  "1rTj9d2BfDUUrVPi2i8VqbZNIiSUiafUT",
  "1J7jJ0qSKBg7m45uifFw8x8YRqWA-oD4V",
  "1uLJb65WlVzec5utMpPqXiBjgZ0IcA4n5",
  "1URCbAouAcm_eEf4hlGQ9dFW8L4WZMcD7",
  "1qUL_FMYSApFotrJ_75XlLaET9ilEdmxN"
)

# download GitHub repository and list relevant files
temp <- tempfile()
tempd <- tempdir()
download.file("https://github.com/ccodwg/Covid19Canada/archive/master.zip", temp, mode = "wb")
unzip(temp, exdir = tempd)
files <- list.files(path = tempd, pattern = "*.csv|*.txt|*.md|*.MD", full.names = TRUE, recursive = TRUE)

# mirror datasets in GitHub repository
for (i in 1:length(folders)) {
  gd <- drive_ls(as_id(folder_ids[i]))
  fs <- files[grep(paste0("/", folders[i], "/"), files)]
  for (f in 1:length(fs)) {
    drive_update(gd[gd$name == basename(fs[f]), ], fs[f])
  }
}

### GOOGLE SHEETS FORMAT ###

# define folder IDs
folder_ids <- c(
  "1HIXc0pmp-UCqu_qfxlBb9IT-Oiodycsv",
  "1nH3Tww7mKWfaYnJjWQlg4Uv2qaZFuwpD",
  "1WT-NT36yZAAjBqv-j9XEUJsvcE6Obojx",
  "12A5jyQ6ELtbc0qFSgxSsMpKebca4mahg",
  "17C8nL6nT6qJ8GZx4xo3CBEfxERzkdMui",
  "1vkpKlRUMRuMGMlBkubodteTZUdmLp0RU"
)

# copy CSV files and convert to Google Sheets
for (i in 1:length(folders)) {
  gd <- drive_ls(as_id(folder_ids[i]))
  fs <- files[grep(paste0("/", folders[i], "/"), files)]
  for (f in 1:length(fs)) {
    drive_update(
      gd[gd$name == sub(".csv$", "", basename(fs[f])), ],
      fs[f],
      mime_type = drive_mime_type("spreadsheet"))
  }
}

### FILES IN ROOT DIRECTORY ###

# [CSV FORMAT] update files in root directory
drive_update(as_id("1xIVU43CMv0AaH9LgjPyebAz7gqimo3Dq"), files[grep("/README.md", files)])
drive_update(as_id("1mojC1dHjsZr1Tx8MNLYbZ8-8ghmfndh4"), files[grep("/LICENSE.MD", files)])
drive_update(as_id("1k4YYdQQezhNz3wLoOAfSUuaesk13RSxv"), files[grep("/update_time.txt", files)]) # should be LAST file updated

# [GOOGLE SHEETS FORMAT] copy files in root directory (note that the MD files cannot be converted)
drive_update(as_id("1l2l0CCigx2ISI9NYeRcdcfz1ABI0z2yz"), files[grep("/README.md", files)])
drive_update(as_id("1ovgnXT39rhLi0cFu79l-luMkMkE5PUcF"), files[grep("/LICENSE.MD", files)])
drive_update(as_id("1hNQJCuqQSg_nh1tClTLxkck4cmlzrdxCtw351jRN3rk"), files[grep("/update_time.txt", files)], mime_type = drive_mime_type("document")) # should be LAST file updated
