library(jsonlite)
library(dplyr)
library(tidyr)
import_sentiment_json <- fromJSON("sentiment_dict.json") %>%
  bind_rows(.id = "article_id") %>%
  pivot_wider(names_from = "label", values_from = "score", names_sort = TRUE) %>%
  rename(negative_score = LABEL_0,
            neutral_score = LABEL_1,
            positive_score = LABEL_2) %>%
  mutate(label = names(.[2:4])[max.col(.[2:4], "first")])

