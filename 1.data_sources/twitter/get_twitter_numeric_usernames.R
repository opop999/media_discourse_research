# FOR SOME USE-CASES, WE NEED NUMERIC TWITTER USERNAME. WE CAN CONVERT IT WITH THIS SCRIPT.

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

convert_twitter_usernames_numeric <- function(users_character, token, dir_name) {

  #Remove any NAs
  users_character <- users_character[!is.na(users_character)] # Vector with twitter usernames

  users_numeric <- get_user_id(
    users_character,
    bearer_token = token,
    all = TRUE,
    keep_na = TRUE
  )

  # Save df as an RDS object
  saveRDS(users_numeric, file = paste0(dir_name, "/user_numeric_ids.rds"), compress = TRUE)

}

# Specify function inputs
users_character <- readRDS("1.data_sources/twitter/twitter_acc_ids.rds")
token <- Sys.getenv("TWITTER_TOKEN")
dir_name <- "1.data_sources/twitter/data"

# Run function
convert_twitter_usernames_numeric(users_character, token, dir_name)

