# COVID-19 Canada Open Data Working Group Push Updated Data to GitHub #
# Author: Jean-Paul R. Soucy #

# Push updated files to the GitHub repository using git from the command line
# GitHub repository: https://github.com/ccodwg/Covid19Canada

# Note: This script assumes the working directory is set to the root directory of the project
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# Authentication: You must authenticate your Google account before running the rest of the script.
# You may be asked to give "Tidyverse API Packages" read/write access to your Google account.

# GitHub: This script assumes a stored SSH key for GitHub.

# authenticate your Google account before running the rest of the script
library(googledrive) # interface with Google Drive
if (file.exists("email.txt")) {
  # automatically read account name from email.txt, if present
  drive_auth(readLines("email.txt"))
} else {
  # otherwise, prompt for authentication
  drive_auth()
}

# list files in Google Drive data folder
files <- drive_ls("ccodwg/data")

# download and format data notes, append current date as header
drive_download(
  files[files$name == "data_notes_covid19", ],
  path = "data_notes.txt",
  overwrite = TRUE
)
data_notes <- suppressWarnings(readLines("data_notes.txt"))
header <- paste0("New data: ", as.character(date(with_tz(Sys.time(), tzone = "America/Toronto"))), ". See data notes.\n\n")
data_notes <- paste0(header, paste(data_notes, collapse = "\n"), "\n")

# write data notes
cat(data_notes, file = "data_notes.txt")

# stage data update
system2(
  command = "git",
  args = c("add",
           "official_datasets/",
           "timeseries_canada/",
           "timeseries_hr/",
           "timeseries_hr_sk_new/",
           "timeseries_prov",
           "data_notes.txt",
           "update_time.txt"
           )
  )

# commit data update
system2(
  command = "git",
  args = c("commit",
           "-m",
           paste0('"', data_notes, '"')
           )
)

# push data update
system2(
  command = "git",
  args = c("push")
)
