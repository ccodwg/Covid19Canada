# COVID-19 Canada Open Data Working Group: Mirror datasets in GitHub repository to Google Drive in Google Sheets format #
# Author: Jean-Paul R. Soucy #

# This script mirrors the datasets in the CCODWG GitHub repository (https://github.com/ccodwg/Covid19Canada) #
# to a Google Drive folder (https://drive.google.com/drive/folders/1He6mPAbolgh7jtsq1zu6LpLQKz34n_nP). #

# Note: This script assumes the working directory is set to the root directory of the project
# This is most easily achieved by using the provided Covid19Canada.Rproj in RStudio

# Authentication: You must authenticate your Google account before running the rest of the script.
# This is performed in the conductor.R script. See details there.

# Example of downloading CSVs from Google Sheets hosted on Google Drive
# cases_timeseries_hr: https://docs.google.com/spreadsheets/d/1Ue6HfXbXEQWx6H2eHxORlarU-g9G283iBAsrLA5wg-g/export?format=csv&id=1Ue6HfXbXEQWx6H2eHxORlarU-g9G283iBAsrLA5wg-g
# mortality_timeseries_hr: https://docs.google.com/spreadsheets/d/1yHQ_U5RvyCXdtum0luuDNmANv_t3_lnrQ8KGk41R0zg/export?format=csv&id=1yHQ_U5RvyCXdtum0luuDNmANv_t3_lnrQ8KGk41R0zg

# load libraries
library(dplyr)

# define folders
folders <- c("official_datasets", "other", "timeseries_canada",
             "timeseries_hr", "timeseries_hr_sk_new", "timeseries_prov")

# download GitHub repository and list relevant files
temp <- tempfile()
tempd <- tempdir()
download.file("https://github.com/ccodwg/Covid19Canada/archive/master.zip", temp, mode = "wb")
unzip(temp, exdir = tempd)
files <- list.files(path = tempd, pattern = "*.csv|*.txt|*.md|*.MD", full.names = TRUE, recursive = TRUE)

### DATA IN GOOGLE SHEETS FORMAT ###

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
    d <- read.csv(fs[f], stringsAsFactors = TRUE, header = TRUE)
    ss <- gd[gd$name == sub(".csv$", "", basename(fs[f])), ]
    tryCatch(
      sheet_write(data = d, ss = ss, sheet = 1),
      error = function(e) {print(e); cat("Upload failed:", ss$name, fill = TRUE)}
    )
  }
}

### FILES IN ROOT DIRECTORY ###

# copy files in root directory (note that the MD files cannot be converted)
tryCatch(
  drive_update(as_id("1l2l0CCigx2ISI9NYeRcdcfz1ABI0z2yz"), files[grep("/README.md", files)]),
  error = function(e) {print(e); cat("Upload failed: README.md", fill = TRUE)}
)
tryCatch(
  drive_update(as_id("1ovgnXT39rhLi0cFu79l-luMkMkE5PUcF"), files[grep("/LICENSE.MD", files)]),
  error = function(e) {print(e); cat("Upload failed: LICENSE.MD", fill = TRUE)}
)
tryCatch(
  drive_update(as_id("10XQFWIYxmebh9kiY3xyHh2YPnUNvdugt03ewieoao5w"), files[grep("/data_notes.txt", files)]),
  error = function(e) {print(e); cat("Upload failed: data_notes.txt", fill = TRUE)}
)

# copy update time (should be LAST file updated)
update_time <- readLines(files[grep("/update_time.txt", files)])
update_time <- data.frame(update_time)
tryCatch(
  range_write(
    data = update_time,
    ss = as_id("1kF9Y56WboXU86SqoRaPSrpcwlk9oXD5Cp76wJTWdWNY"),
    sheet = 1,
    range = "A1",
    col_names = FALSE),
  error = function(e) {print(e); cat("Upload failed: update_time", fill = TRUE)}
)
