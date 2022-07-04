library(doc2vec)
library(tidyr)
library(dplyr)
library(stringr)
library(purrr)
library(wordcloud)

udpipe_processed_df <- list.files(path = "2.data_transformations/media_articles/data/udpipe_processed/chunks/", pattern = "*.rds", full.names = TRUE) %>%
  .[25:35] %>%
  map_dfr(readRDS)

txt <- udpipe_processed_df %>%
  filter(upos %in% c("VERB", "NOUN", "ADJ", "PROPN")) %>%
  # head(10000) %>%
  mutate(word = tolower(str_replace_na(lemma, replacement = ""))) %>% # Select token or lemma for different results
  group_by(doc_id) %>%
  summarize(text = str_squish(str_c(word, collapse = " "))) %>%
  ungroup()

# Fit model
model <- paragraph2vec(x = txt, type = "PV-DBOW", dim = 50, iter = 20,
                       min_count = 5, lr = 0.05, threads = 11)

# Get the embedding of the documents or words and get the vocabulary
embedding <- as.matrix(model, which = "words")
embedding <- as.matrix(model, which = "docs")
vocab <- summary(model, which = "docs")
vocab <- summary(model, which = "words")

documents_of_interest <- "2015E275E034" # could be a vector of multiple elements

results <- predict(model, newdata = documents_of_interest, type = "nearest", which = "doc2doc", top_n = 5)

most_similar_documents <- results[[1]][["term2"]]
txt[txt$doc_id %in% most_similar_documents, "text"] # Full text of the most similar doc

summary(model, which = "docs")

# TOP2VEC
# library(doc2vec)
# library(word2vec)
# library(uwot)
# library(dbscan)
# data(be_parliament_2020, package = "doc2vec")
# x      <- data.frame(doc_id = be_parliament_2020$doc_id,
#                      text   = be_parliament_2020$text_nl,
#                      stringsAsFactors = FALSE)
# x$text <- txt_clean_word2vec(x$text)
# x      <- subset(x, txt_count_words(text) < 1000)
#
# d2v    <- paragraph2vec(x, type = "PV-DBOW", dim = 50,
#                         lr = 0.05, iter = 10,
#                         window = 15, hs = TRUE, negative = 0,
#                         sample = 0.00001, min_count = 5,
#                         threads = 1)
# model  <- top2vec(d2v,
#                   control.dbscan = list(minPts = 50),
#                   control.umap = list(n_neighbors = 15L, n_components = 3), umap = tumap,
#                   trace = TRUE)
# info   <- summary(model, top_n = 7)
# info$topwords
