library(quanteda)
library(tidyr)
library(dplyr)
library(stringr)
library(purrr)
library(lexRankr)

udpipe_processed_df <- list.files(path = "2.data_transformations/media_articles/data/udpipe_processed/chunks/",
                                  pattern = "*.rds",
                                  full.names = TRUE) %>%
  .[25] %>%
  map_dfr(readRDS)

txt <- udpipe_processed_df %>%
  filter(upos %in% c("VERB", "NOUN")) %>%
  head(5000) %>%
  mutate(word = tolower(str_replace_na(token, replacement = ""))) %>% # Select token or lemma for different results
  group_by(doc_id, sentence_id) %>%
  summarize(tokenized_text = str_squish(str_c(word, collapse = " "))) %>%
  ungroup()

top_sentence_per_document <- txt %>%
  bind_lexrank(tokenized_text, doc_id, level = "sentences") %>%
  group_by(doc_id) %>%
  slice_max(lexrank, n = 1) %>%
  arrange(desc(lexrank))
