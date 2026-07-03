rb_db_url <- function() {
  env_url <- Sys.getenv("RB_YZFISHDB_URL", "")
  if (nzchar(env_url)) return(env_url)
  opt_url <- getOption("regionbarcoder.yzfishdb_url", "")
  if (is.null(opt_url)) return("")
  as.character(opt_url)
}

rb_db_dir <- function(create = TRUE) {
  cache_dir <- Sys.getenv("RB_YZFISHDB_CACHE_DIR", "")
  if (!nzchar(cache_dir)) {
    cache_dir <- tools::R_user_dir("regionbarcoder", which = "data")
  }
  if (isTRUE(create) && !dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  normalizePath(cache_dir, winslash = "/", mustWork = dir.exists(cache_dir))
}

rb_db_path <- function(filename = "YZFishDB.db") {
  file.path(rb_db_dir(), filename)
}

rb_db_available <- function(path = rb_db_path()) {
  nzchar(path) && file.exists(path)
}

rb_install_db <- function(url = rb_db_url(), destfile = rb_db_path(),
                          overwrite = FALSE, sha256 = NULL,
                          min_bytes = 1, quiet = FALSE) {
  if (file.exists(destfile) && !isTRUE(overwrite)) {
    return(normalizePath(destfile, winslash = "/", mustWork = TRUE))
  }
  if (!nzchar(url)) {
    stop(
      "No YZFishDB download URL is configured. ",
      "Set RB_YZFISHDB_URL, set option regionbarcoder.yzfishdb_url, ",
      "or pass url = '...' to rb_install_db().",
      call. = FALSE
    )
  }

  dest_dir <- dirname(destfile)
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  }

  tmp <- tempfile("YZFishDB-", fileext = ".db")
  on.exit(unlink(tmp), add = TRUE)
  rb_download_file(url, tmp, quiet = quiet)

  file_size <- file.info(tmp)$size
  if (is.na(file_size) || file_size < min_bytes) {
    stop("Downloaded YZFishDB file is empty or incomplete.", call. = FALSE)
  }
  if (!is.null(sha256)) {
    observed <- unname(tools::sha256sum(tmp))
    if (!identical(tolower(observed), tolower(sha256))) {
      stop("Downloaded YZFishDB checksum does not match expected sha256.", call. = FALSE)
    }
  }

  ok <- file.copy(tmp, destfile, overwrite = TRUE)
  if (!isTRUE(ok)) {
    stop("Could not write YZFishDB database to: ", destfile, call. = FALSE)
  }
  normalizePath(destfile, winslash = "/", mustWork = TRUE)
}

rb_download_file <- function(url, destfile, quiet = FALSE) {
  if (file.exists(url)) {
    ok <- file.copy(url, destfile, overwrite = TRUE)
    if (!isTRUE(ok)) {
      stop("Could not copy local YZFishDB file: ", url, call. = FALSE)
    }
    return(invisible(destfile))
  }

  if (grepl("^file://", url)) {
    local_path <- utils::URLdecode(sub("^file:///?", "", url))
    if (.Platform$OS.type == "windows") {
      local_path <- sub("^([A-Za-z]):", "\\1:", local_path)
    }
    ok <- file.copy(local_path, destfile, overwrite = TRUE)
    if (!isTRUE(ok)) {
      stop("Could not copy local YZFishDB file: ", local_path, call. = FALSE)
    }
    return(invisible(destfile))
  }

  status <- utils::download.file(url, destfile, mode = "wb", quiet = quiet)
  if (!identical(status, 0L)) {
    stop("Could not download YZFishDB from: ", url, call. = FALSE)
  }
  invisible(destfile)
}
