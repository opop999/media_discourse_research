extract_full_articles <- function(search_string,
                                  page_size = 100,
                                  min_date,
                                  max_date,
                                  sort = "PublishDate_desc",
                                  newton_api_token,
                                  media_history_id = NULL,
                                  media_id = NULL,
                                  duplicities = FALSE,
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
    is.numeric(media_history_id) | is.null(media_history_id),
    is.numeric(media_id) | is.null(media_id),
    is.character(min_date),
    is.character(max_date),
    nchar(min_date) == 10,
    nchar(max_date) == 10,
    is.character(sort),
    is.logical(duplicities),
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
               file = paste0(log_path, "get_full_articles_log.txt"),
               append = TRUE) {
        cat(..., file = file, append = append)
      }
  } else {
    cat_sink <- cat
  }

  cat_sink("\n>--------------------<\n\n", as.character(Sys.time()))

  # 2. Get total number of results ------------------------------------------
  total_results <- httr::POST(
      url = "https://api.newtonmedia.eu/v2/archive/searchCount",
      httr::add_headers(
        Accept = "application/json",
        `Content-Type` = "application/json",
        Authorization = paste("token", as.character(newton_api_token)),
        Connection = "keep-alive",
        `Accept-Encoding` = "gzip, deflate, br"
      ),
      encode = "json",
      body = toJSON(list(
        QueryText = unbox(search_string),
        DateFrom = unbox(paste0(min_date, "T00:00:00")),
        DateTo = unbox(paste0(as.Date(max_date) - 1, "T23:59:59")),
        showDuplicities = unbox(duplicities),
        sourceHistoryIds = media_history_id
      ))
    ) %>%
      content(as = "parsed") %>%
      .[["count"]]

  if (is.null(total_results))  {
    stop("\nUnable to retrieve the total number of results for this time window. Check the API.\n")
    } else if (total_results > 10000) {
    cat_sink(
      "\nWARNING: Total number of news items within selected time period is larger than 10000.\n",
      "Articles above this limit will not be saved. Consider shortening the time window.\n"
    )
  }  else {
    cat_sink("\nOK: Total number of news items is under the limit of 10000.\n")
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
  full_articles_list <- vector(mode = "list", length = total_pages)

  # Start counting the extraction length
  start_time <- Sys.time()

  for (i in seq_len(total_pages)) {

    full_articles_list[[i]] <- GET(
      url = "https://api.newtonmedia.eu/v2/archive/archives/search",
      httr::add_headers(
        Accept = "application/json",
        Authorization = paste("token", as.character(newton_api_token))
      ),
      query = list(
        page = i,
        size = page_size,
        query = search_string,
        from = min_date,
        to = max_date,
        orderBy = sort,
        sourceIds = media_id
      )
    )

    if (httr::status_code(full_articles_list[[i]]) == 500) {
      cat_sink("\nWARNING: API call nr.", i, " failed with error code 500. Missing data are likely.")

      # Replace with empty dataset so bind_row at the end is successful
      full_articles_list[[i]] <- tibble()

    } else if (httr::status_code(full_articles_list[[i]]) == 200) {
      full_articles_list[[i]] <- full_articles_list[[i]] %>%
        content(as = "text") %>%
        fromJSON(flatten = TRUE) %>%
        .[, !colnames(.) %in% c(
          "LanguageCode",
          "Annotation"
        )]

      cat_sink("\nAPI call nr.", i, "executed. The number of rows is", nrow(full_articles_list[[i]]))
    } else {
      cat_sink("\nWARNING: API call nr.", i, " returned the following code: ", httr::status_code(full_articles_list[[i]]), ". Check the connection.")
    }

    # Random wait time as not to overwhelm the API
    pause <- runif(1, 0.2, 1)
    cat_sink("\nPausing for", pause, "seconds.\n")
    Sys.sleep(pause)
  }

  cat_sink(
    "\nSUMMARY: Total amount of articles for this period is", total_results,
    "\nAmount collected:", sum(unlist(lapply(full_articles_list, nrow))),
    "\nAbsolute difference of", abs(total_results - sum(unlist(lapply(full_articles_list, nrow)))), "\n",
    "\n\nExtraction of the period from", min_date, "to", max_date, "(excluding) has finished.\n")

  print(Sys.time() - start_time)

  cat_sink("\n>--------------------<\n\n")

  if (return_df == TRUE) {
    return(bind_rows(full_articles_list))
  } else if (return_df == FALSE) {
    return(full_articles_list)
  }

}
