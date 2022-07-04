# EXTRACT ALL TWEETS to JSON

## 1. Loading the required R libraries

packages <- c("dplyr", "academictwitteR")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# Disable scientific notation of numbers
options(scipen = 999)

## 2. Function for the extraction of Twitter content, which adds new account's tweets if not yet present in the dataset

get_all_twitter_tweets <- function(accounts, start_date, end_date, dir_name, upper_limit, token, exceptions) {

  # We have to create a desired directory, if one does not yet exist
  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }

    #Remove any NAs
    accounts <- accounts[!is.na(accounts)] # Vector with twitter usernames

    existing_twitter_dataset_usernames <- readRDS(paste0(dir_name, "/binded_tweets.rds"))[["user_username"]]

    print("Dataset contains the following tweets")

    print(table(existing_twitter_dataset_usernames))

    # Using existing twitter dataset, filter out usernames that are already present in it. Exceptions are accounts that have no tweets.
    accounts <- accounts[!tolower(accounts) %in% c(tolower(existing_twitter_dataset_usernames), exceptions)]

    if (length(accounts) == 0) { stop("There are no new accounts to add to the dataset, will not extract data.") }

    # This function calls the Twitter API and saves the output to JSON
    get_all_tweets(users = accounts,
                   start_tweets = start_date,
                   end_tweets = end_date,
                   is_retweet = NULL,
                   data_path = paste0(dir_name, "/raw_json_data_", format(Sys.Date(), format = "%Y_%m_%d"), "/"),
                   export_query = TRUE,
                   bind_tweets = FALSE,
                   n = upper_limit,
                   bearer_token = token)

  }


## 3. Running the function
get_all_twitter_tweets(accounts = readRDS("1.data_sources/twitter/twitter_acc_ids.rds"),
                       start_date = "2015-01-01T00:00:00Z",
                       end_date = paste0(format(Sys.Date(), format = "%Y-%m-%d"), "T00:00:00Z"),
                       dir_name = "1.data_sources/twitter/data",
                       upper_limit = Inf,
                       token = Sys.getenv("TWITTER_TOKEN"),
                       exceptions = c("krajskelisty"))



