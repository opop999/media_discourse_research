# 0. Load libraries ------------------------------------------

# Package names
packages <- c("googledrive", "dplyr")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# 1. Pull files from remote, which do not exist locally -------------------

fetch_remote_files <- function(local_folder_path, remote_folder_path) {

  # Get files in the remote folder, compare which ones are missing in local
  local_files <- list.files(local_folder_path)
  remote_files <- drive_ls(remote_folder_path) %>% pull("name")
  files_to_fetch <- setdiff(remote_files, local_files)

  if (!length(files_to_fetch) ==  0) {
    for (i in seq_along(files_to_fetch)) {

      drive_download(
        file = paste0(remote_folder_path, files_to_fetch[[i]]),
        path = paste0(local_folder_path, files_to_fetch[[i]]),
        overwrite = FALSE
      )
      print(paste("File nr.", i, "out of", length(files_to_fetch), "finished donwloading."))
    }
  } else {
    print("No files on remote that would be missing locally. Sync OK.")
  }
}

# 2. Backup local folder: Upload files that are present locally -----------

backup_local_files <- function(local_folder_path, remote_folder_path) {

  # Get files in the local and remote folder, compare which ones are missing in remote
  local_files <- list.files(local_folder_path)
  remote_files <- drive_ls(remote_folder_path) %>% pull("name")
  files_to_back_up <- setdiff(local_files, remote_files)

  if (!length(files_to_back_up) ==  0) {
    for (i in seq_along(files_to_back_up)) {

      drive_upload(
        media = paste0(local_folder_path, files_to_back_up[[i]]),
        path = paste0(remote_folder_path, files_to_back_up[[i]]),
        overwrite = FALSE
      )
      print(paste("File nr.", i, "out of", length(files_to_back_up), "finished uploading."))
    }
  } else {
    print("No files on local that would be missing in remote. Sync OK.")
  }
}
# 3. Pull and Push -------------------

synchronize_selected_folders <- function(list_of_folders) {

  for (o in seq_along(list_of_folders)) {

    print(paste("<-- STARTING SYNCHRONIZATION OF", toupper(names(list_of_folders[o])), "FOLDER -->"))

    # First, pull from remote
    fetch_remote_files(local_folder_path = list_of_folders[[o]][["local_folder_path"]],
                       remote_folder_path = list_of_folders[[o]][["remote_folder_path"]])

    # Then push from local to remote
    backup_local_files(local_folder_path = list_of_folders[[o]][["local_folder_path"]],
                       remote_folder_path = list_of_folders[[o]][["remote_folder_path"]])

    print(paste("<-- SYNCHRONIZATION OF FOLDER", toupper(names(list_of_folders[o])), "FINISHED -->"))
    print("======================================================================")

  }
print("END: ALL PROVIDED FOLDERS HAVE BEEN SYNCHRONIZED WITH REMOTE GOOGLE DRIVE REPOSITORY")
}
