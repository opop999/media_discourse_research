# THIS VERSION OF THE SCRIPT IS CAPABLE OF EXTRACTING
# UNLIMITED AMOUNT OF FB PAGES, WHOSE IDs WE HAVE TO
# SPECIFY IN A "PARTIES" LIST

# PART 1: LOAD THE REQUIRED LIBRARIES FOR THIS SCRIPT

# Specify the package names we will be using.
packages <- c("dplyr", "tidyr", "remotes")

# Install packages not yet installed.
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading.
invisible(lapply(packages, library, character.only = TRUE))


# We have to install the Radlibrary package, which is available only on GitHub
# To install Radlibrary, we need to use install_github function from a lightweight
# remotes package. We also specify argument "upgrade" to never, so we do not get
# a dialog window asking us whether to update when the script runs automatically.

remotes::install_github("facebookresearch/Radlibrary", upgrade = "never", dependencies = TRUE)

library(Radlibrary)

# Disable scientific notation of numbers.
options(scipen = 999)

# PART 2: DEFINE THE FUNCTION THAT WILL EXTRACT, MERGE AND SAVE FB ADS DATASETS

############################### FUNCTION BEGGINING #############################

get_all_tables_merge <- function(token, account_ids, min_date, max_date, dir_name = "data", old_df = NA, new_df = "merged_dataset.rds") {

  if (nchar(token) < 50) { stop("Token is missing or misspecified.") }

  if (!is.character(account_ids) | !is.vector(account_ids) | all(nchar(account_ids) < 1)) { stop("Account IDs not provided as a character vector or empty.") }

  # A. SPECIFICATION PART OF THE FUNCTION
  # We need to specify the arguments we want to supply the Radlibrary functions

  #Remove any NAs from the vector of usernames
  account_ids <- account_ids[!is.na(account_ids)]

  if (!is.na(old_df)) {
    existing_fb_dataset <- readRDS(paste0(dir_name, old_df))

    existing_fb_dataset_usernames <- existing_fb_dataset[c("page_id", "page_name")]

    print("Dataset contains the following FB ADS")

    print(table(existing_fb_dataset_usernames$page_name))

    # Using existing dataset, filter out usernames that are already present in it.
    account_ids <- account_ids[!account_ids %in% existing_fb_dataset_usernames$page_id]
  }


  if (length(account_ids) == 0) { stop("There are no new accounts to add to the dataset, will not extract data.") }

  fields_vector <- c("ad_data", "region_data", "demographic_data")
  table_type_vector <- c("ad", "region", "demographic")

  # We initialize empty list to which we will add data
  fb_ad_list <- vector(mode = "list", length = length(fields_vector))

  # We will also name its three items with values from table_type_vector so we can
  # refer to them further
  names(fb_ad_list) <- table_type_vector

  # We have to create a desired directory, if one does not yet exist
  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }

  # B. EXTRACTION PART OF THE FUNCTION

  # We will be using 2 nested for loops for extraction
  # The outer for loop cycles over the list of parties
  # The inner for loop gets us the 3 distinct types of tables from the FB Ads.

  for (p in seq_along(account_ids)) {
    print(paste("outer_loop", p))

    for (i in seq_along(fields_vector)) {
      print(paste("inner_loop", i))

      # Building the query
      query <- adlib_build_query(
        ad_reached_countries = "CZ",
        ad_active_status = "ALL",
        ad_delivery_date_max = max_date,
        ad_delivery_date_min = min_date,
        ad_type = "POLITICAL_AND_ISSUE_ADS",
        publisher_platform = c("FACEBOOK", "INSTAGRAM", "AUDIENCE_NETWORK", "MESSENGER", "WHATSAPP"),
        limit = 1000,
        search_page_ids = account_ids[[p]],
        fields = fields_vector[i]
      )

      # The call is limited to 1000 results but pagination of overcomes it.
      # We pipe the output of the paginated call to the as_tibble function.
      fb_ad_list[[table_type_vector[i]]][[p]] <- adlib_get_paginated(query,
                                                                token = token,
                                                                max_gets = 200
      ) %>%
        as_tibble(
          type = table_type_vector[i],
          censor_access_token = TRUE
        )

    }
  }

  # # Transform lists into dataframes
  # dataset_ad <- bind_rows(ad_list)
  # dataset_region <- bind_rows(region_list)
  # dataset_demographic <- bind_rows(demographic_list)

  # C. MERGE PART OF THE FUNCTION
  # After extraction of the three tables through the for loop, we transform
  # and merge into one. The demographic & region datasets are in the "long"
  # format and we need a transformation to a "wide" format of the ad dataset


  fb_ad_list[["demographic"]] <- fb_ad_list[["demographic"]] %>%
    bind_rows() %>%
    mutate(percentage = round(percentage, 3)) %>%
    pivot_wider(
      id_cols = adlib_id,
      names_from = c("gender", "age"),
      names_sort = TRUE,
      values_from = percentage
    )

  fb_ad_list[["region"]] <- fb_ad_list[["region"]] %>%
    bind_rows() %>%
    mutate(percentage = round(percentage, 3)) %>%
    pivot_wider(
      id_cols = adlib_id,
      names_from = region,
      names_sort = TRUE,
      values_from = percentage
    )

  # Performing a left join on the common id column across the 3 datasets, remove
  # full duplicates and arrange by date.
  merged_dataset <- fb_ad_list[["ad"]] %>%
    bind_rows() %>%
    left_join(fb_ad_list[["demographic"]], by = "adlib_id") %>%
    left_join(fb_ad_list[["region"]], by = "adlib_id") %>%
    distinct() %>%
    arrange(desc(ad_creation_time))

  # We save the merged dataset in the rds format
  # Rds enables faster reading when using the dataset in R for further analyses
  # We turn off compression for rds files (optional). Their size is larger, but
  # the advantage are a magnitude faster read/write times using R.

  # If we specify the old dataset, we can append the new data here.
  if (!is.na(old_df)) {
    merged_dataset <- bind_rows(existing_fb_dataset, merged_dataset) %>% distinct()
  }

  saveRDS(object = merged_dataset, file = paste0(dir_name, new_df), compress = FALSE)

}

############################### FUNCTION END ###################################



# PART 3: RUNNING THE FUNCTION WITH APPROPRIATE ARGUMENTS
get_all_tables_merge(
  token = Sys.getenv("FB_TOKEN"),
  account_ids = readRDS("1.data_sources/facebook/facebook_ads/num_facebook_acc_ids.rds"),
  min_date = "2020-05-07",
  max_date = format((Sys.Date()), "%Y-%m-%d"),
  dir_name = "1.data_sources/facebook/facebook_ads/data/",
  old_df = "merged_fb_ads_data.rds",
  new_df = "merged_fb_ads_data.rds"
)
