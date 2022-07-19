library(tidyverse)
library(tidytext)
library(topicmodels)
library(tm)
library(jsonlite)
library(udpipe)
library(data.table)
library(SnowballC)
library(text2vec)

# Create Document-Term Matrix using TF weighting
sparse_dtm <- titles_tidy %>% cast_dtm(document, word, n, weighting = tm::weightTf)

# Optionally, make matrix less sparse
less_sparse_matrix <- removeSparseTerms(sparse_dtm, sparse = 0.999)

# Fit LDA model with k number of topics
chapters_lda <- LDA(sparse_dtm, k = 10, control = list(seed = 3859))

ap_topics <- tidy(chapters_lda, matrix = "beta")

ap_top_terms <- ap_topics %>% group_by(topic) %>%
  slice_max(beta, n = 10) %>%
  ungroup() %>%
  arrange(topic, -beta)

ap_top_terms %>%
  mutate(term = reorder_within(term, beta, topic)) %>%
  ggplot(aes(beta, term, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  scale_y_reordered()

# What words have the greatest impact
beta_wide <- ap_topics %>%
  mutate(topic = paste0("topic", topic)) %>%
  pivot_wider(names_from = topic, values_from = beta) %>%
  filter(topic1 > .001 | topic2 > .001) %>%
  mutate(log_ratio = log2(topic2 / topic1))

beta_wide

ap_documents <- tidy(chapters_lda, matrix = "gamma")
ap_documents

# using text2vec approach

# tokens = tolower(annotated_articles_subset$title)
# tokens = word_tokenizer(tokens)

it = itoken(titles_tidy$word, ids = titles_tidy$document, progressbar = TRUE)
v = create_vocabulary(it)
v = prune_vocabulary(v, term_count_min = 10, doc_proportion_max = 0.2)

vectorizer = vocab_vectorizer(v)
dtm = create_dtm(it, vectorizer, type = "dgTMatrix")

lda_model = LDA$new(n_topics = 5, doc_topic_prior = 0.1, topic_word_prior = 0.01)
doc_topic_distr = lda_model$fit_transform(x = dtm, n_iter = 1000,
                                          convergence_tol = 0.001, n_check_convergence = 25,
                                          progressbar = TRUE)

lda_model$get_top_words(n = 10, lambda = 0.4)


#####
#####
library(text2map)
library(stringr)
# library(tm)
library(data.table)
library(dtplyr)
library(dplyr, warn.conflicts = FALSE)
# library(topicmodels)


upos_filter <- c("NOUN", "PROPN")

test <- lazy_dt(test)

test <- test %>%
  filter(upos %in% upos_filter) %>%
  mutate(word = tolower(str_replace_na(lemma, replacement = ""))) %>%
  group_by(doc_id) %>%
  summarize(text = str_squish(str_c(word, collapse = " "))) %>%
  ungroup() %>%
  as_tibble()


dtm_udpipe <- dtm_builder(data = test, text = "text", doc_id = "doc_id")
dtm_stats(dtm_udpipe)

dtm_less_sparse <- dtm_stopper(dtm_udpipe,
                               stop_termfreq = c(2, Inf),
                               stop_docfreq = c(10, Inf))
dtm_stats(dtm_less_sparse)


# test_lda <- LDA(dtm_less_sparse, k = 10, control = list(seed = 3859))

# Calculation of metrics for k topics
library(ldatuning)

result <- FindTopicsNumber(dtm_less_sparse,
                           mc.cores = parallel::detectCores() - 1)
FindTopicsNumber_plot(result)


library(text2vec)

set.seed(3859L)
lda_model <- LDA$new(
  n_topics = 10
)

doc_topic_distr <-
  lda_model$fit_transform(
    x = dtm_less_sparse,
    n_iter = 1000,
    convergence_tol = 0.001,
    n_check_convergence = 10
  )

library(LDAvis)
lda_model$plot()
