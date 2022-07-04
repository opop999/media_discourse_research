## 1. Loading the required R libraries

# Package names
packages <- c("httr", "dplyr", "jsonlite", "purrr")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

hlidac_data <- list()



# API call to query the details of the required dataset for more detailed info
dataset_detail <- fromJSON(
  content(
    httr::VERB(
      verb = "GET", url = "https://www.hlidacstatu.cz/api/v2/datasety/skutecni-majitele",
      httr::add_headers(accept = "application/json", Authorization = Sys.getenv("HS_TOKEN"))
    ),
    as = "text"
  )
)

sort <- "datum" # Which column is used for sorting? We keep this consistent
descending <- 1 # 1 is descending sort, 0 is ascending. We keep this consistent
dir_name <- "1. data_sources/complementary/parliamentary_speeches/data" # Specify the folder, where the tables will be saved
token <- Sys.getenv("HS_TOKEN") # Hlidac Statu API token

# URL encoded query string that targets migration-related speeches
# Decoded string: "běženec* OR běženk* OR imigrant* OR migra* OR imigra* OR přistěhoval* OR uprchl* OR utečen* OR azylant*"
query_string <- "CZECH%20NEWS%20CENTER%20a.s."

hlidac_data[[i]] <- fromJSON(content(httr::VERB(
  verb = "GET", url = "https://www.hlidacstatu.cz/api/v2/datasety/skutecni-majitele/hledat",
  httr::add_headers(
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
)[["results"]]

