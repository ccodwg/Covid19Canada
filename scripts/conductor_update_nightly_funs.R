# Functions for: Orchestrate the nightly COVID-19 Canada Open Data Working Group data update #
# Author: Jean-Paul R. Soucy #

# get time in ET time zone (America/Toronto)
get_time_et <- function() {
  with_tz(Sys.time(), tzone = "America/Toronto")
}

# run function after certain date & time (assumes ET time zone) has been reached
run_at <- function(time_et, FUN) {
  time_et <- as.POSIXct(time_et, tz = "America/Toronto") # assume ET time zone
  cat("Waiting until", as.character(time_et), "to continue...", fill = TRUE)
  cat("Current time:", as.character(get_time_et()), fill = TRUE)
  while(get_time_et() < time_et) {
    cat(as.character(get_time_et()), "... waiting", fill = TRUE) # print current time
    Sys.sleep(30) # check every 30 seconds
  }
  cat("Continuing script...", fill = TRUE)
  FUN
}
