# This script programmatically downloads Vaclav Cvrcek et al.
# work on Czech media types from Google Sheets
library("googlesheets4")
last_update = "february_2022"

url_to_sheet <- Sys.getenv("MEDIA_TYPES_CVRCEK_URL")

# Get info about all individual sheets
gs4_get(url_to_sheet)
sheet_properties(url_to_sheet)

sheets <- sheet_names(url_to_sheet)

# We have two sheets of interest from two coders. One is coded by Vaclav Cvrcek, the second by Jan Henys.
labels_vc <- read_sheet(url_to_sheet, sheet = sheets[grep("VC", sheets, ignore.case = TRUE)], col_types = "ccnccccccccc")
labels_jh <- read_sheet(url_to_sheet, sheet = sheets[grep("JH", sheets, ignore.case = TRUE)], col_types = "ccnccccccccc")

saveRDS(labels_vc, paste0("1.data_sources/media_articles/data/media_type_labels/labels_vc_", last_update, ".rds"))
saveRDS(labels_jh, paste0("1.data_sources/media_articles/data/media_type_labels/labels_jh_", last_update, ".rds"))
