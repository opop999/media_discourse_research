# Pre-processes a character vector of text according to provided regex pattern,
# while removing extra space

pattern_preprocessing_cs <- function(text_vector, main_pattern) {
  # 0. Load libraries ------------------------------------------
  # Package names
  packages <- c("stringi")

  # Install packages not yet installed
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)) {
    install.packages(packages[!installed_packages])
  }

  # Packages loading
  invisible(lapply(packages, library, character.only = TRUE))

  stri_trim_both(gsub(pattern = "  +",
                      replacement = " ",
                      x = gsub(pattern = main_pattern,
                               replacement = " ",
                               x = text_vector)))

}

