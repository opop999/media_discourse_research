# Work in progress. Exploration of tweet counts regarding migration over time.

library(arrow)
library(dplyr)
library(ggplot2)
library(plotly)
library(tidyr)

# # All Tweets with the search string
# all_migration_tweets <- read_feather("1.data_sources/twitter/data/all_migration_tweets_by_date_no_filter.feather")

# Only tweets tagged as in czech language
tweets_czech <- read_feather("1.data_sources/twitter/data/all_migration_tweets_by_date_filter_language.feather")

# # Only tweets tagged with Czech place of origin
# all_migration_tweets_czechia <- read_feather("1.data_sources/twitter/data/all_migration_tweets_by_date_filter_country.feather")

# Load all media tweets regarding migration
tweets_czech_media <- readRDS("2.data_transformations/data/tweets_with_regex_match.rds")


# all_migration_tweets_summary <- all_migration_tweets %>%
#   mutate(
#     week = as.Date(cut(as.Date(end), breaks = "week", start.on.monday = TRUE))
#   ) %>%
#   arrange(week) %>%
#   group_by(week) %>%
#   summarise(weekly_tweets = tweet_count) %>%
#   ungroup()

tweets_summary_czech <- tweets_czech %>%
  mutate(
    week = as.Date(cut(as.Date(end), breaks = "week", start.on.monday = TRUE))
  ) %>%
  arrange(week) %>%
  group_by(week) %>%
  summarise(weekly_tweets = sum(tweet_count)) %>%
  ungroup()


tweets_summary_czech_media <- tweets_czech_media %>%
  mutate(
    date = format(as.Date(created_at), format = "%Y-%m-%d"),
    week = as.Date(cut(as.Date(date), breaks = "week", start.on.monday = TRUE))
  ) %>%
  count(week) %>%
  ungroup() %>%
  rename(weekly_tweets = n)

# all_migration_tweets_summary_czechia <- all_migration_tweets_czechia %>%
#   mutate(
#     week = as.Date(cut(as.Date(end), breaks = "week", start.on.monday = TRUE))
#   ) %>%
#   arrange(week) %>%
#   group_by(week) %>%
#   summarise(weekly_tweets = sum(tweet_count)) %>%
#   ungroup()


# merged_dataset <- inner_join(all_migration_tweets_summary, all_migration_tweets_summary_czech, by = "week", suffix = c("_all", "_czech_lang")) %>%
#   inner_join(all_migration_tweets_summary_czechia, by = "week") %>%
#   rename(weekly_tweets_czech_geo = weekly_tweets) %>%
#   pivot_longer(values_to = "end_of_week_tweets", names_to = "source", cols = c("weekly_tweets_all", "weekly_tweets_czech_lang", "weekly_tweets_czech_geo"))

merge_media_with_all_tweets <- inner_join(tweets_summary_czech, tweets_summary_czech_media, by = "week", suffix = c("_all", "_media")) %>%
  pivot_longer(values_to = "end_of_week_tweets", names_to = "source", cols = c("weekly_tweets_all", "weekly_tweets_media"))

interactive_graph <- (ggplot(merge_media_with_all_tweets, aes(x = week, y = end_of_week_tweets, color = source)) +
    geom_line() +
    scale_x_date(date_breaks = "1 years") +
    scale_y_continuous(
      breaks = seq(0, 5000, 100),
      labels = seq(0, 5000, 100)
    ) +
    theme_minimal() +
    ylab("Total Weekly Tweets") +
    xlab(element_blank()) +
    labs(color = "Origin of Tweets") +
    ggtitle(paste("Tweets on Czech Twitter related to migration, since 1 January 2015"))) %>%
  ggplotly()


htmlwidgets::saveWidget(interactive_graph, file = "3.data_EDA/data/plot_over_time_twitter.html")
