library(httr)
library(jsonlite)
library(dplyr)
library(data.table)

lemma = "migrace"
pos = "N"

# Extract similar words from the syn v8 corpus, using Wang2Vec algorithm.

similar_words <- GET(
  url = paste0("https://utils.korpus.cz/wsserver/corpora/syn_v8/similarWords/nce/", lemma, "/", pos),
  query = list(
    limit = 10,
    minScore = 0.7
  ),
  add_headers(
    Accept = "application/json",
    Connection = "keep-alive",
    `Accept-Encoding` = "gzip, deflate, br"
  )) %>%
  content(as = "text", encoding = "UTF-8") %>%
  fromJSON()

# Tomáš Machálek (2014): KonText – Corpus Query Interface. FF UK, Praha. Available at WWW: <http://kontext.korpus.cz/>.

