# COVID-19 Canada Open Data Working Group: Mirror datasets in GitHub repository to Google Drive #
# Author: Jean-Paul R. Soucy #

# This script mirrors the datasets in the CCODWG GitHub repository (https://github.com/ccodwg/Covid19Canada) #
# to a Google Drive folder (https://drive.google.com/drive/folders/1He6mPAbolgh7jtsq1zu6LpLQKz34n_nP). #

# Note: This script assumes the working directory is set to the root directory of the project
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# Authentication: You must authenticate your Google account before running the rest of the script.
# You may be asked to give "Tidyverse API Packages" read/write access to your Google account.

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
folder_ids <- c(
  "1lptRTUZNQcK8fnzgwKwZ14wiiZY86pMM",
  "1rTj9d2BfDUUrVPi2i8VqbZNIiSUiafUT",
  "1J7jJ0qSKBg7m45uifFw8x8YRqWA-oD4V",
  "1uLJb65WlVzec5utMpPqXiBjgZ0IcA4n5",
  "1URCbAouAcm_eEf4hlGQ9dFW8L4WZMcD7",
  "1qUL_FMYSApFotrJ_75XlLaET9ilEdmxN"
)

# define functions
delete_files_in_dir <- function(id) {
  files <- drive_ls(as_id(id)) %>%
    filter(!name %in% folders)
  drive_rm(files)
}

# remove existing files
for (i in c("1He6mPAbolgh7jtsq1zu6LpLQKz34n_nP", folder_ids)) {
  delete_files_in_dir(i)
}

# download GitHub repository and list relevant files
temp <- tempfile()
tempd <- tempdir()
download.file("https://github.com/ccodwg/Covid19Canada/archive/master.zip", temp, mode = "wb")
unzip(temp, exdir = tempd)
files <- list.files(path = tempd, pattern = "*.csv|*.txt|*.md|*.MD", full.names = TRUE, recursive = TRUE)

# mirror GitHub repository
for (f in files[grep("/update_time.txt|/README.md|/LICENSE.MD", files)]) {
  drive_upload(f, as_id("1He6mPAbolgh7jtsq1zu6LpLQKz34n_nP"))
}
for (i in 1:length(folders)) {
  fs <- files[grep(paste0("/", folders[i], "/"), files)]
  for (f in 1:length(fs)) {
    drive_upload(fs[f], as_id(folder_ids[i]))
  }
}
