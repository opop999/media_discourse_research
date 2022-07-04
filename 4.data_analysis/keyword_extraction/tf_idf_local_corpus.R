library(httr)
library(jsonlite)
library(dplyr)
library(data.table)
library(tidytext)
library(ggplot2)
library(forcats)
library(purrr)
library(stringr)

# full_articles_subset <- readRDS("2.data_transformations/data/full_articles_subset.rds")
# full_articles_subset$Content <- gsub(pattern = "  +",
#                                      replacement = " ",
#                                      x = gsub(pattern = "<(.|\n)*?>|[^ěščřžýáíéóúůďťňĎŇŤŠČŘŽÝÁÍÉÚŮĚÓa-zA-Z,\\.{1}\\!{1}\\?{1} ]", # Dot removal for ellipsis
#                                               replacement = " ",
#                                               x = full_articles_subset$Content))
# Consider (), ?, !

udpipe_processed_df <- list.files(path = "2.data_transformations/media_articles/data/udpipe_processed/chunks/",
                                  pattern = "*.rds",
                                  full.names = TRUE) %>%
  .[grepl("(2015-(10))", .)] %>% # "(2015-(10|11|12))|(2022-(02|03|04))"
  map_dfr(readRDS)

txt <- udpipe_processed_df %>%
  filter(upos %in% c("VERB", "NOUN", "ADJ", "PROPN")) %>%
  mutate(word = tolower(str_replace_na(lemma, replacement = "")))

corpus_words <- txt %>%
  # unnest_tokens(word, text_lemma) %>%
  count(doc_id, word, sort = TRUE)

total_words <- corpus_words %>%
  group_by(doc_id) %>%
  summarize(total = sum(n))

corpus_words <- left_join(corpus_words, total_words, by = "doc_id")

corpus_tf_idf <- corpus_words %>%
  bind_tf_idf(word, doc_id, n) %>%
  slice_max(tf_idf, n = 100) %>%
  arrange(desc(tf_idf))

# KW visualization: Work in progress
corpus_tf_idf %>%
  group_by(doc_id) %>%
  slice_max(tf_idf, n = 1) %>%
  ungroup() %>%
  ggplot(aes(tf_idf, fct_reorder(word, tf_idf), fill = doc_id)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~doc_id, ncol = 2, scales = "free") +
  labs(x = "tf-idf", y = NULL)
