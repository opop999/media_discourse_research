## WE CAN GET TWITTER FOLLOWERS OF SPECIFIED ACCOUNTS WITH THIS SCRIPT

## 1. Loading the required R libraries

# Package names
packages <- c("rtweet")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# Specify functions
get_twitter_followers <- function(twitter_accounts, dir_name) {

  # Using rtweet library and older v1.1 endpoint
  # Check rate limit for this API and authenticate
  rate_limit()

# We have to create a desired directory, if one does not yet exist
  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }


  if (file.exists(paste0(dir_name, "/user_followers_data.rds"))) {

    print("Data file with twitter followers already exists, loading it to memory")

    #Remove any NAs
    twitter_accounts <- twitter_accounts[!is.na(twitter_accounts)] # Vector with twitter usernames

    twitter_followers <- readRDS(paste0(dir_name, "/user_followers_data.rds"))

    # From twitter_accounts, select only those that are not already present in the list

    twitter_accounts <- twitter_accounts[!twitter_accounts %in% names(twitter_followers)]

    for (i in seq_along(twitter_accounts)) {
      print(paste("START Twitter account", as.character(i), "/", length(twitter_accounts),  ":", as.character(twitter_accounts[[i]])))

      lookup_twitter_account <- lookup_users(twitter_accounts[[i]])

      print(paste("Account", as.character(twitter_accounts[[i]]), "has", as.character(lookup_twitter_account$followers_count), "followers"))

      twitter_followers[twitter_accounts[[i]]] <- get_followers(user = twitter_accounts[[i]],
                                                                retryonratelimit = TRUE,
                                                                n = lookup_twitter_account$followers_count)

      print(paste("FINISHED & SAVING Twitter account", as.character(i), "/", length(twitter_accounts), ":", as.character(twitter_accounts[[i]])))

      # Save list as an RDS object
      saveRDS(twitter_followers, file = paste0(dir_name, "/user_followers_data.rds"), compress = TRUE)

    }


  } else if (!file.exists(paste0(dir_name, "/user_followers_data.rds"))) {
    #Remove any NAs
    twitter_accounts <- twitter_accounts[!is.na(twitter_accounts)]

    # Initiate empty list
    twitter_followers <- vector(mode = "list", length = length(twitter_accounts))

    # twitter_followers <- vector(mode = "list", length = length(twitter_accounts)) # Pre-allocate list of size x
    # names(twitter_followers) <- twitter_accounts

    for (i in seq_along(twitter_accounts)) {
      print(paste("START Twitter account", as.character(i), "/", length(twitter_accounts), ":", as.character(twitter_accounts[[i]])))

      lookup_twitter_account <- lookup_users(twitter_accounts[[i]])

      print(paste("Account", as.character(twitter_accounts[[i]]), "has", as.character(lookup_twitter_account$followers_count), "followers"))

      twitter_followers[twitter_accounts[[i]]] <- get_followers(user = twitter_accounts[[i]],
                                                                retryonratelimit = TRUE,
                                                                n = lookup_twitter_account$followers_count)

      print(paste("FINISHED & SAVING Twitter account", as.character(i), "/", length(twitter_accounts), ":", as.character(twitter_accounts[[i]])))

      # Save list as an RDS object
      saveRDS(twitter_followers, file = paste0(dir_name, "/user_followers_data.rds"), compress = TRUE)

    }
  }

}

# Specify function inputs
twitter_accounts <- readRDS("1.data_sources/twitter/twitter_acc_ids.rds") # Vector with twitter usernames
dir_name <- "1.data_sources/twitter/data"

# Run function
get_twitter_followers(twitter_accounts = twitter_accounts, dir_name = dir_name)

