rb_marker_coverage <- function(con, rank = "species") {
  valid <- c("species", "genus", "family", "order")
  if (!rank %in% valid) stop("Unsupported rank: ", rank, call. = FALSE)
  rank_sql <- as.character(DBI::dbQuoteIdentifier(con, rank))
  sql <- paste0(
    "select ", rank_sql, " as ", rank, ", seq_type, count(*) as n_sequences, ",
    "count(distinct source) as n_sources from yzfishdb_final ",
    "where qc_flag = 'pass' group by ", rank_sql, ", seq_type ",
    "order by ", rank_sql, ", seq_type"
  )
  DBI::dbGetQuery(con, sql)
}

rb_source_coverage <- function(con) {
  DBI::dbGetQuery(con, paste(
    "select source, seq_type, count(*) as n_sequences,",
    "count(distinct species) as n_species",
    "from yzfishdb_final where qc_flag = 'pass'",
    "group by source, seq_type order by source, seq_type"
  ))
}

rb_qc_summary <- function(con) {
  if ("qc_reference_p2" %in% DBI::dbListTables(con)) {
    DBI::dbGetQuery(con, paste(
      "select qc_flag, count(*) as n_sequences",
      "from qc_reference_p2 group by qc_flag order by n_sequences desc"
    ))
  } else {
    DBI::dbGetQuery(con, paste(
      "select qc_flag, count(*) as n_sequences",
      "from yzfishdb_final group by qc_flag order by n_sequences desc"
    ))
  }
}

rb_barcode_gap <- function(con, species = NULL, marker = NULL) {
  if (!"barcode_gap_metrics" %in% DBI::dbListTables(con)) {
    return(data.frame())
  }
  conditions <- character()
  if (!is.null(species)) conditions <- c(conditions, paste0("species in (", rb_quote_in(con, species), ")"))
  if (!is.null(marker)) conditions <- c(conditions, paste0("marker in (", rb_quote_in(con, marker), ")"))
  sql <- "select * from barcode_gap_metrics"
  if (length(conditions) > 0) sql <- paste(sql, "where", paste(conditions, collapse = " and "))
  DBI::dbGetQuery(con, sql)
}

rb_ambiguity <- function(con) {
  if (!"ambiguous_sequences" %in% DBI::dbListTables(con)) {
    return(data.frame())
  }
  DBI::dbGetQuery(con, "select * from ambiguous_sequences")
}

rb_read_barcode_gap <- function(path = NULL, species = NULL, marker = NULL) {
  if (is.null(path)) {
    path <- rb_default_data_file("barcode_gap_metrics_enhanced.csv")
  }
  if (!nzchar(path) || !file.exists(path)) {
    stop("Barcode gap metrics file does not exist: ", path, call. = FALSE)
  }
  gap <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  if (!is.null(species)) gap <- gap[gap$species %in% species, , drop = FALSE]
  if (!is.null(marker)) gap <- gap[gap$marker %in% marker, , drop = FALSE]
  row.names(gap) <- NULL
  gap
}

rb_read_ambiguity <- function(path = NULL, action = NULL) {
  if (is.null(path)) {
    path <- rb_default_data_file("ambiguous_sequences_tbl_cleaned.csv")
  }
  if (!nzchar(path) || !file.exists(path)) {
    stop("Ambiguous sequence table does not exist: ", path, call. = FALSE)
  }
  amb <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  if (!is.null(action)) amb <- amb[amb$action %in% action, , drop = FALSE]
  row.names(amb) <- NULL
  amb
}
