source(file.path("ner_nametag_api.R"))

for (o in seq_along(all_chunks_path_ner)) {

  one_chunk <- readRDS(all_chunks_path_ner[[o]])

  nametag_df_chunk <- nametag_process(article_id = one_chunk$article_id,
                                      article_text = one_chunk$text,
                                      log_path = file.path("docs/"))

  saveRDS(nametag_df_chunk, paste0(file.path("data", "chunks", "nametag_") , all_chunks_name_ner[[o]]))

  rm(nametag_df_chunk, one_chunk)
  gc()

  cat("\nThe following chunk was processed by NameTag and saved locally:", all_chunks_name_ner[[o]], "\n")

  # Pause cca 10 mins between chunks
  Sys.sleep(abs(rnorm(1, 600, sd = 100)))

}
