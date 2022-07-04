## IF WE HAVE NUMERIC TWITTER ACCOUNT ID, WE CAN GET DETAILED INFO ABOUT THE ACCOUNT

## 1. Loading the required R libraries

# Package names
packages <- c("academictwitteR")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

get_twitter_account_info <- function(users_numeric, token, dir_name) {

  #Remove any NAs
  users_numeric <- users_numeric[!is.na(users_numeric)] # Vector with twitter usernames

  user_info <- get_user_profile(
    users_numeric,
    bearer_token = token
  )

  # Save df as an RDS object
  saveRDS(user_info, file = paste0(dir_name, "/user_info.rds"), compress = TRUE)

}

# Specify function inputs
users_numeric <- readRDS("1.data_sources/twitter/data/user_numeric_ids.rds")[["id"]]
token <- Sys.getenv("TWITTER_TOKEN")
dir_name <- "1.data_sources/twitter/data"

# Run function
get_twitter_account_info(users_numeric, token, dir_name)

