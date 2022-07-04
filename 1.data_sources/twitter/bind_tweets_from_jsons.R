library(academictwitteR)

binded_tweets_df <- bind_tweets("1.data_sources/twitter/data/raw_json_data/", output_format = "tidy")

saveRDS("1.data_sources/twitter/data/binded_tweets.rds")
