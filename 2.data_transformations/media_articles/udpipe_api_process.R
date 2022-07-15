# 0. Load libraries ------------------------------------------

# Package names
packages <- c("httr", "dplyr", "jsonlite", "udpipe")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))


# Modified function from the UDPIPE package

# Transforms Conllu format to R's data frame
conllu_to_df_mod <- function(x, document_id = "# newdoc", is_udpipe_annotation = FALSE, ...)
{
  data.table::setDTthreads(threads = 1)

  x = list(conllu = x) %>% "class<-"("udpipe_connlu")
  # Imports C++ dependency from UDPIPE package
  na_locf <- function(x) {
    .Call('_udpipe_na_locf', PACKAGE = 'udpipe', x)
  }

  doc_id <- paragraph_id <- sentence_id <- token_id <- head_token_id <- token <- lemma <- upos <- xpos <- feats <- dep_rel <- deps <- misc <- term_id <- .N <- NULL
  output_fields <- c("doc_id", "paragraph_id", "sentence_id",
                     "sentence", "token_id", "token", "lemma", "upos", "xpos",
                     "feats", "head_token_id", "dep_rel", "deps", "misc")
  ldots <- list(...)
  if (any(c("rich", "full", "enhanced", "detailed") %in% names(ldots))) {
    ldots$term_id <- TRUE
    ldots$start_end <- TRUE
  }
  if ("term_id" %in% names(ldots)) {
    if (isTRUE(ldots$term_id)) {
      output_fields <- append(output_fields, values = "term_id",
                              after = 4)
    }
  }
  if ("start_end" %in% names(ldots)) {
    if (isTRUE(ldots$start_end)) {
      output_fields <- append(output_fields, values = c("start",
                                                        "end"), after = 4)
    }
  }
  default <- data.frame(doc_id = character(), paragraph_id = integer(),
                        sentence_id = character(), sentence = character(), start = integer(),
                        end = integer(), term_id = integer(), token_id = character(),
                        token = character(), lemma = character(), upos = character(),
                        xpos = character(), feats = character(), head_token_id = character(),
                        dep_rel = character(), deps = character(), misc = character(),
                        stringsAsFactors = FALSE)
  default <- default[, output_fields]
  if (is_udpipe_annotation) {
    default$sentence_id <- as.integer(default$sentence_id)
  }
  if (length(x$conllu) <= 1) {
    if (all(x$conllu == "")) {
      msg <- unique(x$error)
      if (length(msg) == 0) {
        msg <- ""
      }
      else {
        msg <- paste(msg, collapse = ", ")
      }
      warning(sprintf("No parsed data in x$conllu, returning default empty data.frame. Error message at x$error indicates e.g.: %s",
                      msg))
      return(default)
    }
  }
  if (!exists("startsWith", envir = baseenv())) {
    startsWith <- function(x, prefix) {
      prefix <- paste("^", prefix, sep = "")
      grepl(pattern = prefix, x = x)
    }
  }
  txt <- strsplit(x$conllu, "\n", fixed = TRUE)[[1]]
  is_sentence_boundary <- txt == ""
  is_comment <- startsWith(txt, "#")
  is_newdoc <- startsWith(txt, "# newdoc")
  is_newparagraph <- startsWith(txt, "# newpar")
  is_sentenceid <- startsWith(txt, "# sent_id")
  is_sentencetext <-  startsWith(txt, "# text")
  is_taggeddata <- !is_sentence_boundary & !is_comment
  out <- data.table::data.table(txt = txt, doc_id = na_locf(ifelse(is_newdoc,
                                                                   sub("^# newdoc", document_id, txt), NA_character_)), sentence_id = na_locf(ifelse(is_sentenceid,
                                                                                                                                                     sub("^# sent_id = *", "", txt), NA_character_)), sentence = na_locf(ifelse(is_sentencetext,
                                                                                                                                                                                                                                sub("^# text = *", "", txt), NA_character_)), is_newparagraph = is_newparagraph)
  if (is_udpipe_annotation) {
    out$sentence_id <- as.integer(out$sentence_id)
  }
  underscore_as_na <- function(x, which_na = NA_character_) {
    x[which(x == "_")] <- which_na
    x
  }
  out[, `:=`(paragraph_id, cumsum(is_newparagraph)), by = list(doc_id)]
  out <- out[is_taggeddata, ]
  if ("term_id" %in% output_fields) {
    out[, `:=`(term_id, 1L:.N), by = list(doc_id)]
  }
  out <- out[, `:=`(c("token_id", "token", "lemma", "upos",
                      "xpos", "feats", "head_token_id", "dep_rel", "deps",
                      "misc"), data.table::tstrsplit(txt, "\t", fixed = TRUE))]
  out[, `:=`(token_id, underscore_as_na(token_id))]
  out[, `:=`(head_token_id, underscore_as_na(head_token_id))]
  out[, `:=`(lemma, underscore_as_na(lemma))]
  out[, `:=`(upos, underscore_as_na(upos))]
  out[, `:=`(xpos, underscore_as_na(xpos))]
  out[, `:=`(feats, underscore_as_na(feats))]
  out[, `:=`(dep_rel, underscore_as_na(dep_rel))]
  out[, `:=`(deps, underscore_as_na(deps))]
  out[, `:=`(misc, underscore_as_na(misc))]
  if (all(c("start", "end") %in% output_fields)) {
    out[, `:=`(c("start", "end"), udpipe_reconstruct(sentence_id = sentence_id,
                                                     token = token, token_id = token_id, misc = misc,
                                                     only_from_to = TRUE)), by = list(doc_id)]
  }
  out <- out[, output_fields, with = FALSE]
  out <- data.table::setDF(out)
  out
}


# Function which interacts with the UDPIPE's API
udpipe_process <- function(article_id,
                           article_text,
                           log = TRUE,
                           log_path = "",
                           return_df = TRUE) {

  # 1. Verify function's inputs ------------------------------------------
  stopifnot(
    is.character(article_id),
    is.character(article_text),
    is.logical(log),
    is.character(log_path),
    is.logical(return_df)
  )

  # Add log printing for long extractions
  if (log == TRUE) {
    # Custom function to print console output to a file
    cat_sink <- function(..., file = paste0(log_path, "udpipe_api_process_log.txt"), append = TRUE) {
      cat(..., file = file, append = append)
    }
  } else {
    cat_sink <- cat
  }

  cat_sink("\n>--------------------<\n\n", as.character(Sys.time()))
  # 3. Loop over pages ------------------------------------------

  ## Create empty list to append results to
  udpipe_dfs_list <- vector(mode = "list", length = length(article_id))

  # Start counting the extraction length
  start_time <- Sys.time()

  for (i in seq_along(udpipe_dfs_list)) {

    if (i %% 5000 == 0) {
      cat_sink("\nAfter 5000 calls: Pausing for 600 seconds.\n")
      Sys.sleep(600)
    }

    if (i %% 500 == 0) {
          gc()
    }

    udpipe_dfs_list[[i]] <- POST(
      url = "http://lindat.mff.cuni.cz/services/udpipe/api/process",
      query = list(
        model = "czech-pdt-ud-2.6-200830",
        tokenizer = "",
        parser = "",
        tagger = ""
      ),
      add_headers(
        Accept = "application/json",
        `Content-Type` = "application/x-www-form-urlencoded",
        Connection = "keep-alive",
        `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.114 Safari/537.36",
        `Accept-Encoding` = "gzip, deflate, br"
      ),
      body = list(
        data = article_text[[i]]
      ),
      encode = "form")

    if (httr::status_code(udpipe_dfs_list[[i]]) == 500) {
      cat_sink("\nWARNING: API call nr.", i, " failed with error code 500. Missing data are likely.")

      # Replace with empty dataset so bind_row at the end is successful
      udpipe_dfs_list[[i]] <- tibble()

      # Longer wait time
      cat_sink("\nPausing for 600 seconds.\n")
      Sys.sleep(600)

    } else if (httr::status_code(udpipe_dfs_list[[i]]) == 200) {

      udpipe_dfs_list[[i]] <- udpipe_dfs_list[[i]] %>%
      content(as = "text", encoding = "UTF-8") %>%
        fromJSON() %>%
        .[["result"]] %>%
        conllu_to_df_mod(document_id = article_id[[i]]) %>%
        transmute(doc_id, sentence_id = as.integer(sentence_id), token_id, token, lemma, upos, xpos, feats, head_token_id, dep_rel)

      cat_sink("\nAPI call nr.", i, "executed. The number of rows is", nrow(udpipe_dfs_list[[i]]))

    } else {
      cat_sink("\nWARNING: API call nr.", i, " returned the following code: ", httr::status_code(udpipe_dfs_list[[i]]), ". Check the connection.")
      # Replace with empty dataset so bind_row at the end is successful
      udpipe_dfs_list[[i]] <- tibble()
      # Longer wait time
      cat_sink("\nPausing for 600 seconds.\n")
      Sys.sleep(600)

    }

    # Random wait time as not to overwhelm the API
    pause <- runif(1, 0.01, 0.1)
    cat_sink("\nPausing for", pause, "seconds.\n")
    Sys.sleep(pause)
  }

  cat_sink("\nSUMMARY: Total amount of articles processed with UDPIPE is", length(udpipe_dfs_list), "\n")

  print(Sys.time() - start_time)

  cat_sink("\n>--------------------<\n\n")

  gc()

  if (return_df == TRUE) {
    return(bind_rows(udpipe_dfs_list))
  } else if (return_df == FALSE) {
    return(udpipe_dfs_list)
  }

}
