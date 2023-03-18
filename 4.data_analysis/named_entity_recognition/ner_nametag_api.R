# 0. Load libraries ------------------------------------------

# Package names
packages <- c("httr", "dplyr", "jsonlite", "data.table")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# Function which interacts with the NameTag's API
nametag_process <- function(article_id,
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
    cat_sink <-
      function(...,
               file = paste0(log_path, "nametag_api_process_log.txt"),
               append = TRUE) {
        cat(..., file = file, append = append)
      }
  } else {
    cat_sink <- cat
  }

  cat_sink("\n>--------------------<\n\n", as.character(Sys.time()))

  # 3. Loop over pages ------------------------------------------

  ## Create empty list to append results to
  nametag_dfs_list <- vector(mode = "list", length = length(article_id))

  # Start counting the extraction length
  start_time <- Sys.time()

  for (i in seq_along(nametag_dfs_list)) {
    if (i %% 5000 == 0) {
      cat_sink("\nAfter 5000 calls: Pausing for 600 seconds.\n")
      Sys.sleep(600)
      gc()
    }

    nametag_dfs_list[[i]] <- httr::RETRY(
      verb = "POST",
      url = "http://lindat.mff.cuni.cz/services/nametag/api/recognize",
      query = list(
        output = "vertical",
        model = "czech-cnec2.0-200831",
        input = "untokenized"
      ),
      config = httr::add_headers(
        Accept = "application/json",
        `Content-Type` = "application/x-www-form-urlencoded",
        Connection = "keep-alive",
        `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.114 Safari/537.36",
        `Accept-Encoding` = "gzip, deflate, br"
      ),
      body = list(
        data = article_text[[i]]
      ),
      encode = "form"
    )

    if (httr::status_code(nametag_dfs_list[[i]]) == 500) {
      cat_sink("\nWARNING: API call nr.", i, " failed with error code 500. Missing data are likely.")

      # Replace with empty dataset so bind_row at the end is successful
      nametag_dfs_list[[i]] <- tibble()

      # Longer wait time
      cat_sink("\nPausing for 600 seconds.\n")
      Sys.sleep(600)
    } else if (httr::status_code(nametag_dfs_list[[i]]) == 200) {
      nametag_dfs_list[[i]] <- nametag_dfs_list[[i]] %>%
        content(as = "text", encoding = "UTF-8") %>%
        fromJSON() %>%
        .[["result"]]

      if (nchar(nametag_dfs_list[[i]]) >= 4) {
        nametag_dfs_list[[i]] <- nametag_dfs_list[[i]] %>%
          fread(
            sep = "\t", header = FALSE,
            colClasses = c("character", "character", "character"),
            col.names = c("token_range", "ent_type", "ent_text")
          ) %>%
          .[, doc_id := article_id[[i]]]

        cat_sink("\nAPI call nr.", i, "executed. The number of rows is", nrow(nametag_dfs_list[[i]]))
      } else {
        nametag_dfs_list[[i]] <- tibble()

        cat_sink("\nAPI call nr.", i, "executed. No entities were gathered.")
      }
    } else {
      cat_sink("\nWARNING: API call nr.", i, " returned the following code: ", httr::status_code(nametag_dfs_list[[i]]), ". Check the connection.")
      # Replace with empty dataset so bind_row at the end is successful
      nametag_dfs_list[[i]] <- tibble()
      # Longer wait time
      cat_sink("\nPausing for 600 seconds.\n")
      Sys.sleep(600)
    }

    # Random wait time as not to overwhelm the API
    Sys.sleep(runif(1, 0.01, 0.1))
  }

  cat_sink("\nSUMMARY: Total amount of articles processed with NameTag is", length(nametag_dfs_list), "\n")

  print(Sys.time() - start_time)

  cat_sink("\n>--------------------<\n\n")

  if (return_df == TRUE) {
    return(bind_rows(nametag_dfs_list))
  } else if (return_df == FALSE) {
    return(nametag_dfs_list)
  }
}
