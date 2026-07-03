rb_sql_conditions <- function(con, species = NULL, genus = NULL, family = NULL,
                              marker = NULL, source = NULL, occurrence = NULL,
                              qc_flag = NULL) {
  conditions <- character()
  add_in <- function(field, values) {
    if (is.null(values)) return(NULL)
    quoted_field <- as.character(DBI::dbQuoteIdentifier(con, field))
    paste0(quoted_field, " in (", rb_quote_in(con, values), ")")
  }
  conditions <- c(
    conditions,
    add_in("species", species),
    add_in("genus", genus),
    add_in("family", family),
    add_in("seq_type", marker),
    add_in("source", source),
    add_in("occurrence", occurrence)
  )
  if (!is.null(qc_flag)) {
    if (identical(qc_flag, "pass")) {
      conditions <- c(conditions, "qc_flag = 'pass'")
    } else {
      pattern <- DBI::dbQuoteString(con, paste0("%", qc_flag, "%"))
      conditions <- c(conditions, paste0("qc_flag like ", pattern))
    }
  }
  conditions[!is.na(conditions) & nzchar(conditions)]
}

rb_get_sequences <- function(con, species = NULL, genus = NULL, family = NULL,
                             marker = NULL, source = NULL, occurrence = NULL,
                             qc_flag = "pass") {
  conditions <- rb_sql_conditions(
    con, species = species, genus = genus, family = family,
    marker = marker, source = source, occurrence = occurrence, qc_flag = qc_flag
  )
  sql <- "select * from yzfishdb_final"
  if (length(conditions) > 0) {
    sql <- paste(sql, "where", paste(conditions, collapse = " and "))
  }
  DBI::dbGetQuery(con, sql)
}

rb_list_taxa <- function(con, rank = "species", occurrence = NULL, marker = NULL) {
  valid <- c("kingdom", "phylum", "class", "order", "family", "genus", "species")
  if (!rank %in% valid) stop("Unsupported rank: ", rank, call. = FALSE)
  rank_sql <- as.character(DBI::dbQuoteIdentifier(con, rank))
  conditions <- rb_sql_conditions(con, occurrence = occurrence, marker = marker, qc_flag = "pass")
  sql <- paste0("select ", rank_sql, " as ", rank, ", count(*) as n_sequences from yzfishdb_final")
  if (length(conditions) > 0) {
    sql <- paste(sql, "where", paste(conditions, collapse = " and "))
  }
  sql <- paste(sql, "group by", rank_sql, "order by", rank_sql)
  DBI::dbGetQuery(con, sql)
}

rb_filter_reference <- function(data, marker = NULL, source = NULL, occurrence = NULL,
                                min_length = NULL, max_length = NULL) {
  out <- data
  if (!is.null(marker)) out <- out[out$seq_type %in% marker, , drop = FALSE]
  if (!is.null(source)) out <- out[out$source %in% source, , drop = FALSE]
  if (!is.null(occurrence)) out <- out[out$occurrence %in% occurrence, , drop = FALSE]
  seq_len <- nchar(rb_clean_sequence(out$sequence))
  if (!is.null(min_length)) out <- out[seq_len >= min_length, , drop = FALSE]
  if (!is.null(max_length)) out <- out[seq_len <= max_length, , drop = FALSE]
  row.names(out) <- NULL
  out
}

rb_taxonomy <- function(con, species = NULL) {
  conditions <- rb_sql_conditions(con, species = species, qc_flag = "pass")
  sql <- paste(
    "select distinct kingdom, phylum, class, `order`, family, genus, species, occurrence, habitat",
    "from yzfishdb_final"
  )
  if (length(conditions) > 0) sql <- paste(sql, "where", paste(conditions, collapse = " and "))
  DBI::dbGetQuery(con, sql)
}
