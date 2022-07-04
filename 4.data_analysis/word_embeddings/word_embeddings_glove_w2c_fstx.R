library(jsonlite)
library(dplyr)
library(text2vec)
library(tm)
library(purrr)
library(word2vec)
library(fastTextR)
library(stringr)

# Important to lowercase, remove punctuation and undesirable PoS/StopWords
# stw <- fromJSON("2.data_transformations/media_articles/data/irene_stopwords.json")
# stw_2 <- fromJSON("2.data_transformations/media_articles/data/stopwords_cs.json")
# txt <- readRDS("~/Media_discourse_research/2.data_transformations/media_articles/data/df_chunks/non_processed/cs_chunk_1.rds")[,2] %>%
#   tolower() %>%
#   removePunctuation() %>%
#   removeNumbers() %>%
#   stripWhitespace() %>%
#   removeWords(words = unique(c(stw, stw_2)))

# tokens <- lapply(tokens, function(x) { return( tolower(x[!x %in% c(stw, stw_2)])) })


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

# For wang2vec cli interface
writeLines(txt$text, "4.data_analysis/word_embedding/data/test_corp.txt")


# Embeddings using GLOVE http://text2vec.org/glove.html

# Create iterator over tokens
tokens = space_tokenizer(txt$text)

# Create vocabulary. Terms will be unigrams (simple words).
it = itoken(tokens)
vocab = create_vocabulary(it)
vocab = prune_vocabulary(vocab, term_count_min = 3L)

# Use our filtered vocabulary
vectorizer = vocab_vectorizer(vocab)
# use window of 5 for context words
tcm = create_tcm(it, vectorizer, skip_grams_window = 5L)

glove = GlobalVectors$new(rank = 50, x_max = 10)
wv_main = glove$fit_transform(tcm, n_iter = 20, convergence_tol = 0.01)
wv_context = glove$components
word_vectors = wv_main + t(wv_context)

sim2(x = word_vectors, y = word_vectors[c("syřan"), , drop = FALSE], method = "cosine", norm = "l2")[,1] %>%
  sort(decreasing = TRUE) %>%
  head(10)

# Word2Vec variations

# model trained with Wang2Vec C library
model_2 <- read.word2vec("4.data_analysis/word_embedding/w2v_embeddings", normalize = TRUE)
predict(model_2, c("migrant"), type = "nearest", top_n = 10)

sim2(x = word_vectors, y = word_vectors["uprchlík", , drop = FALSE], method = "cosine", norm = "l2")[,1] %>%
  sort(decreasing = TRUE) %>%
  head(10)

# Import media labels
media_labels <- readRDS("1.data_sources/media_articles/data/media_type_labels/all_media_labels_with_doc_id.rds")

# Example: create two models for 2015 - one for mainstream and other for antisystemic
model_mainstream <- txt %>%
  filter(doc_id %in% media_labels$doc_id[media_labels$media_type == "mainstream"]) %>%
  pull(text) %>%
  word2vec(iter = 20, threads = 12L)

predict(model_mainstream, c("migrace", "imigrace", "uprchlík", "syřan"), type = "nearest", top_n = 10)

model_antisystem <- txt %>%
  filter(doc_id %in% media_labels$doc_id[media_labels$media_type == "antisystem"]) %>%
  pull(text) %>%
  word2vec(iter = 20, threads = 12L)

predict(model_antisystem, c("migrace", "imigrace", "uprchlík", "syřan"), type = "nearest", top_n = 10)


# Model trained using Python's library
model_fasttext <- fastTextR::ft_load("4.data_analysis/word_embedding/data/fasttext_model.bin")

ft_nearest_neighbors(model_fasttext, "uprchlík", k = 10L)
