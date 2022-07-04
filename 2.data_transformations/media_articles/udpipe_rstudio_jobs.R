source(file.path("udpipe_api_process.R"))

for (o in seq_along(all_chunks_path_udpipe)) {

  one_chunk <- readRDS(all_chunks_path_udpipe[[o]])

  udpipe_df_chunk <- udpipe_process(article_id = one_chunk$article_id,
                                    article_text = one_chunk$text,
                                    log_path = file.path("docs/"))

  saveRDS(udpipe_df_chunk, paste0(file.path("data", "udpipe_processed", "chunks", "udpipe_"), all_chunks_name_udpipe[[o]]))

  rm(udpipe_df_chunk, one_chunk)

  gc()

  cat("\nThe following chunk was processed by UDPIPE and saved locally:", all_chunks_name_udpipe[[o]], "\n")

  # Pause ~10 mins between chunks
  Sys.sleep(abs(rnorm(1, 600, sd = 100)))

}
