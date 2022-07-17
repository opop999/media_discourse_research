## 1. Loading the required R libraries

# Package names
packages <- c("bigrquery")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# Define a function for getting the
get_google_political_ads <- function(dir_name, sql_query, billing) {

# Interactive authentication through Google account
bq_auth()

# A temporary table is created remotely in Google Cloud
dataset_google_ads_remote <- bq_project_query(x = billing, query = sql_query)

# Downloading the temporary table to a local dataset
dataset_google_ads_local <- bq_table_download(dataset_google_ads_remote)

# Alternatively, if the result of the query is large, it could be saved to a Google Cloud Storage
# bq_table_save(x = dataset_google_ads_remote, destination_uris = "gs://[YOUR_BUCKET]/file-name-*.json")

# Save full dataset in RDS
saveRDS(object = dataset_google_ads_local, file = paste0(dir_name, "/all_google_ads.rds"))

}

# Run the function with parameters
get_google_political_ads(dir_name = "1.data_sources/complementary/contextual_datasets/google_political_ads/data", # Specify the folder, where the tables will be saved
                         sql_query = "SELECT * FROM `bigquery-public-data.google_political_ads.creative_stats` WHERE regions IN ('CZ, EU', 'CZ', 'EU, CZ');",
                         billing = bq_test_project()) # Set first the project ID in the BIGQUERY_TEST_PROJECT env variable using Sys.setenv() or in the .Renviron file in the repository root
