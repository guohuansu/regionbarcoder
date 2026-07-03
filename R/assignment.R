rb_read_fasta <- function(path) {
  if (!file.exists(path)) stop("FASTA file does not exist: ", path, call. = FALSE)
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(lines)]
  header_idx <- which(startsWith(lines, ">"))
  if (length(header_idx) == 0) stop("No FASTA records found in: ", path, call. = FALSE)
  end_idx <- c(header_idx[-1] - 1, length(lines))
  ids <- sub("^>", "", lines[header_idx])
  ids <- sub("\\s.*$", "", ids)
  seqs <- vapply(seq_along(header_idx), function(i) {
    paste(lines[(header_idx[[i]] + 1):end_idx[[i]]], collapse = "")
  }, character(1))
  data.frame(asv_id = ids, sequence = rb_clean_sequence(seqs), stringsAsFactors = FALSE)
}

rb_score_assignments <- function(hits, min_identity = 99, min_coverage = 0.9,
                                 tie_bitscore = 0) {
  if (nrow(hits) == 0) {
    return(data.frame())
  }
  rb_required_columns(hits, c("asv_id", "species", "pident", "qcov", "evalue", "bitscore"))
  out <- lapply(split(hits, hits$asv_id), function(x) {
    x <- x[order(-x$bitscore, -x$pident, -x$qcov, x$evalue), , drop = FALSE]
    best <- x[1, , drop = FALSE]
    tied <- x[
      x$bitscore >= best$bitscore[[1]] - tie_bitscore &
        x$pident == best$pident[[1]] &
        x$qcov == best$qcov[[1]],
      ,
      drop = FALSE
    ]
    species <- sort(unique(tied$species))
    status <- if (length(species) == 1) "unique" else "ambiguous"
    confidence <- if (status == "ambiguous") {
      "ambiguous"
    } else if (best$pident[[1]] >= min_identity && best$qcov[[1]] >= min_coverage) {
      "high"
    } else {
      "low"
    }
    data.frame(
      asv_id = best$asv_id[[1]],
      species = paste(species, collapse = "|"),
      genus = paste(sort(unique(tied$genus)), collapse = "|"),
      family = paste(sort(unique(tied$family)), collapse = "|"),
      pident = best$pident[[1]],
      qcov = best$qcov[[1]],
      evalue = best$evalue[[1]],
      bitscore = best$bitscore[[1]],
      n_best_species = length(species),
      assignment_status = status,
      confidence = confidence,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

rb_exact_hits <- function(asvs, refs) {
  ref_seq <- rb_clean_sequence(refs$sequence)
  out <- lapply(seq_len(nrow(asvs)), function(i) {
    idx <- which(ref_seq == asvs$sequence[[i]])
    if (length(idx) == 0) return(NULL)
    x <- refs[idx, , drop = FALSE]
    data.frame(
      asv_id = asvs$asv_id[[i]],
      species = x$species,
      genus = x$genus,
      family = x$family,
      pident = 100,
      qcov = 1,
      evalue = 0,
      bitscore = nchar(asvs$sequence[[i]]),
      stringsAsFactors = FALSE
    )
  })
  out <- out[!vapply(out, is.null, logical(1))]
  if (length(out) == 0) return(data.frame())
  do.call(rbind, out)
}

rb_parse_blast_tabular <- function(path) {
  cols <- c(
    "asv_id", "subject_id", "pident", "length", "qlen", "slen",
    "evalue", "bitscore", "mismatch", "gapopen", "qstart", "qend",
    "sstart", "send"
  )
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(data.frame())
  }
  x <- utils::read.table(path, sep = "\t", header = FALSE, quote = "",
                         col.names = cols, stringsAsFactors = FALSE)
  x$qcov <- x$length / x$qlen
  x
}

rb_assign_blastn <- function(asv_fasta, refs, out_dir, min_identity, min_coverage,
                             max_target_seqs, blastn, makeblastdb) {
  if (!nzchar(Sys.which(blastn))) {
    stop("BLASTN executable not found: ", blastn, ". Install BLAST+ or use method = 'exact'.", call. = FALSE)
  }
  if (!nzchar(Sys.which(makeblastdb))) {
    stop("makeblastdb executable not found: ", makeblastdb, ". Install BLAST+ or use method = 'exact'.", call. = FALSE)
  }
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  ref_fasta <- file.path(out_dir, "regionbarcoder_reference.fasta")
  db_prefix <- file.path(out_dir, "regionbarcoder_reference")
  blast_out <- file.path(out_dir, "regionbarcoder_blast.tsv")
  rb_write_fasta(paste0(">", refs$unique_code), refs$sequence, ref_fasta)
  system2(makeblastdb, c("-in", ref_fasta, "-dbtype", "nucl", "-out", db_prefix),
          stdout = FALSE, stderr = FALSE)
  outfmt <- "6 qseqid sseqid pident length qlen slen evalue bitscore mismatch gapopen qstart qend sstart send"
  system2(blastn, c(
    "-query", asv_fasta,
    "-db", db_prefix,
    "-outfmt", outfmt,
    "-max_target_seqs", as.character(max_target_seqs),
    "-perc_identity", as.character(min_identity),
    "-out", blast_out
  ), stdout = FALSE, stderr = FALSE)
  hits <- rb_parse_blast_tabular(blast_out)
  if (nrow(hits) == 0) return(data.frame())
  meta <- refs[, c("unique_code", "species", "genus", "family"), drop = FALSE]
  names(meta)[1] <- "subject_id"
  hits <- merge(hits, meta, by = "subject_id", all.x = TRUE)
  hits[hits$qcov >= min_coverage, , drop = FALSE]
}

rb_assign_edna <- function(asv_fasta, con = NULL, db_path = NULL, marker = NULL,
                           method = c("blastn", "exact"), min_identity = 99,
                           min_coverage = 0.9, max_target_seqs = 20,
                           out_dir = tempfile("regionbarcoder_assign_"),
                           blastn = "blastn", makeblastdb = "makeblastdb") {
  method <- match.arg(method)
  own_connection <- FALSE
  if (is.null(con)) {
    con <- rb_connect(db_path)
    own_connection <- TRUE
  }
  on.exit(if (own_connection) rb_disconnect(con), add = TRUE)
  asvs <- rb_read_fasta(asv_fasta)
  refs <- rb_get_sequences(con, marker = marker)
  refs$sequence <- rb_clean_sequence(refs$sequence)
  if (method == "exact") {
    hits <- rb_exact_hits(asvs, refs)
  } else {
    hits <- rb_assign_blastn(
      asv_fasta = asv_fasta,
      refs = refs,
      out_dir = out_dir,
      min_identity = min_identity,
      min_coverage = min_coverage,
      max_target_seqs = max_target_seqs,
      blastn = blastn,
      makeblastdb = makeblastdb
    )
  }
  scored <- rb_score_assignments(hits, min_identity = min_identity, min_coverage = min_coverage)
  missing <- setdiff(asvs$asv_id, scored$asv_id)
  if (length(missing) > 0) {
    no_hits <- data.frame(
      asv_id = missing,
      species = NA_character_,
      genus = NA_character_,
      family = NA_character_,
      pident = NA_real_,
      qcov = NA_real_,
      evalue = NA_real_,
      bitscore = NA_real_,
      n_best_species = 0L,
      assignment_status = "no_match",
      confidence = "none",
      stringsAsFactors = FALSE
    )
    scored <- rbind(scored, no_hits)
  }
  scored[match(asvs$asv_id, scored$asv_id), , drop = FALSE]
}

rb_build_species_matrix <- function(assignment, asv_table,
                                    include_ambiguous = FALSE,
                                    unassigned = FALSE) {
  rb_required_columns(assignment, c("asv_id", "species", "assignment_status"))
  rb_required_columns(asv_table, "asv_id")
  x <- merge(assignment[, c("asv_id", "species", "assignment_status"), drop = FALSE],
             asv_table, by = "asv_id", all.x = FALSE, all.y = FALSE)
  keep <- !is.na(x$species)
  if (!include_ambiguous) keep <- keep & x$assignment_status == "unique"
  if (!unassigned) keep <- keep & x$assignment_status != "no_match"
  x <- x[keep, , drop = FALSE]
  if (nrow(x) == 0) return(data.frame())
  sample_cols <- setdiff(names(x), c("asv_id", "species", "assignment_status"))
  for (col in sample_cols) x[[col]] <- as.numeric(x[[col]])
  stats::aggregate(x[, sample_cols, drop = FALSE], by = list(species = x$species), FUN = sum)
}
