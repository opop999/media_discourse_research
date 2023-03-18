get_history_id <- function(media_name_vec,
                           media_types_vec,
                           page_size,
                           newton_api_token,
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
    is.character(media_name_vec),
    is.numeric(page_size),
    page_size > 0,
    is.numeric(media_types_vec),
    media_types_vec %in% c(2, 3, 4, 5),
    is.character(newton_api_token),
    nchar(newton_api_token) > 30,
    length(media_name_vec) == length(media_types_vec),
    !is.na(media_name_vec),
    !is.na(media_types_vec)
  )

  # Add log printing for long extractions
  if (log == TRUE) {
    # Custom function to print console output to a file
    cat_sink <-
      function(...,
               file = paste0(log_path, "get_history_id_log.txt"),
               append = TRUE) {
        cat(..., file = file, append = append)
      }
  } else {
    cat_sink <- cat
  }

  cat_sink("\n>--------------------<\n\n", as.character(Sys.time()))
  cat_sink(
    "\nThe total number of media names & the total amount of API calls:",
    length(media_name_vec),
    "\n"
  )

  # 2. Loop over each media name ------------------------------------------

  ## Create empty list to append results to
  articles_id_list <- vector(mode = "list", length = length(media_name_vec))

  for (i in seq_along(media_name_vec)) {
    articles_id_list[[i]] <- httr::RETRY(
      verb = "POST",
      url = "https://api.newtonmedia.eu/v2/archive/filter/sourceautocomplete",
      config = httr::add_headers(
        Accept = "application/json",
        `Content-Type` = "application/json",
        Authorization = paste("token", as.character(newton_api_token))
      ),
      encode = "json",
      body = toJSON(list(
        SourceName = unbox(media_name_vec[[i]]),
        AllowedMediaType = media_types_vec[[i]],
        PageSize = unbox(page_size)
      ))
    )

    if (httr::status_code(articles_id_list[[i]]) == 500) {
      cat_sink("\nWARNING: API call nr.", i, " failed with error code 500. Missing data are likely.")

      # Replace with NA if failed data extraction
      articles_id_list[[i]] <- NA
    } else if (httr::status_code(articles_id_list[[i]]) == 200) {
      articles_id_list[[i]] <- articles_id_list[[i]] %>%
        content(as = "parsed") %>%
        .[["sources"]] %>%
        lapply(., function(x) {
          c(x, searched_name = media_name_vec[[i]])
        })

      cat_sink("\nAPI call nr.", i, "executed sucessfully")
      cat("\nAPI call nr.", i, "executed sucessfully")
    } else {
      stop("\nWARNING: API call nr.", i, " returned the following code: ", httr::status_code(articles_id_list[[i]]), ". Check the connection.")
    }

    # Random wait time as not to overwhelm the API
    pause <- runif(1, 0.1, 0.2)
    cat_sink("\nPausing for", pause, "seconds.\n")
    Sys.sleep(pause)
  }

  cat_sink(
    "\nSUMMARY: Total amount of media names for this period is", length(media_name_vec),
    "\nAmount collected:", sum(!is.na(articles_id_list)),
    "\nAbsolute difference of", abs(length(media_name_vec) - sum(!is.na(articles_id_list))), "\n"
  )
  return(articles_id_list)
}
