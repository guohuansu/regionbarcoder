rb_write_fasta <- function(headers, sequences, file) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  lines <- character(length(headers) * 2)
  lines[seq(1, length(lines), by = 2)] <- headers
  lines[seq(2, length(lines), by = 2)] <- rb_clean_sequence(sequences)
  writeLines(lines, file, useBytes = TRUE)
  invisible(file)
}

rb_safe_id <- function(data) {
  if ("unique_code" %in% names(data)) {
    make.names(data$unique_code, unique = TRUE)
  } else if ("sequence_id" %in% names(data)) {
    make.names(data$sequence_id, unique = TRUE)
  } else {
    paste0("seq_", seq_len(nrow(data)))
  }
}

rb_export_fasta <- function(data, file, format = c("blastn", "dada2", "qiime2", "usearch"),
                            taxonomy_file = NULL) {
  format <- match.arg(format)
  switch(
    format,
    blastn = rb_export_blastn(data, file),
    dada2 = rb_export_dada2(data, file),
    qiime2 = rb_export_qiime2(data, file, taxonomy_file),
    usearch = rb_export_usearch(data, file)
  )
}

rb_export_blastn <- function(data, fasta_file) {
  rb_required_columns(data, c("sequence", "kingdom", "phylum", "class", "order", "family", "genus", "species"))
  tax <- rb_build_taxonomy_string(data, style = "plain")
  headers <- paste0(">", rb_safe_id(data), ";", tax)
  rb_write_fasta(headers, data$sequence, fasta_file)
}

rb_export_dada2 <- function(data, fasta_file) {
  rb_required_columns(data, c("sequence", "kingdom", "phylum", "class", "order", "family", "genus", "species"))
  tax <- rb_build_taxonomy_string(data, style = "plain")
  headers <- paste0(">", rb_safe_id(data), ";tax=", tax)
  rb_write_fasta(headers, data$sequence, fasta_file)
}

rb_export_qiime2 <- function(data, fasta_file, taxonomy_file) {
  if (is.null(taxonomy_file)) stop("taxonomy_file is required for QIIME2 export.", call. = FALSE)
  rb_required_columns(data, c("sequence", "kingdom", "phylum", "class", "order", "family", "genus", "species"))
  ids <- rb_safe_id(data)
  rb_write_fasta(paste0(">", ids), data$sequence, fasta_file)
  tax <- rb_build_taxonomy_string(data, style = "rank_prefix")
  lines <- c("Feature ID\tTaxon", paste(ids, tax, sep = "\t"))
  dir.create(dirname(taxonomy_file), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, taxonomy_file, useBytes = TRUE)
  invisible(list(fasta = fasta_file, taxonomy = taxonomy_file))
}

rb_export_usearch <- function(data, fasta_file) {
  rb_required_columns(data, c("sequence", "kingdom", "phylum", "class", "order", "family", "genus", "species"))
  tax <- rb_build_taxonomy_string(data, style = "rank_prefix")
  headers <- paste0(">", rb_safe_id(data), " tax=", tax)
  rb_write_fasta(headers, data$sequence, fasta_file)
}
