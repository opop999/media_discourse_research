# EXTRACT ALL YESTERDAY'S TWEETS, ADD IT TO THE FULL LIST

# 1. Loading the required R libraries

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

# 2. Function for the extraction of Twitter content, which adds new
# account's tweets if not yet present in the dataset

get_all_twitter_tweets <- function(accounts, start_date, end_date, dir_name, upper_limit, token) {

	# We have to create a desired directory, if one does not yet exist
	if (!dir.exists(dir_name)) {
		dir.create(dir_name)
	} else {
		print("Output directory already exists")
	}

  if (file.exists(paste0(dir_name, "/all_data_twitter.rds"))) {

    print("Data file with accounts' tweets already exists, loading it to memory")

    #Remove any NAs
    accounts <- accounts[!is.na(accounts)] # Vector with twitter usernames

    existing_tweets_dataset <- readRDS(paste0(dir_name, "/all_data_twitter.rds"))

    print("Dataset contains the following tweets")

    print(table(existing_tweets_dataset$user_name))

    # Using existing twitter dataset, filter out usernames that are already present in it

    accounts <- accounts[!accounts %in% existing_tweets_dataset$user_username]

    if (length(accounts) == 0) { stop("There are no new accounts to add to the dataset, will not extract data.", call. = FALSE) }

    # This function calls the Twitter API and saves the output to JSON
    get_all_tweets(users = accounts,
                   start_tweets = start_date,
                   end_tweets = end_date,
                   is_retweet = NULL,
                   data_path = paste0(dir_name, "/json/"),
                   export_query = FALSE,
                   bind_tweets = FALSE,
                   n = upper_limit,
                   bearer_token = token)

    # This function binds extracted JSONS to a "tidy" dataframe
    new_tweet_data <- bind_tweets(paste0(dir_name, "/json/"), output_format = NA, user = T)

    # Delete unneeded JSON repository
    unlink(paste0(dir_name, "/json/"), recursive = TRUE)

    # Append the existing dataset with new rows from yesterday and delete full duplicates
    all_data <- bind_rows(new_tweet_data, existing_tweets_dataset) %>% distinct()

    # Save to RDS
    saveRDS(object = all_data, file = paste0(dir_name, "/all_data_twitter.rds"), compress = TRUE)


  } else if (!file.exists(paste0(dir_name, "/all_data_twitter.rds"))) {

    print("Data file with accounts' tweets does not yet exist, new dataset will be created")

    # Remove any NAs
    accounts <- accounts[!is.na(accounts)] # Vector with twitter usernames

    # This function calls the Twitter API and saves the output to JSON
    get_all_tweets(users = accounts,
                           start_tweets = start_date,
                           end_tweets = end_date,
                           is_retweet = NULL,
                           # data_path = paste0(dir_name, "/json/"),
                           export_query = FALSE,
                           bind_tweets = TRUE,
                           n = upper_limit,
                           bearer_token = token)
    # This function binds extracted JSONS to a "tidy" dataframe
    all_data <- bind_tweets(paste0(dir_name, "/json/"), output_format = "tidy")

    # Delete unneeded JSON repository
    unlink(paste0(dir_name, "/json/"), recursive = TRUE)

    # Save to RDS
    saveRDS(object = all_data, file = paste0(dir_name, "/all_data_twitter.rds"), compress = TRUE)

}

}

# 3. Running the function
get_all_twitter_tweets(accounts = readRDS("1.data_sources/twitter/twitter_acc_ids.rds"),
                      start_date = "2015-01-01T00:00:00Z",
                      end_date = paste0(format(Sys.Date(), format = "%Y-%m-%d"), "T00:00:00Z"),
                      dir_name = "1.data_sources/twitter/data",
                      upper_limit = Inf,
                      token = Sys.getenv("TWITTER_TOKEN"))
