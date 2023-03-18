# This function extracts media articles according to selected criteria.
# The output is a list of datasets, which contain article title and annotation.

extract_annotated_articles <- function(search_string,
                                       page_size,
                                       min_date,
                                       max_date,
                                       country = c(1, 2),
                                       media_types = c(2, 3, 4, 5),
                                       sort = 2,
                                       section = NULL,
                                       media_history_id = NULL,
                                       duplicities = FALSE,
                                       newton_api_token,
                                       return_df = TRUE,
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
    is.logical(log),
    is.character(log_path),
    is.character(search_string),
    length(search_string) == 1,
    is.numeric(page_size),
    page_size > 0 & page_size <= 10000,
    is.character(section) | is.null(section),
    is.numeric(media_history_id) | is.null(media_history_id),
    is.character(min_date),
    is.character(max_date),
    nchar(min_date) == 19,
    nchar(max_date) == 19,
    is.numeric(country),
    country %in% c(1, 2),
    is.numeric(media_types),
    media_types %in% c(2, 3, 4, 5),
    is.numeric(sort),
    sort %in% c(1, 2, 3),
    is.logical(duplicities),
    is.logical(return_df),
    is.character(newton_api_token),
    nchar(newton_api_token) > 30
  )
  # Add log printing for long extractions
  if (log == TRUE) {
    # Custom function to print console output to a file
    cat_sink <-
      function(...,
               file = paste0(log_path, "get_annotated_articles_log.txt"),
               append = TRUE) {
        cat(..., file = file, append = append)
      }
  } else {
    cat_sink <- cat
  }

  cat_sink("\n>--------------------<\n\n", as.character(Sys.time()))

  # 2. Get total number of results ------------------------------------------

  get_total_results <- function() {
    httr::RETRY(
      verb = "POST",
      url = "https://api.newtonmedia.eu/v2/archive/searchCount",
      config = httr::add_headers(
        Accept = "application/json",
        `Content-Type` = "application/json",
        Authorization = paste("token", as.character(newton_api_token))
      ),
      encode = "json",
      body = toJSON(list(
        QueryText = unbox(search_string),
        DateFrom = unbox(min_date),
        DateTo = unbox(max_date),
        showDuplicities = unbox(duplicities),
        AllowedMediaTypeIds = media_types,
        CountryIds = country,
        SectionQuery = section,
        sourceHistoryIds = media_history_id
      ))
    ) %>%
      content(as = "parsed") %>%
      .[["count"]]
  }

  total_results <- get_total_results()

  if (is.null(total_results)) {
    stop("\nWARNING: Total number of news items undetermined. Authentication likely denied.")
  } else if (total_results > 10000) {
    cat_sink(
      "\nWARNING: Total number of news items within selected time period is larger than 10000.\n",
      "Articles above this limit will not be saved. Consider shortening the time window.\n"
    )
  } else if (total_results <= 10000) {
    cat_sink("\nTotal number of news items is under the limit of 10000.\n")
  }

  total_pages <- ceiling(total_results / page_size)

  cat_sink(
    "\nWithin the search period of",
    min_date, "-", max_date, ":",
    "\nThe number of total results is:", total_results,
    "\nThe selected page size is:", page_size,
    "\nTotal number of API calls will be:", total_pages, "\n"
  )

  # 3. Loop over pages ------------------------------------------

  ## Create empty list to append results to
  annotated_articles_list <- vector(mode = "list", length = total_pages)

  if (total_pages >= 1) {
    for (i in seq_len(total_pages)) {
      annotated_articles_list[[i]] <- httr::RETRY(
        verb = "POST",
        url = "https://api.newtonmedia.eu/v2/archive/search",
        config = httr::add_headers(
          Accept = "application/json",
          `Content-Type` = "application/json",
          Authorization = paste("token", as.character(newton_api_token)),
          Connection = "keep-alive",
          `Accept-Encoding` = "gzip, deflate, br"
        ),
        encode = "json",
        body = toJSON(list(
          QueryText = unbox(search_string),
          DateFrom = unbox(min_date),
          DateTo = unbox(max_date),
          CurrentPage = unbox(i),
          PageSize = unbox(page_size),
          Sorting = unbox(sort),
          showDuplicities = unbox(duplicities),
          AllowedMediaTypeIds = media_types,
          CountryIds = country,
          SectionQuery = section,
          sourceHistoryIds = media_history_id
        ))
      )

      if (httr::status_code(annotated_articles_list[[i]]) == 500) {
        cat_sink("\nWARNING: API call nr.", i, " failed with error code 500. Missing data are likely.")

        # Replace with empty dataset so bind_row at the end is successful
        annotated_articles_list[[i]] <- tibble()
      } else if (httr::status_code(annotated_articles_list[[i]]) == 200) {
        annotated_articles_list[[i]] <- annotated_articles_list[[i]] %>%
          content(as = "text") %>%
          fromJSON(flatten = TRUE) %>%
          # Remove columns that do not provide any useful information to our research or are duplicates
          .[["articles"]] %>%
          .[, !colnames(.) %in% c(
            "language",
            "isRead",
            "isBookmarked",
            "userQueryId",
            "mediaType.code",
            "mediaType.name"
          )]

        cat_sink("\nAPI call nr.", i, "executed. The number of rows is", nrow(annotated_articles_list[[i]]))
      } else {
        cat_sink(
          "\nWARNING: API call nr.", i, " returned the following code: ",
          httr::status_code(annotated_articles_list[[i]]), ". Check the connection."
        )
      }

      # Random wait time as not to overwhelm the API
      pause <- runif(1, 0.5, 2)
      cat_sink("\nPausing for", pause, "seconds.\n")
      Sys.sleep(pause)
    }
  } else if (total_pages == 0) {
    cat_sink("\nNo results for the selected period, skipping extraction.\n")
  }
  cat_sink(
    "\nSUMMARY: Total amount of articles for this period is", total_results,
    "\nAmount collected:", sum(unlist(lapply(annotated_articles_list, nrow))),
    "\nAbsolute difference of", abs(total_results - sum(unlist(lapply(annotated_articles_list, nrow)))),
    "\n>--------------------<\n\n"
  )

  if (return_df == TRUE) {
    return(bind_rows(annotated_articles_list))
  } else if (return_df == FALSE) {
    return(annotated_articles_list)
  }
}
