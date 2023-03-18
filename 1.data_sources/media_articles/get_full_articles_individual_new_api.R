extract_full_articles_individual_new_api <- function(article_code,
                                                     date_published,
                                                     search_history_id,
                                                     newton_api_token,
                                                     media_id = NULL,
                                                     return_df = FALSE,
                                                     log = TRUE,
                                                     log_path = "") {
  # 0. Load libraries ------------------------------------------

  # Package names
  packages <- c("httr", "dplyr", "jsonlite")

  # Install packages not yet installed
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(packages[!installed_packages])
  }

  # Packages loading
  invisible(lapply(packages, library, character.only = TRUE))

  # 1. Verify function's inputs ------------------------------------------
  stopifnot(
    is.character(article_code) & length(article_code) == 1,
    is.character(search_history_id) | is.numeric(search_history_id),
    (is.character(date_published) & nchar(date_published) %in% c(10, 19)) | inherits(date_published, "Date"),
    is.logical(return_df),
    is.logical(log),
    is.character(log_path),
    is.character(newton_api_token),
    nchar(newton_api_token) > 30
  )
  # Add log printing for long extractions
  if (log == TRUE) {
    # Custom function to print console output to a file
    cat_sink <-
      function(...,
               file = paste0(log_path, "get_full_articles_individual_new_api_log.txt"),
               append = TRUE) {
        cat(..., file = file, append = append)
      }
  } else {
    cat_sink <- cat
  }

  # 3. Extract the article ------------------------------------------

  full_article <- httr::RETRY(
    verb = "GET",
    url = paste0("https://api.newtonmedia.eu/v2/archive/articles/", article_code),
    config = httr::add_headers(
      Accept = "application/json",
      Authorization = paste("token", as.character(newton_api_token)),
      Connection = "keep-alive",
      `Accept-Encoding` = "gzip, deflate, br"
    ),
    query = list(
      publishDate = date_published,
      searchHistoryId = search_history_id
    )
  )

  if (httr::status_code(full_article) == 500) {
    cat_sink("\nWARNING: API call for article", article_code, "from date", as.character(date_published), "failed with error code 500. Missing data are likely.")

    # Replace with empty dataset so bind_row at the end is successful
    full_article <- tibble()
  } else if (httr::status_code(full_article) == 200 & as.numeric(full_article$headers$`content-length`) < 50) {
    cat_sink("\nWARNING: API call for article", article_code, "from date", as.character(date_published), "probably failed because content lenght is lower than expected.")

    # Replace with empty dataset so bind_row at the end is successful
    full_article <- tibble()
  } else if (httr::status_code(full_article) == 200 & as.numeric(full_article$headers$`content-length`) >= 50) {
    full_article <- full_article %>%
      content(as = "text") %>%
      fromJSON() %>%
      .[c(
        "content",
        "page",
        "sectionName",
        "sourceName",
        "code",
        "author",
        "datePublished",
        "importDate",
        "detailUrl",
        "title"
      )]

    cat_sink("\n\nExtraction of article", article_code, "from date", as.character(date_published), "has finished.\n")
  } else {
    cat_sink("\nWARNING: API call for article", article_code, "from date", as.character(date_published), "returned the following code:", httr::status_code(full_article), ". Check the connection.")
  }

  if (return_df == TRUE) {
    return(bind_rows(full_article))
  } else if (return_df == FALSE) {
    return(full_article)
  }
}
