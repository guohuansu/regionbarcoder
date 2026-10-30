rb_create_db <- function(fasta_path = NULL,
                         metadata_path = NULL,
                         db_path,
                         join_by = "seq_id",
                         marker = "other_unknown",
                         source = "unknown",
                         table_name = "reference_final",
                         overwrite = TRUE,
                         metadata_sep = ",") {
  
  if (is.null(fasta_path) && is.null(metadata_path)) {
    stop("At least one of `fasta_path` or `metadata_path` must be provided.", call. = FALSE)
  }
  if (!nzchar(db_path)) {
    stop("`db_path` must be a non-empty file path.", call. = FALSE)
  }
  
  # 1. Read FASTA if provided
  fasta_data <- NULL
  if (!is.null(fasta_path)) {
    fasta_data <- rb_read_fasta(fasta_path) # Uses existing internal function
    names(fasta_data)[names(fasta_data) == "asv_id"] <- join_by
  }
  
  # 2. Read metadata if provided
  meta_data <- NULL
  if (!is.null(metadata_path)) {
    if (!file.exists(metadata_path)) stop("Metadata file does not exist: ", metadata_path, call. = FALSE)
    meta_data <- utils::read.csv(metadata_path, sep = metadata_sep, stringsAsFactors = FALSE, check.names = FALSE)
  }
  
  # 3. Merge data
  if (!is.null(fasta_data) && !is.null(meta_data)) {
    if (!join_by %in% names(meta_data)) {
      stop(paste0("Column '", join_by, "' not found in metadata file."))
    }
    ref_data <- merge(fasta_data, meta_data, by = join_by, all.x = TRUE)
  } else if (!is.null(fasta_data)) {
    ref_data <- fasta_data
    # Attempt to parse species from FASTA header if metadata is missing
    # Assumes header format like ">Species_name_seq1" or ">Species name seq1"
    ref_data$species <- gsub("_", " ", sub("^>([^_]+).*", "\\1", ref_data[[join_by]]))
    message("No metadata file provided. Attempted to parse species from FASTA headers. Please verify taxonomy.")
  } else {
    ref_data <- meta_data
    if (!"sequence" %in% names(ref_data)) {
      stop("Metadata file must contain a 'sequence' column if no FASTA file is provided.")
    }
  }
  
  # 4. Standardize columns (porting logic from barcurateR)
  if (!"species" %in% names(ref_data)) stop("Missing required column: 'species'")
  if (!"sequence" %in% names(ref_data)) stop("Missing required column: 'sequence'")
  
  # Ensure marker/seq_type exists
  if ("marker" %in% names(ref_data) && !"seq_type" %in% names(ref_data)) {
    ref_data$seq_type <- ref_data$marker
  } else if (!"seq_type" %in% names(ref_data)) {
    ref_data$seq_type <- marker
  }
  
  # Ensure source exists
  if (!"source" %in% names(ref_data)) ref_data$source <- source
  
  # Ensure qc_flag exists
  if (!"qc_flag" %in% names(ref_data)) ref_data$qc_flag <- "pass"
  
  # Ensure taxonomy columns exist (fill with NA if missing so SQL queries don't fail)
  tax_ranks <- c("kingdom", "phylum", "class", "order", "family", "genus")
  for (rank in tax_ranks) {
    if (!rank %in% names(ref_data)) ref_data[[rank]] <- NA_character_
  }
  
  # Ensure sequence_id exists
  if (!"sequence_id" %in% names(ref_data)) {
    ref_data$sequence_id <- ref_data[[join_by]]
  }
  
  # Ensure unique_code exists for assignment functions
  if (!"unique_code" %in% names(ref_data)) {
    seq_clean <- rb_clean_sequence(ref_data$sequence)
    unique_seqs <- unique(seq_clean)
    codes <- sprintf("seq_%05d", seq_along(unique_seqs))
    ref_data$unique_code <- codes[match(seq_clean, unique_seqs)]
  }
  
  # Clean sequences
  ref_data$sequence <- rb_clean_sequence(ref_data$sequence)
  
  # Remove list columns and convert factors to character for SQLite compatibility
  ref_data <- as.data.frame(lapply(ref_data, function(x) {
    if (is.factor(x)) as.character(x) else x
  }), stringsAsFactors = FALSE)
  
  # 5. Write to SQLite
  dest_dir <- dirname(db_path)
  if (nzchar(dest_dir) && !dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  
  DBI::dbWriteTable(con, table_name, ref_data, overwrite = overwrite)
  
  message("Successfully created regionbarcoder database at: ", normalizePath(db_path, winslash = "/"))
  invisible(normalizePath(db_path, winslash = "/", mustWork = TRUE))
}
