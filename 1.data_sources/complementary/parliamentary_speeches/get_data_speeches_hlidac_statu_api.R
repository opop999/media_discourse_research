## 1. Loading the required R libraries

# Package names
packages <- c("httr", "dplyr", "jsonlite")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# API call to query the details of the required dataset for more detailed info
dataset_detail <- fromJSON(content(
  httr::RETRY(
    verb = "GET",
    url = "https://www.hlidacstatu.cz/api/v2/datasety/stenozaznamy-psp",
    config = httr::add_headers(
      accept = "application/json",
      Authorization = Sys.getenv("HS_TOKEN")
    )
  ),
  as = "text"
))

# Function that gets all of the speeches with given parameters
get_all_speeches <- function(dir_name, sort, descending, token, query_string) {
  # Get total number of pages from the initial result. We divide the number of
  # total posts by 25 (this is the size of one API page) and apply ceiling to get a
  # full number
  pages <- ceiling(
    fromJSON(
      content(
        httr::RETRY(
          verb = "GET",
          url = "https://www.hlidacstatu.cz/api/v2/datasety/stenozaznamy-psp/hledat",
          config = httr::add_headers(
            accept = "application/json",
            Authorization = token
          ),
          query = list(
            dotaz = query_string,
            sort = sort,
            desc = descending
          )
        ),
        as = "text"
      )
    )[[1]] / 25
  )

  # We initialize empty list to which we add items with each loop iteration
  hlidac_data <- vector(mode = "list", length = pages)

  # Hlidac's API supports an upper limit of 200 pages so we have to
  # set an upper hard limit
  for (i in seq_len(pages)[seq_len(pages) <= 200]) {
    # Send GET request to the API of Hlidac Statu and transform JSON output to a list of dataframes
    hlidac_data[[i]] <- fromJSON(
      content(
        httr::RETRY(
          verb = "GET",
          url = "https://www.hlidacstatu.cz/api/v2/datasety/stenozaznamy-psp/hledat",
          config = httr::add_headers(
            accept = "application/json",
            Authorization = token
          ),
          query = list(
            dotaz = query_string,
            strana = i,
            sort = sort,
            desc = descending
          )
        ),
        as = "text"
      ),
      flatten = TRUE
    )[[3]]
  }

  # Transform the list of dataframes to one large dataframe
  hlidac_data_df <- bind_rows(hlidac_data)

  # Remove completely empty columns
  hlidac_data_df <- hlidac_data_df[, !colnames(hlidac_data_df) %in% c("narozeni", "temata", "DbCreatedBy")]

  # Save full dataset in RDS format
  if (file.exists(paste0(dir_name, "/all_speeches.rds"))) {
    hlidac_data_df <- bind_rows(readRDS(paste0(dir_name, "/all_speeches.rds")), hlidac_data_df) %>%
      distinct()
  }

  saveRDS(object = hlidac_data_df, file = paste0(dir_name, "/all_speeches.rds"))
}


get_all_speeches(
  dir_name = "1.data_sources/complementary/parliamentary_speeches/data", # Specify the folder, where the tables will be saved
  sort = "datum", # Which column is used for sorting? We keep this consistent
  descending = 1, # 1 is descending sort, 0 is ascending. We keep this consistent
  token = Sys.getenv("HS_TOKEN"), # Hlidac Statu API token,
  # URL encoded query string that targets migration-related speeches
  # Decoded string: "běženec* OR běženk* OR imigrant* OR migra* OR imigra* OR přistěhoval* OR uprchl* OR utečen* OR azylant*"
  query_string = "b%C4%9B%C5%BEenec%2A%20OR%20b%C4%9B%C5%BEenk%2A%20OR%20imigrant%2A%20OR%20migra%2A%20OR%20imigra%2A%20OR%20p%C5%99ist%C4%9Bhoval%2A%20OR%20uprchl%2A%20OR%20ute%C4%8Den%2A%20OR%20azylant%2A"
)
