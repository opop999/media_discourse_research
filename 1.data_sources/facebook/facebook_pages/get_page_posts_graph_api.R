# PART 1: LOAD THE REQUIRED LIBRARIES FOR THIS SCRIPT

# Package names
packages <- c("httr", "dplyr")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))


temporary_token <- Sys.getenv("SHORT_LIVED_FB_TOKEN")

posts_list <- list()

facebook_acc <- "hospodarky"

# Set min date and max date

# Using the old API endpoint to get raw response
response <- content(httr::GET(
  url = paste0("https://graph.facebook.com/v5.0/", facebook_acc, "/posts"),
  httr::add_headers(
    Accept = "application/json"
  ),
  query = list(
    limit = "100",
    access_token = temporary_token,
    since = min_date,
    until = max_date
  )), as = "parsed")

# Add first 100 records to the list
posts_list[[1]] <- response[["data"]]

# Extract the url for the next call
next_url <- response[["paging"]][["next"]]


# Here begins the for loop to get other pages
response <- content(httr::VERB(
  verb = "GET",
  url = next_url,
  httr::add_headers(
    Accept = "application/json"
  )), as = "parsed")

posts_list[[2]] <- response[["data"]]

next_url <- response[["paging"]][["next"]]


fb_posts_df <- bind_rows(posts_list)

