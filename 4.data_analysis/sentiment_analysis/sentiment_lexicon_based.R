library(dplyr)
library(readr)

cz_sent_lexicon <- read_delim("4.data_analysis/sentiment_analysis/data/sent_lex_sublex_1.csv",
                           "\t",
                           escape_double = FALSE,
                           col_names = c("negation", "pos", "lemma", "orientation", "en_source"),
                           trim_ws = TRUE,
                           col_types = c("ccccc")) %>%
                           transmute(lemma = gsub(x = lemma, pattern = "_.*|-.*", replacement = ""),
                                     word_sent = case_when(orientation == "POS" ~ 1,
                                                             orientation == "NEG" ~ -1))

sentiment_labelled_df <- lemmatized_df[, c("doc_id", "lemma")] %>%
  inner_join(cz_sent_lexicon, by = "lemma") %>%
  group_by(doc_id) %>%
  summarize(sentence_sent_sum = sum(word_sent)) %>%
  ungroup() %>%
  mutate(sentence_sent_simplified = case_when(
    sentence_sent_sum < 0 ~ "NEG",
    sentence_sent_sum == 0 ~ "NEUT",
    sentence_sent_sum > 0 ~ "POS"))



# tokens_sentiment_negative <- tokens_clean_lemma %>%
#   inner_join(sentiment_cz %>%
#                filter(sentiment == "NEG")) %>%
#   transmute(word, n) %>%
#   arrange(desc(n))
