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

# Define a function for getting the GDELT dataset for selected coutry
get_gdelt_data <- function(dir_name, sql_query, billing) {

  bq_auth() # Interactive authentication through Google account

  # A temporary table is created remotely in Google Cloud
  dataset_google_ads_remote <- bq_project_query(x = billing, query = sql_query)

  # The resulting GDELT dataset could be large (>50 GB).
  # The result of the query can be saved remotely to a selected bucket - but beware of billing costs by google
  # bq_table_save(x = dataset_google_ads_remote, destination_uris = "gs://[YOUR_BUCKET]/file-name-*.json")

  # For the rest, use the googleCloudStorageR package or the GUI of the Google Cloud console

}


get_gdelt_data(dir_name = "1. data_sources/complementary/gdelt/data",
               sql_query = "SELECT * FROM `gdelt-bq.gdeltv2.gkg` WHERE SourceCommonName LIKE '%.cz';", # or "LIKE '%.se';" for Swedish sources
               billing = bq_test_project()) # Set first the project ID in the BIGQUERY_TEST_PROJECT env variable using Sys.setenv() or in the .Renviron file in the repository root)
