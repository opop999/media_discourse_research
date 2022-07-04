extract_full_articles_individual <- function(search_string,
                                             page_size = 1,
                                             min_date,
                                             max_date,
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
    is.character(search_string),
    length(search_string) == 1,
    is.numeric(page_size),
    page_size > 0,
    is.character(media_id) | is.numeric(media_id) | is.null(media_id),
    is.character(min_date),
    is.character(max_date),
    nchar(min_date) == 10,
    nchar(max_date) == 10,
    is.logical(return_df),
    is.logical(log),
    is.character(log_path),
    is.character(newton_api_token),
    nchar(newton_api_token) > 30
  )
  # Add log printing for long extractions
  if (log == TRUE) {
    # Custom function to print console output to a file
    cat_sink <- function(..., file = paste0(log_path, "get_full_articles_individual_log.txt"), append = TRUE) {
      cat(..., file = file, append = append)
    }
  }

  # 3. Loop over pages ------------------------------------------

     full_article <- GET(
      url = "https://api.newtonmedia.eu/v2/archive/archives/search",
      httr::add_headers(
        Accept = "application/json",
        Authorization = paste("token", as.character(newton_api_token)),
        Connection = "keep-alive",
        `Accept-Encoding` = "gzip, deflate, br"
      ),
      query = list(
        page = 1,
        size = page_size,
        query = search_string,
        from = min_date,
        to = max_date,
        sourceIds = media_id
      )
    )

    if (httr::status_code(full_article) == 500) {
      cat_sink("\nWARNING: API call for article from media id", media_id, "between dates", min_date, "-", max_date, "failed with error code 500. Missing data are likely.")

      # Replace with empty dataset so bind_row at the end is successful
      full_article <- tibble()

    } else if (httr::status_code(full_article) == 200 & as.numeric(full_article$headers$`content-length`) < 50) {

      cat_sink("\nWARNING: API call for article from media id", media_id, "between dates", min_date, "-", max_date, "probably failed because content lenght is lower than expected.")

      # Replace with empty dataset so bind_row at the end is successful
      full_article <- tibble()

    } else if (httr::status_code(full_article) == 200 & as.numeric(full_article$headers$`content-length`) >= 50) {
      full_article <- full_article %>%
        content(as = "text") %>%
        fromJSON(flatten = TRUE) %>%
        .[, !colnames(.) %in% c(
          "LanguageCode",
          "Annotation"
        )]

      cat_sink("\n\nExtraction of article from media id", media_id, "between dates", min_date, "-", max_date, "; using the following search string:", search_string,  "; has finished.\n")
    } else {
      cat_sink("\nWARNING: API call for article from media id", media_id, "between dates", min_date, "-", max_date, "returned the following code:", httr::status_code(full_article), ". Check the connection.")
    }

  if (return_df == TRUE) {
    return(bind_rows(full_article))
  } else if (return_df == FALSE) {
    return(full_article)
  }

}
