# PROJECT: Using Google Trends to measure popularity of Czech political actors

# The resulting data should be treated with caution as to the
# interpretations of the popularity of given political actors.
# We should assume the existence of a sampling bias, as the Google search user-base
# will not likely be representative of the general Czech population.

# Ideally, this should be accompanied by other data sources, such as term
# searches on Seznam.cz, however, this platform do not easy programmatic access.

# PART 1: LOAD THE REQUIRED R LIBRARIES

# Package names
packages <- c("dplyr", "gtrendsR", "data.table", "arrow", "stringr", "tidyr")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))


# PART 2: DEFINE THE FUNCTION THAT WILL EXTRACT AND SAVE GOOGLE TRENDS

extract_gtrends <- function(search_terms, start_date, end_date, dir_name) {

  # We have to create a desired directory, if one does not yet exist
  if (!dir.exists(dir_name)) {
    dir.create(dir_name)
  } else {
    print("Output directory already exists")
  }

  # We initialize empty dataset to which we add rows with each loop iteration
  gtrends_list <- list()
  related_topics_list <- list()

  # To get every item from the list, we need to use for loop
  for (i in seq_along(search_terms)) {

    # Formulate the Google Trends query using function from the gtrendsR package
    gtrends_query <- gtrends(
      keyword = search_terms[[i]],
      geo = "CZ",
      time = paste(start_date, end_date),
      gprop = "web",
      category = 0,
      hl = "cs",
      low_search_volume = TRUE,
      cookie_url = "http://trends.google.com/Cookies/NID",
      tz = 0,
      onlyInterest = FALSE
    )

if (!is.null(gtrends_query$interest_over_time)) {
    gtrends_list[[i]] <- gtrends_query$interest_over_time %>%
      transmute(
        date = date,
        term_name = keyword,
        hits = as.integer(str_replace_all(hits, "<.*", "0")),
      ) %>%
      arrange(desc(date))
}

    if (!is.null(gtrends_query$related_topics)) {
    related_topics_list[[i]] <- gtrends_query$related_topics %>%
      filter(related_topics == "top") %>%
      transmute(
        term_name = keyword,
        related_keyword = value,
        popularity = as.integer(subject)
      )
    }
  }

  gtrends_df <- bind_rows(gtrends_list)
  related_topics_df <- bind_rows(related_topics_list)

  # Clean the downloaded dataset, select only appropriate columns
  gtrends_df_clean <- gtrends_df %>%
    mutate(
      term_name = as.factor(term_name),
      term_id = as.integer(term_name)
    ) %>%
    arrange(desc(date))

  related_topics_df_clean <- related_topics_df %>%
    mutate(
      term_name = as.factor(term_name),
      term_id = as.integer(term_name)
    ) %>%
    arrange(desc(popularity))

  # We save the cleaned tables in a memory to a dedicated csv and rds file
  # Rds enables faster reading when using the dataset in R for further analyses
  # We turn off compression for rds files (optional). Their size is larger, but
  # the advantage are a magnitude faster read/write times using R.

  fwrite(x = gtrends_df_clean, file = paste0(dir_name, "/full_data_gtrends.csv"))
  saveRDS(object = gtrends_df_clean, file = paste0(dir_name, "/full_data_gtrends.rds"), compress = FALSE)
  write_feather(x = gtrends_df_clean, sink = paste0(dir_name, "/full_data_gtrends.feather"))

  fwrite(x = related_topics_df_clean, file = paste0(dir_name, "/full_data_gtrends_related_topics.csv"))
  saveRDS(object = related_topics_df_clean, file = paste0(dir_name, "/full_data_gtrends_related_topics.rds"), compress = FALSE)
  write_feather(x = related_topics_df_clean, sink = paste0(dir_name, "/full_data_gtrends_related_topics.feather"))

}


## PART 3: SPECIFY INPUTS FOR THE WIKIPEDIA EXTRACTION FUNCTION
start_date <- as.Date("2015-01-01")

end_date <- Sys.Date()

search_terms <- c("migrace", # Migration flows keywords
                  "imigrace",
                  "uprchlictví",
                  "přistěhovalectví",
                  "emigrace", # Terms for humans
                  "migrant",
                  "migrantka",
                  "migrantky",
                  "migranti",
                  "imigrant",
                  "imigrantka",
                  "imigranti",
                  "imigrantky",
                  "uprchlík",
                  "uprchlice",
                  "uprchlíci",
                  "běženec",
                  "běženka",
                  "běženky",
                  "běženci",
                  "přistěhovalec",
                  "přistěhovalkyně",
                  "přistěhovalci",
                  "emigrant",
                  "emigrantka",
                  "emigrantky",
                  "emigranti",
                  "azylant",
                  "azylantka",
                  "azylantky",
                  "azylanti",
                  "utečenec",
                  "utečenka",
                  "utečenci",
                  "utečenky")

# Specify output directory
dir_name <- "1.data_sources/complementary/contextual_datasets/migration_saliency/data/"

# PART 4: RUNNING THE FUNCTION WITH APPROPRIATE ARGUMENTS
extract_gtrends(
  search_terms = search_terms,
  start_date = start_date,
  end_date = end_date,
  dir_name = dir_name
)
