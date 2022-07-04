library(dplyr)
library(stringr)
library(dtplyr)
library(data.table)

# Original Dataframe
full_twitter_df <- readRDS("1.data_sources/twitter/data/binded_tweets.rds")

# Count number of tweets by account
n_count_total <- full_twitter_df %>% count(user_username) %>% arrange(desc(n))

# Faster regex match using data.table library
test_regex <- as.data.table(full_twitter_df)[text %like% "(?i)(běženec\\w*)|(běženk\\w*)|(imigrant\\w*)|(migra\\w*)|(imigra\\w*)|(přistěhoval\\w*)|(uprchl\\w*)|(utečen\\w*)|(azylant\\w*)"]

# Extract Regex matches (if Simplify = TRUE, character matrix is the output, each word is in a separate column)
rgx_match <- full_twitter_df[["text"]] %>% str_extract_all(pattern = "(?i)(běženec\\w*)|(běženk\\w*)|(imigrant\\w*)|(migra\\w*)|(imigra\\w*)|(přistěhoval\\w*)|(uprchl\\w*)|(utečen\\w*)|(azylant\\w*)", simplify = TRUE)

# Bind the x-column matrix to the original dataframe
full_twitter_df_with_rgx <- bind_cols(full_twitter_df, as_tibble(rgx_match))

# Replace missing values with NA using apply
fix_missing <- function(x) {
  x[x == ""] <- NA
  return(x)
}

full_twitter_df_with_rgx[c("V1", "V2", "V3", "V4", "V5")] <- lapply(full_twitter_df_with_rgx[c("V1", "V2", "V3", "V4", "V5")], fix_missing)

# Filter the new df only for rows with matches, i.e. rows where at least one of the regex columns is not NA
full_twitter_df_with_rgx_subset <- full_twitter_df_with_rgx %>% filter(if_any(c(V1, V2, V3, V4, V5), ~ !is.na(.)))

saveRDS(full_twitter_df_with_rgx_subset, "2.data_transformations/data/tweets_with_regex_match.rds")

# Count number of tweets by account after filtering for migration content
n_count_subset <- full_twitter_df_with_rgx_subset %>% count(user_username) %>% arrange(desc(n))

joined_df_with_matches <- inner_join(n_count_total, n_count_subset, by = "user_username", suffix = c("_total", "_migration_filter")) %>%
  mutate(proportion_perc = n_migration_filter/n_total*100) %>%
  arrange(desc(proportion_perc))


# ALTERNATIVE WAY
# Extract Regex matches (if Simplify = FALSE, list is the output)
rgx_match <- full_twitter_df[["text"]] %>% str_extract_all(pattern = "(?i)(běženec\\w*)|(běženk\\w*)|(imigrant\\w*)|(migra\\w*)|(imigra\\w*)|(přistěhoval\\w*)|(uprchl\\w*)|(utečen\\w*)|(azylant\\w*)", simplify = FALSE)

# Preserve order, add NA to positions where no match
rgx_match_vector <- sapply(rgx_match, function(s) if (length(s) == 0) NA_character_ else paste(s, collapse = " "))

# Subset the original df with matches
df_with_matches <- binded_tweets[!is.na(rgx_match_vector),]
