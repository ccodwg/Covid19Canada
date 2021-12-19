# Functions for: Orchestrate the nightly COVID-19 Canada Open Data Working Group data update #
# Author: Jean-Paul R. Soucy #

# send email via POST request to GitHub Actions
send_email <- function(subject, body) {
  
  # check if GitHub PAT is available in environment
  if (Sys.getenv("GITHUB_PAT") != "") {
    
    # create JSON request body
    json_body <- jsonlite::toJSON(
      list(ref = "main", inputs = list(subject = subject, body = body)),
      auto_unbox = TRUE)
    
    # send POST request
    httr::POST(
      url = "https://api.github.com/repos/ccodwg/Covid19CanadaBot/actions/workflows/send-email.yml/dispatches",
      body = json_body,
      encode = "raw",
      httr::add_headers(Accept = "application/vnd.github.v3+json"),
      httr::authenticate(
        user = "jeanpaulrsoucy",
        password = Sys.getenv("GITHUB_PAT"))
    )
  } else {
    warning("Cannot send email. GitHub PAT must be available from the environment as GITHUB_PAT.")
  }
}

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
