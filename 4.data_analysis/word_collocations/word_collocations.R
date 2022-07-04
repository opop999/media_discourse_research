library(quanteda)
library(quanteda.textstats)
library(tidyr)
library(dplyr)
library(stringr)
library(purrr)
library(wordcloud)
library(tidytext)
library(tm)
library(ggplot2)
library(FactoMineR)
library(factoextra)
library(GGally)
library(igraph)
library(network)

collocation_pattern <- "(běženec\\S*)|(běženk\\S*)|(imigrant\\S*)|(migra\\S*)|(imigra\\S*)|(přistěhoval\\S*)|(uprchl\\S*)|(utečen\\S*)|(azylant\\S*)"
# All "normal" characters "^[ěščřžýáíéóúůďťňĎŇŤŠČŘŽÝÁÍÉÚŮĚÓa-z0-9]"
# sub_pattern <- "rakous\\S*"

# Function definitions
## Get only the UDPIPE data according to selection
get_udpipe_selection <- function(udpipe_path_to_rds,
                                 period_filter = NULL,
                                 media_labels = NULL,
                                 media_type_filter = NULL,
                                 pos_filter = c("VERB", "NOUN", "ADJ", "PROPN")
                                 ) {

  all_udpipe_chunks <- list.files(path = udpipe_path_to_rds, pattern = "*.rds", full.names = TRUE)
  if (!is.null(period_filter)) {all_udpipe_chunks <- all_udpipe_chunks[grepl(period_filter, all_udpipe_chunks)]}
  txt <- map_dfr(all_udpipe_chunks, readRDS) %>% filter(upos %in% pos_filter) %>% select(doc_id, lemma)

  if (!is.null(media_labels) & !is.null(media_type_filter)) {txt <- txt %>%
    inner_join(media_labels,  by = "doc_id") %>%
    filter(media_type %in% media_type_filter) %>%
    select(doc_id, lemma, media_type)
  }

  return(txt)
}

## Get collocations for the provided UDPIPE data
get_all_collocations <- function(udpipe_df,
                                 collocation_pattern,
                                 sub_pattern = NULL,
                                 window_size = 5,
                                 min_count = 20,
                                 collocation_size = 2) {

  # Process to a format usable with Quanteda's textstat_collocations function
  udpipe_df %>%
    mutate(word = tolower(str_replace_na(lemma, replacement = ""))) %>% # Select token or lemma for different results
    group_by(doc_id) %>%
    summarize(tokenized_text = str_squish(str_c(word, collapse = " "))) %>%
    ungroup() %>%
    corpus(docid_field = "doc_id", text_field = "tokenized_text") %>%
    tokens(remove_punct = TRUE,
           remove_numbers = TRUE,
           padding = TRUE,
           remove_symbols = TRUE) %>%
    # Selecting only words in a specific window can speed up calculations
    tokens_select(pattern = collocation_pattern,
                  valuetype = "regex",
                  selection = "keep",
                  window = window_size,
                  case_insensitive = TRUE,
                  padding = TRUE,
                  verbose = TRUE) %>%
    # Create collocations, optionally filtering further by a pattern of interest
    textstat_collocations(min_count = min_count, size = collocation_size) %>%
    filter(if (!is.null(sub_pattern)) str_detect(collocation, sub_pattern) else TRUE) %>%
    arrange(lambda)
}

mainstream_2015_df <- get_udpipe_selection(udpipe_path_to_rds = "2.data_transformations/media_articles/data/udpipe_processed/chunks",
                                           period_filter = "2015-(10|11|12)",
                                           media_labels = readRDS("1.data_sources/media_articles/data/media_type_labels/all_media_labels_with_doc_id.rds"),
                                           media_type_filter = "mainstream",
                                           pos_filter = c("NOUN", "ADJ"))

mainstream_2015_collocs <- get_all_collocations(mainstream_2015_df, collocation_pattern, collocation_size = 2) %>%
  bind_rows(get_all_collocations(mainstream_2015_df, collocation_pattern, collocation_size = 3))

saveRDS(mainstream_2015_collocs, "4.data_analysis/word_collocations/data/mainstream_2015_collocs.rds")

alternative_2015_df <- get_udpipe_selection(udpipe_path_to_rds = "2.data_transformations/media_articles/data/udpipe_processed/chunks",
                                           period_filter = "2015-(10|11|12)",
                                           media_labels = readRDS("1.data_sources/media_articles/data/media_type_labels/all_media_labels_with_doc_id.rds"),
                                           media_type_filter = c("antisystem", "political_tabloid"),
                                           pos_filter = c("NOUN", "ADJ"))

alternative_2015_collocs <- get_all_collocations(alternative_2015_df, collocation_pattern, collocation_size = 2) %>%
  bind_rows(get_all_collocations(alternative_2015_df, collocation_pattern, collocation_size = 3))

saveRDS(alternative_2015_collocs, "4.data_analysis/word_collocations/data/alternative_2015_collocs.rds")


mainstream_2022_df <- get_udpipe_selection(udpipe_path_to_rds = "2.data_transformations/media_articles/data/udpipe_processed/chunks",
                                           period_filter = "2022-(02|03|04)",
                                           media_labels = readRDS("1.data_sources/media_articles/data/media_type_labels/all_media_labels_with_doc_id.rds"),
                                           media_type_filter = "mainstream",
                                           pos_filter = c("NOUN", "ADJ"))

mainstream_2022_collocs <- get_all_collocations(mainstream_2022_df, collocation_pattern, collocation_size = 2) %>%
  bind_rows(get_all_collocations(mainstream_2022_df, collocation_pattern, collocation_size = 3))

saveRDS(mainstream_2022_collocs, "4.data_analysis/word_collocations/data/mainstream_2022_collocs.rds")

alternative_2022_df <- get_udpipe_selection(udpipe_path_to_rds = "2.data_transformations/media_articles/data/udpipe_processed/chunks",
                                            period_filter = "2022-(02|03|04)",
                                            media_labels = readRDS("1.data_sources/media_articles/data/media_type_labels/all_media_labels_with_doc_id.rds"),
                                            media_type_filter = c("antisystem", "political_tabloid"),
                                            pos_filter = c("NOUN", "ADJ"))

alternative_2022_collocs <- get_all_collocations(alternative_2022_df, collocation_pattern, collocation_size = 2) %>%
  bind_rows(get_all_collocations(alternative_2022_df, collocation_pattern, collocation_size = 3))

saveRDS(alternative_2022_collocs, "4.data_analysis/word_collocations/data/alternative_2022_collocs.rds")



# Create Wordcloud Viz
collocations_migration %>%
    with(wordcloud(collocation, z, min.freq = 5, random.order = FALSE, max.words = 100, colors = brewer.pal(8, "Dark2")))




































###################################

# Alternative: Collocations using text2vec library
library(text2vec)

model = Collocations$new(collocation_count_min = 50, pmi_min = 5)
txt = as.list(txt) # Txt Token object created above
it = itoken(txt)
model$fit(it, n_iter = 3)

collocations_migration_txt2vec <- model$collocation_stat %>%
  filter(str_detect(prefix, sub_pattern) | str_detect(suffix, sub_pattern))

# Create Wordcloud Viz
collocations_migration_txt2vec %>%
  with(wordcloud(paste(prefix, suffix, sep = " "), llr, min.freq = 5, random.order = FALSE, max.words = 30, colors = brewer.pal(8, "Dark2")))


##################################
# Workflow to get all collocates for a term of interest

# Construct Document-Term Matrix ------------------------------------------
get_dtm <- function(udpipe_processed_df,
                    pos_filter = c("VERB", "NOUN", "ADJ", "PROPN"),
                    media_labels = NULL,
                    media_types = c("mainstream", "alternative"),
                    dtm_sparsity = 0.99)  {

  udpipe_processed_df %>%
    filter(upos %in% pos_filter) %>%
    mutate(word = tolower(str_replace_na(lemma, replacement = ""))) %>% # Select token or lemma for different results
    group_by(doc_id) %>%
    summarize(tokenized_text = str_squish(str_c(word, collapse = " "))) %>%
    ungroup() %>%
    inner_join(media_labels, by = "doc_id") %>%
    filter(media_type %in% media_types) %>%
    pull(tokenized_text) %>%
    VectorSource() %>%
    Corpus() %>%
    DocumentTermMatrix() %>%
    removeSparseTerms(sparse = dtm_sparsity)
}


# Get COOC Stats DF --------------------------------------------------------
get_cooc_stats_df <-
  function(dtm,
           key_terms,
           cooc_function_path,
           measure = c("DICE", "LOGLIK", "MI")) {
    source(cooc_function_path)

    cooc_stats_list <-
      vector("list", length = length(key_terms)) %>% setNames(key_terms)

for (o in seq_along(key_terms))  {

    for (i in measure) {
      cooc_stats_list[[key_terms[[o]]]][[i]] <- calculate_cooc_stats(cooc_term = key_terms[[o]],
                                                   dtm = dtm,
                                                   measure = i)
    }

    cooc_stats_list[[key_terms[[o]]]] <- bind_rows(cooc_stats_list[[key_terms[[o]]]], .id = "measure") %>%
      pivot_longer(
        cols = 2:ncol(.),
        values_to = "strength",
        names_to = "term"
      ) %>%
      pivot_wider(names_from = "measure", values_from = "strength") %>%
      filter(if_all(measure, ~ is.finite(.x) &
        !is.nan(.x) & !is.na(.x))) %>%
      mutate(
        rank_dice = rank(-DICE, ties.method = "first"),
        rank_loglik = rank(-LOGLIK, ties.method = "first"),
        rank_mi = rank(-MI, ties.method = "first")
      ) %>%
      rowwise() %>%
      mutate(avg_rank = round(mean(c(rank_dice, rank_loglik, rank_mi)))) %>%
      ungroup()
  }
    cooc_stats_df <- bind_rows(cooc_stats_list, .id = "lemma")
  }


# Transform DTM to Sparse Matrix ------------------------------------------
dtm_to_sparse_matrix <- function(dtm) {

  sparse_matrix <- Matrix::sparseMatrix(i = dtm$i, j = dtm$j,
                                        x = dtm$v,
                                        dims = c(dtm$nrow, dtm$ncol),
                                        dimnames = dimnames(dtm))

  collocates <- (t(sparse_matrix) %*% sparse_matrix) %>%
    as.matrix()

  return(collocates)
}


# Remove non-collocating items --------------------------------------------
noncolocs_removed_matrix <- function(colloc_df, sparse_colloc_matrix, key_term) {

  collocates_redux <- sparse_colloc_matrix[rownames(sparse_colloc_matrix) %in% c(colloc_df$term, key_term), ] %>%
    .[, colnames(.) %in% c(colloc_df$term, key_term)]

}

# Get graph of strengths of association -----------------------------------
get_collocs_viz <- function(colloc_df, key_term, measure) {
  ggplot(colloc_df, aes(x = reorder(term, strength, mean), y = strength)) +
    geom_point() +
    coord_flip() +
    theme_bw() +
    labs(y = "") +
    labs(x = "") +
    ggtitle(paste("Collocates of the term", key_term, "by strength of association using", measure))
}

# Create network object vizualization -------------------------------------
get_network_viz <- function(matrix_redux) {
  net_object <- network(matrix_redux,
                         directed = FALSE,
                         ignore.eval = FALSE,
                         names.eval = "weights")

  network.vertex.names(net_object) = rownames(matrix_redux)

  net_object_viz <- ggnet2(
    net_object,
    size = "degree",
    label = TRUE,
    palette	= "Dark2",
    label.size = 4,
    alpha = 0.2,
    size.cut = 3,
    edge.alpha = 0.2
  ) +
    guides(color = "none", size = "none")

  return(net_object_viz)
}

# Create Correspondence Analysis Vizualization ----------------------------
get_ca_viz <- function(matrix_redux) {
  CA(mainstream_redux, graph = FALSE) %>%
    fviz_ca_row(repel = TRUE, col.row = "gray20")
}


###########################


media_labels_filtered <- readRDS("1.data_sources/media_articles/data/media_type_labels/all_media_labels_with_doc_id.rds") %>%
  mutate(media_type = fct_collapse(media_type, alternative = c("antisystem", "political_tabloid"))) %>%
  filter(media_type %in% c("mainstream", "alternative"))

# Get Collocates for selected term for alt media

key_terms <- c("uprchlík", "migrant") %>% tolower()
cooc_function_path <- "4.data_analysis/word_collocations/get_cooc_stats.R"


alt_colocs <- get_dtm(
  udpipe_processed_df,
  pos_filter = c("NOUN", "ADJ", "PROPN"),
  media_types = "alternative",
  media_labels = media_labels_filtered
) %>% get_cooc_stats_df(key_terms = key_terms,
                         cooc_function_path = cooc_function_path)

alt_colocs %>%
  filter(lemma == "migrant") %>%
  slice_min(rank_loglik, n = 10) %>%
ggplot(aes(x = reorder(term, LOGLIK), y = LOGLIK)) +
  geom_point() +
  geom_col(width = 0.2) +
  coord_flip() +
  theme_bw() +
  labs(y = "") +
  labs(x = "")
  # scale_y_continuous(
  #   expand = c(0, 0),
  #   breaks = seq(0, 1, 0.1),
  #   labels = seq(0, 1, 0.1),
  #   limits = c(0, 1)
  # )

mainstream_colloc_matrix <- dtm_to_sparse_matrix(dtm = mainstream_colloc_dtm)
mainstream_redux <- noncolocs_removed_matrix(mainstream_colloc_df, mainstream_colloc_matrix, key_term = key_term)
get_collocs_viz(mainstream_colloc_df, key_term = key_term, measure = measure)
get_network_viz(mainstream_redux)
get_ca_viz(mainstream_redux)

# Simple count of BiGrams in the corpus
# udpipe_bigrams <- udpipe_processed_df %>%
#   filter(upos %in% c("VERB", "NOUN", "ADJ", "PROPN")) %>%
#   mutate(word = tolower(str_replace_na(lemma, replacement = ""))) %>% # Select token or lemma for different results
#   group_by(doc_id) %>%
#   summarize(tokenized_text = str_squish(str_c(word, collapse = " "))) %>%
#   unnest_tokens(word_1, tokenized_text)  %>%
#   ungroup() %>%
#   mutate(word_2 = c(word_1[2:length(word_1)], NA)) %>%
#   na.omit() %>%
#   transmute(doc_id, bigram = paste(word_1, word_2, sep = " ")) %>%
#   count(bigram, sort = TRUE)
