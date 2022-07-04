# This analysis uses USAS lexicon
# Info about the project https://ucrel.lancs.ac.uk/usas/
# Repository with multilingual lexicons https://github.com/UCREL/Multilingual-USAS

library(dplyr)
library(readr)
library(tidyr)
library(stringr)

semantic_lexicon <- read_delim("4.data_analysis/semantic_analysis/data/semantic_lexicon_cz.tsv",
  "\t",
  escape_double = FALSE,
  trim_ws = TRUE,
  col_types = c("ccc")
) %>%
  mutate(lemma = tolower(lemma))

semantic_categories <- read_delim("4.data_analysis/semantic_analysis/data/semtags_subcategories.tsv",
  "\t",
  escape_double = FALSE,
  trim_ws = TRUE,
  col_types = c("cc"),
  col_names = c("tag", "category")
)

semantic_labelled_df <- udp %>%
  filter(upos %in% c("NOUN")) %>% # Filtering our POS tags that are not of interest
  select("doc_id", "lemma") %>%
  mutate(lemma = tolower(lemma)) %>%
  inner_join(semantic_lexicon, by = "lemma")

max_tags_rn <- max(str_count(semantic_labelled_df[["semantic_tags"]], "\\/|\\s")) + 1

semantic_labelled_df_long <- semantic_labelled_df %>%
  separate(semantic_tags,
    into = paste0("tag_", seq_len(max_tags_rn)),
    remove = TRUE,
    sep = "\\/|\\s",
    extra = "drop",
    fill = "right"
  ) %>%
  pivot_longer(paste0("tag_", seq_len(max_tags_rn)), names_to = "tag_nr", values_to = "tag_value") %>%
  # Removing extra characters, that are prevent matching with the categories
  mutate(
    tag_value = str_replace_all(tag_value, "[%@fmcni]", ""), # Remove all %@fmcni
    tag_value = str_replace_all(tag_value, "\\+{2,}", "+"), # Remove more than one plus sing
    tag_value = str_replace_all(tag_value, "\\-{2,}", "-")
  ) %>% # Remove more than one minus sing
  left_join(semantic_categories, by = setNames("tag", "tag_value"))


ucas_summary <- semantic_labelled_df_long[!is.na(semantic_labelled_df_long$category), ] %>%
  count(category, sort = TRUE)
