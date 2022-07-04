library(data.table)
library(dplyr)
library(SnowballC)


annotated_subset <- data.table(readRDS("2.data_transformations/data/annotated_articles_subset.rds"))

# TEXT PRE-PROCESSING
# Removal of extra characters
set.seed(3859)
annotated_subset_sample <- annotated_subset[sample(.N, 50000), ][, text := paste(title, annotation)][, .(document = code, text)][, text := gsub(pattern = "<(.|\n)*?>|[^ěščřžýáíéóúůďťňĎŇŤŠČŘŽÝÁÍÉÚŮĚÓa-zA-Z, ]", replacement = "", x = text)]


# Alternatively, consider pattern like this: gsub(pattern = "  +", replacement = " ", x = gsub(pattern = "<(.|\n)*?>|[^ěščřžýáíéóúůďťňĎŇŤŠČŘŽÝÁÍÉÚŮĚÓa-zA-Z,\\.{1} ]", replacement = " ", x = full_articles_subset$Content))

# Load stopwords
# download.file("https://raw.githubusercontent.com/stopwords-iso/stopwords-cs/master/stopwords-cs.json", "2.data_transformations/data/stopwords_cs.json")
stopwords_cs <- data.table(word = jsonlite::read_json(path = "2.data_transformations/data/stopwords_cs.json", simplifyVector = TRUE))

# Unest tokens and apply stopwords
annotated_subset_sample_clean <- annotated_subset_sample %>%
  tidytext::unnest_tokens(output = word, input = text, to_lower = TRUE, token = "words")


annotated_subset_sample_clean_at <- annotated_subset_sample_clean %>%
  anti_join(stopwords_cs, by = "word") %>%
  mutate(word = wordStem(word)) %>%  #  %>% # Stemming alternative to lemmatization
  group_by(word) %>%
  filter(n() > 1) %>% # Filter out words appearing only once across all of the documents
  ungroup() %>%
  count(document, word, sort = TRUE)

# Data.table anti join
annotated_subset_sample_clean_at_2 <- annotated_subset_sample_clean[!stopwords_cs, on = .(word)][,word := wordStem(word)][, .I[.N > 1], list(word, document)][, V1 := NULL][, .N, by = list(word, document)]

# [, .N, by = word][N > 1][, N := NULL][]


# We can use the tokenization & lemmatization features of UDPIPE locally. We can input a dataset, but it needs to have "doc_id" and "text" columns
# lemma <- udpipe(x = titles_tidy$word, object = "2.data_transformations/data/cs_pdt_model.udpipe", parallel.cores = parallel::detectCores() - 1)
# test <- titles_tidy %>% inner_join(lemma, by = c("word" = "token"))
