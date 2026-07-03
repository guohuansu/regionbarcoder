rb_available_datasets <- function() {
  demo_path <- system.file("extdata", "small_yzfishdb.sqlite", package = "regionbarcoder")
  if (!nzchar(demo_path)) {
    demo_path <- rb_find_full_yzfishdb()
  }
  if (!nzchar(demo_path)) {
    demo_path <- rb_demo_db_path()
  }
  data.frame(
    name = "small_yzfishdb",
    version = if (grepl("YZFishDB[.]db$", demo_path)) "full-local" else "demo",
    path = demo_path,
    stringsAsFactors = FALSE
  )
}

rb_connect <- function(path = NULL, download = FALSE, url = rb_db_url()) {
  if (is.null(path)) {
    if (isTRUE(download) && !file.exists(rb_db_path())) {
      path <- rb_install_db(url = url)
    } else {
      path <- rb_available_datasets()$path[[1]]
    }
  }
  if (!nzchar(path) || !file.exists(path)) {
    stop("Database file does not exist: ", path, call. = FALSE)
  }
  DBI::dbConnect(RSQLite::SQLite(), normalizePath(path, winslash = "/", mustWork = TRUE))
}

rb_disconnect <- function(con) {
  if (DBI::dbIsValid(con)) {
    DBI::dbDisconnect(con)
  }
  invisible(TRUE)
}

rb_tables <- function(con) {
  tables <- DBI::dbListTables(con)
  counts <- vapply(tables, function(tab) {
    quoted <- as.character(DBI::dbQuoteIdentifier(con, tab))
    DBI::dbGetQuery(con, paste0("select count(*) as n from ", quoted))[[1]]
  }, numeric(1))
  data.frame(table = tables, n_rows = as.integer(counts), stringsAsFactors = FALSE)
}

rb_read_table <- function(con, table) {
  available <- DBI::dbListTables(con)
  if (!table %in% available) {
    stop("Table not found: ", table, call. = FALSE)
  }
  DBI::dbReadTable(con, table)
}
