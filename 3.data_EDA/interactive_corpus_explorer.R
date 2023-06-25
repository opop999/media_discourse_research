# Testing the interactive corpus-viewing tool for qualitative analysis
library(corporaexplorer)

# Sample annotation chunk
corpus <- readRDS("1.data_sources/media_articles/data/annotations/chunks/annotated_articles_2015.rds") %>%
  head(1000) %>%
  transmute(Text = annotation,
            Date = as.Date(datePublished))

# Prepare the corpus for Viewing
prep_corpus <- prepare_data(corpus)

# Start interactive Shiny app
explore(prep_corpus)
