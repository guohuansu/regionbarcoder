rb_tie_break <- function(assignments, curator = NULL) {
  if (!"assignment_status" %in% names(assignments)) {
    stop("Input data frame must contain an 'assignment_status' column.")
  }
  
  tie_idx <- which(assignments$assignment_status == "check_full_tie")
  
  if (length(tie_idx) == 0) {
    message("No 'check_full_tie' ASVs found in the assignments data frame.")
    return(assignments)
  }
  
  if (is.null(curator) || is.na(curator) || curator == "") {
    curator <- readline(prompt = "Enter curator name for the audit log: ")
    if (curator == "") curator <- "Anonymous"
  }
  
  curation_log <- data.frame(
    asv_id = character(),
    original_ties = character(),
    selected_taxon = character(),
    justification = character(),
    curator = character(),
    timestamp = character(),
    stringsAsFactors = FALSE
  )
  
  message(sprintf("\nFound %d ASVs with full ties. Starting interactive curation...\n", length(tie_idx)))
  
  for (i in seq_along(tie_idx)) {
    row_idx <- tie_idx[i]
    asv <- assignments[row_idx, ]
    
    # Parse tied taxa (assuming they are separated by "|" in the 'tie_taxa' column)
    tied_species <- unlist(strsplit(asv$tie_taxa, "\\|"))
    n_ties <- length(tied_species)
    
    cat("--------------------------------------------------------\n")
    cat(sprintf("ASV %d of %d: %s\n", i, length(tie_idx), asv$asv_id))
    cat(sprintf("Metrics: pident=%s | ccovs=%s | bitscore=%s\n", asv$pident, asv$ccovs, asv$bitscore))
    cat("Tied Taxa:\n")
    for (j in seq_len(n_ties)) {
      cat(sprintf("  [%d] %s\n", j, tied_species[j]))
    }
    cat("  [0] Leave unresolved (keep as ambiguous)\n")
    cat("  [S] Skip for now\n")
    cat("--------------------------------------------------------\n")
    
    choice <- ""
    while (!choice %in% c(as.character(0:n_ties), "S", "s")) {
      choice <- trimws(readline(prompt = "Select the number of the correct taxon (or 0/S): "))
    }
    
    justification <- ""
    if (toupper(choice) != "S" && choice != "0") {
      justification <- readline(prompt = "Enter brief justification for this decision: ")
    }
    
    selected <- if (toupper(choice) == "S") "SKIPPED" else if (choice == "0") "UNRESOLVED" else tied_species[as.integer(choice)]
    
    log_entry <- data.frame(
      asv_id = asv$asv_id,
      original_ties = asv$tie_taxa,
      selected_taxon = selected,
      justification = justification,
      curator = curator,
      timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      stringsAsFactors = FALSE
    )
    curation_log <- rbind(curation_log, log_entry)
    
    if (toupper(choice) != "S" && choice != "0") {
      assignments$species[row_idx] <- selected
      assignments$assignment_status[row_idx] <- "resolved_manual"
      assignments$confidence[row_idx] <- "high"
    }
  }
  
  message("\nCuration complete.")
  attr(assignments, "curation_log") <- curation_log
  
  return(assignments)
}

rb_apply_curation <- function(assignments, curation_log) {
  required_cols <- c("asv_id", "selected_taxon")
  if (!all(required_cols %in% names(curation_log))) {
    stop("curation_log must contain at least: ", paste(required_cols, collapse = ", "))
  }
  
  resolved_log <- curation_log[!curation_log$selected_taxon %in% c("SKIPPED", "UNRESOLVED", "", NA), ]
  
  if (nrow(resolved_log) == 0) {
    message("No resolved taxa found in the curation log.")
    return(assignments)
  }
  
  for (i in seq_len(nrow(resolved_log))) {
    asv <- resolved_log$asv_id[i]
    taxon <- resolved_log$selected_taxon[i]
    
    idx <- which(assignments$asv_id == asv)
    if (length(idx) == 1) {
      assignments$species[idx] <- taxon
      assignments$assignment_status[idx] <- "resolved_manual"
      assignments$confidence[idx] <- "high"
      
      if ("justification" %in% names(resolved_log)) {
        if (!"justification" %in% names(assignments)) assignments$justification <- NA_character_
        assignments$justification[idx] <- resolved_log$justification[i]
      }
      if ("curator" %in% names(resolved_log)) {
        if (!"curator" %in% names(assignments)) assignments$curator <- NA_character_
        assignments$curator[idx] <- resolved_log$curator[i]
      }
    }
  }
  
  message(sprintf("Successfully applied %d manual curation decisions.", nrow(resolved_log)))
  return(assignments)
}
