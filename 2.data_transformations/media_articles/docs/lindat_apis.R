library(httr)
library(jsonlite)
library(dplyr)
library(data.table)

full_articles_subset <- readRDS("2.data_transformations/data/full_articles_subset.rds")
full_articles_subset$Content <- gsub(pattern = "  +", replacement = " ", x = gsub(pattern = "<(.|\n)*?>|[^ěščřžýáíéóúůďťňĎŇŤŠČŘŽÝÁÍÉÚŮĚÓa-zA-Z,\\.{1} ]", replacement = " ", x = full_articles_subset$Content))

i <- 5

# NAME ENTITY RECOGNITION
# Straka, Milan and Straková, Jana, 2014,
# NameTag, LINDAT/CLARIAH-CZ digital library at the Institute of Formal and Applied Linguistics (ÚFAL), Faculty of Mathematics and Physics, Charles University,
# http://hdl.handle.net/11858/00-097C-0000-0023-43CE-E.

ner_tsv <- httr::RETRY(
  verb = "POST",
  url = "http://lindat.mff.cuni.cz/services/nametag/api/recognize",
  query = list(
    output = "vertical",
    model = "czech-cnec2.0-200831",
    input = "untokenized"
  ),
  config = add_headers(
    Accept = "application/json",
    `Content-Type` = "application/x-www-form-urlencoded",
    Connection = "keep-alive",
    `Accept-Encoding` = "gzip, deflate, br"
  ),
  body = list(
    data = full_articles_subset$Content[[i]]
  ),
  encode = "form"
) %>%
  content(as = "text", encoding = "UTF-8") %>%
  fromJSON() %>%
  .[["result"]] %>%
  fread(sep = "\t", header = FALSE, colClasses = c("character", "character", "character"), col.names = c("token_range", "ent_type", "ent_text")) %>%
  .[, document_id := full_articles_subset$Code[[i]]] # When response type tsv (setting "vertical")

# NER: Each file size around 10Kb

# # When response type XML (parsing this way seem to be 5-10 slower)
# parsed_xml <- data.table(xml2::read_xml(paste0("<root>", ner_xml, "</root>")) %>% xml2::xml_find_all("//@type") %>% xml_text(trim = FALSE), xml2::read_xml(paste0("<root>", ner_xml, "</root>")) %>% xml2::xml_find_all("//ne") %>% xml2::xml_text(trim = FALSE))

# # UDPIPE
# #
# # Straka, Milan and Straková, Jana, 2016,
# UDPipe, LINDAT/CLARIAH-CZ digital library at the Institute of Formal and Applied Linguistics (ÚFAL), Faculty of Mathematics and Physics, Charles University,
# http://hdl.handle.net/11234/1-1702.


source("2.data_transformations/conllu_to_df.R")
# API uses UD models v 2.6, slightly improved to 2.5, which is used locally using Udpipe library (changelog: https://github.com/UniversalDependencies/UD_Czech-PDT/tree/master)
udpipe_api <- httr::RETRY(
  verb = "POST",
  url = "http://lindat.mff.cuni.cz/services/udpipe/api/process",
  query = list(
    model = "czech-pdt-ud-2.6-200830",
    tokenizer = "",
    parser = "",
    tagger = ""
  ),
  config = add_headers(
    Accept = "application/json",
    `Content-Type` = "application/x-www-form-urlencoded",
    Connection = "keep-alive",
    `Accept-Encoding` = "gzip, deflate, br"
  ),
  body = list(
    data = processed_cs_df$text[i]
  ),
  encode = "form"
) %>%
  content(as = "text", encoding = "UTF-8") %>%
  fromJSON() %>%
  .[["result"]] %>%
  conllu_to_df_mod(document_id = processed_cs_df$article_id[[i]])

# UDPIPE: Each file size around 100Kb


# Keyword extraction (TF-IDF)
# # Libovický, Jindřich, 2016,
# KER - Keyword Extractor, LINDAT/CLARIAH-CZ digital library at the Institute of Formal and Applied Linguistics (ÚFAL), Faculty of Mathematics and Physics, Charles University,
# http://hdl.handle.net/11234/1-1650.


kw_extract <- httr::RETRY(
  verb = "POST",
  url = "http://lindat.mff.cuni.cz/services/ker",
  query = list(
    language = "cs",
    treshold = 0.2,
    `maximum-words` = 15
  ),
  config = add_headers(
    Accept = "application/json",
    Connection = "keep-alive",
    `Accept-Encoding` = "gzip, deflate, br"
  ),
  body = list(
    data = full_articles_subset$Content[[i]]
  ),
  encode = "multipart"
) %>%
  content(as = "text", encoding = "UTF-8") %>%
  fromJSON() %>%
  .[c("keywords", "keyword_scores")] %>%
  as.data.table() %>%
  .[, document_id := full_articles_subset$Code[[i]]]

# Tomáš Machálek (2014): KonText – Corpus Query Interface. FF UK, Praha. Available at WWW: <http://kontext.korpus.cz/>.


# KORPUS.CZ wordforms
word_forms <- httr::RETRY(
  verb = "GET",
  url = "https://www.korpus.cz/slovo-v-kostce/word-forms/",
  query = list(
    domain = "cs",
    lemma = "byt",
    pos = "N"
  ),
  config = add_headers(
    Accept = "application/json",
    Connection = "keep-alive",
    `Accept-Encoding` = "gzip, deflate, br"
  )
) %>%
  content(as = "text", encoding = "UTF-8") %>%
  fromJSON() %>%
  .[["result"]]
