# PROJECT: Using Wikipedia API to measure the saliency of the so-called refugee crisis on Czech internet

# This means that the resulting data should be treated with caution as to the
# interpretations of the popularity of given political actors.
# We should assume an existence of a sampling bias, as the Wikipedia readership
# will not likely be representative of the general Czech population.

# Ideally, this should be accompanied by other data sources, such as term
# searches on Seznam.cz, however, these platforms do not
# provide free and open official APIs like Wikimedia.

# PART 1: LOAD THE REQUIRED R LIBRARIES

# Package names
packages <- c("dplyr", "pageviews", "data.table", "arrow")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# PART 2: DEFINE THE FUNCTION THAT WILL EXTRACT AND SAVE WIKI DATASETS

extract_wikipedia <- function(article_ids, start_date, end_date, precision, dir_name) {

  # We have to create a desired directory, if one does not yet exist
  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }

  # Function article_pageviews from the "pageviews" package
  full_dataset <- article_pageviews(
    project = "cs.wikipedia",
    article = article_ids,
    platform = "all",
    user_type = "user", # Filter only for "human" users, excluding bots
    start = pageview_timestamps(start_date, first = TRUE),
    end = pageview_timestamps(end_date, first = TRUE),
    reformat = TRUE,
    granularity = precision
  )

  # Clean the downloaded dataset, select only appropriate columns
  clean_dataset <- full_dataset %>%
    transmute(
      date = date,
      entity_name = as.factor(article),
      entity_id = as.numeric(entity_name),
      views = views
    ) %>%
    arrange(desc(date))

  # We save the cleaned tables in a memory to a dedicated csv and rds file
  # Rds enables faster reading when using the dataset in R for further analyses
  # We turn off compression for rds files (optional). Their size is larger, but
  # the advantage are a magnitude faster read/write times using R.

  fwrite(x = clean_dataset, file = paste0(dir_name, "/full_data_wiki.csv"))
  saveRDS(object = clean_dataset, file = paste0(dir_name, "/full_data_wiki.rds"), compress = FALSE)
  write_feather(x = clean_dataset, sink = paste0(dir_name, "/full_data_wiki.feather"))
}

## PART 3: SPECIFY INPUTS FOR THE WIKIPEDIA EXTRACTION FUNCTION
# The Wikipedia API goes back up to mid 2015
start_date <- as.Date("2015-01-01")

end_date <- Sys.Date()

article_ids <- "Evropská_migrační_krize"

precision <- "daily" # The granularity of data returned. Can be monthly/daily

# Specify output directory
dir_name <- "1.data_sources/complementary/contextual_datasets/migration_saliency/data"

# PART 4: RUNNING THE FUNCTION WITH APPROPRIATE ARGUMENTS
extract_wikipedia(
  article_ids = article_ids,
  start_date = start_date,
  end_date = end_date,
  precision = precision,
  dir_name = dir_name
)
