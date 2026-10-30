# ============================================================================
# regionbarcoder: Plecoptera Benchmarking Case Study
# Methods: RB-Exact, RB-BLASTn, VSEARCH-SINTAX, [QIIME2-NaiveBayes]
# Mock community rationale: Braukmann et al. (2019) Mol Ecol Resour 19:711-727
# ============================================================================

library(regionbarcoder)
library(tidyverse)
library(Biostrings)

# --- 0. Configuration & Paths ------------------------------------------------
vsearch_exe     <- "C:/Zi Xun/Git/tools/vsearch-2.32.0-win-x86_64/bin/vsearch.exe"
qiime_env_name  <- "rachis-qiime2-2026.10"

# Inputs from vuatez_2024_seq_dl.R
taxa_table_path <- "data-raw/plecoptera_metadata.csv"
fasta_path      <- "data-raw/plecoptera_sequences.fasta"

# Outputs
db_path         <- "inst/extdata/plecoptera_swiss.db"
table_name      <- "reference_final"
bench_dir       <- "inst/extdata/benchmark"
dir.create(bench_dir, recursive = TRUE, showWarnings = FALSE)


to_wsl_path <- function(win_path) {
  p <- normalizePath(win_path, winslash = "/", mustWork = FALSE)
  sub("^([A-Za-z]):/", "/mnt/\\L\\1/", p, perl = TRUE)
}

# --- 1. Build SQLite DB from the Vuataz taxa table ---------------------------
cat("Building SQLite database...\n")
taxa <- read.csv(taxa_table_path, stringsAsFactors = FALSE, check.names = FALSE)

# Additive taxonomy enrichment (adds standard columns; removes nothing)
taxa$family <- taxa$Family
taxa$genus <- sapply(strsplit(trimws(taxa$species), "\\s+"), `[`, 1)
taxa$genus[trimws(taxa$species) %in% c("sp.", "")] <- NA_character_
taxa$kingdom <- "Metazoa"
taxa$phylum <- "Arthropoda"
taxa$class <- "Insecta"
taxa$order <- "Plecoptera"

# Drop only the redundant sequence column (FASTA is canonical)
taxa_for_db <- taxa[, setdiff(names(taxa), "sequence"), drop = FALSE] |>
  select(unique_code, marker, species, genus, family, order, class, phylum, kingdom, qc_flag, source)
clean_meta <- file.path(bench_dir, "meta_for_db.csv")
write.csv(taxa_for_db, clean_meta, row.names = FALSE)

rb_create_db(
  fasta_path    = fasta_path,
  metadata_path = clean_meta,
  db_path       = db_path,
  join_by       = "unique_code",
  marker        = "COI",
  source        = "Vuataz_et_al_2024",
  table_name    = table_name,
  overwrite     = TRUE
)
cat("Database created at:", db_path, "\n")


# --- 2. Connect and audit ----------------------------------------------------
con <- rb_connect(db_path)

qc_summary   <- rb_qc_summary(con, table = table_name)
species_list <- rb_list_taxa(con, rank = "species", table = table_name)
marker_cov   <- rb_marker_coverage(con, table = table_name)
source_cov   <- rb_source_coverage(con, table = table_name)

cat("Species in database:", nrow(species_list), "\n")
cat("Total sequences:", sum(marker_cov$n_sequences), "\n")


# --- 3. Prepare reference files for external tools ---------------------------
refs <- rb_get_sequences(con, table = table_name, marker = "COI")

# SINTAX reference (USEARCH format: ">id tax=d__...; s__Species")
sintax_ref <- file.path(bench_dir, "sintax_ref.fasta")
rb_export_usearch(refs, sintax_ref)

# QIIME2 references (FASTA + rank-prefixed TSV)
q2_ref_fasta <- file.path(bench_dir, "q2_ref.fasta")
q2_tax_tsv   <- file.path(bench_dir, "q2_taxonomy.tsv")
rb_export_qiime2(refs, fasta_file = q2_ref_fasta, taxonomy_file = q2_tax_tsv)


# --- 4. Generate in silico mock community ------------------------------------
# One representative (longest) sequence per species
refs_one <- refs |>
  filter(!is.na(species) & trimws(species) != "" & trimws(species) != "sp.") |>
  mutate(seq_len = nchar(sequence)) |>
  group_by(species) |>
  slice_max(seq_len, n = 1, with_ties = FALSE) |>
  ungroup()

cat("Reference species for mock community:", nrow(refs_one), "\n")

error_rates <- c(0.00, 0.005, 0.01, 0.02)
n_reps <- 2
bases <- c("A", "C", "G", "T")

mutate_seq <- function(seq_str, err) {
  if (err == 0) return(seq_str)
  chars <- unlist(strsplit(toupper(seq_str), ""))
  n_mut <- round(length(chars) * err)
  if (n_mut == 0) return(seq_str)
  for (p in sample.int(length(chars), n_mut)) {
    if (chars[p] %in% bases) chars[p] <- sample(setdiff(bases, chars[p]), 1)
  }
  paste(chars, collapse = "")
}

set.seed(324)
mock_rows <- list()
truth_rows <- list()
k <- 0
for (i in seq_len(nrow(refs_one))) {
  sp  <- refs_one$species[i]
  seq <- refs_one$sequence[i]
  for (err in error_rates) {
    for (rep in seq_len(n_reps)) {
      k <- k + 1
      asv_id <- sprintf("Mock-%04d-%04.1fpct-r%d", i, err * 100, rep)
      mock_rows[[k]]  <- data.frame(asv_id = asv_id, sequence = mutate_seq(seq, err),
                                    stringsAsFactors = FALSE)
      truth_rows[[k]] <- data.frame(asv_id = asv_id, true_species = sp, error_rate = err,
                                    stringsAsFactors = FALSE)
    }
  }
}
mock_df <- bind_rows(mock_rows)
truth_df <- bind_rows(truth_rows)

mock_fasta <- file.path(bench_dir, "mock_asvs.fasta")
writeLines(c(rbind(paste0(">", mock_df$asv_id), mock_df$sequence)), mock_fasta)
cat("Mock ASVs generated:", nrow(mock_df), "\n")

# --------------------------------------------------------
# Threshold sensitivity analysis
sens_dir <- file.path(bench_dir, "sensitivity")
dir.create(sens_dir, recursive = TRUE, showWarnings = FALSE)

evaluate_sens <- function(pred, truth, method, threshold_label) {
  df <- left_join(truth, pred, by = "asv_id")
  
  assigned <- !is.na(df$species) & nzchar(df$species)
  
  # Split ties: "SpA|SpB" → check if true_species is among them
  is_tie <- assigned & grepl("|", df$species, fixed = TRUE)
  correct_unique <- assigned & !is_tie & (df$species == df$true_species)
  correct_tie <- is_tie & vapply(seq_len(nrow(df)), function(i) {
    if (!is_tie[i]) return(FALSE)
    df$true_species[i] %in% strsplit(df$species[i], "|", fixed = TRUE)[[1]]
  }, logical(1))
  incorrect <- assigned & !correct_unique & !correct_tie
  
  data.frame(
    Method    = method,
    Threshold = threshold_label,
    Total     = nrow(truth),
    Assigned  = sum(assigned),
    Correct   = sum(correct_unique) + sum(correct_tie),
    Correct_unique = sum(correct_unique),
    Correct_tie    = sum(correct_tie),
    Incorrect = sum(incorrect),
    Unassigned = sum(!assigned),
    Precision   = round((sum(correct_unique) + sum(correct_tie)) / max(sum(assigned), 1), 4),
    Sensitivity = round((sum(correct_unique) + sum(correct_tie)) / nrow(truth), 4),
    FDR         = round(sum(incorrect) / max(sum(assigned), 1), 4),
    stringsAsFactors = FALSE
  )
}

## Thresholds
identity_grid <- c(95, 96, 97, 98, 99, 100)
sintax_grid   <- c(0.5, 0.6, 0.7, 0.8, 0.9, 0.95)
q2_conf_grid  <- c(0.5, 0.6, 0.7, 0.8, 0.9, 0.95)

## BLASTn
blast_sens <- lapply(identity_grid, function(id) {
  cat(sprintf("  min_identity = %d%%\n", id))
  res <- rb_assign_edna(
    mock_fasta, con = con, table = table_name,
    marker = "COI", method = "blastn",
    min_identity = id, min_coverage = 0.9,
    blastn = "C:/Program Files/NCBI/blast-2.17.0+/bin/blastn.exe",
    makeblastdb = "C:/Program Files/NCBI/blast-2.17.0+/bin/makeblastdb.exe"
  )
  pred <- res |> select(asv_id, species)
  evaluate_sens(pred, truth_df, "BLASTn", paste0(id, "% identity"))
})
blast_sens_df <- bind_rows(blast_sens)
print(blast_sens_df)

## SINTAX
run_sintax_sens <- function(query, ref, vsearch, out_dir, cutoff) {
  tab_out <- file.path(out_dir, paste0("sintax_cutoff_", cutoff, ".tsv"))
  
  system2(vsearch, c(
    "--sintax", shQuote(query),
    "--db", shQuote(ref),
    "--tabbedout", shQuote(tab_out),
    "--sintax_cutoff", as.character(cutoff),
    "--threads", "4"
  ), stdout = FALSE, stderr = FALSE)
  
  if (!file.exists(tab_out) || file.info(tab_out)$size == 0) {
    return(data.frame(asv_id = character(), species = character()))
  }
  
  x <- read.table(tab_out, sep = "\t", header = FALSE,
                  stringsAsFactors = FALSE, quote = "",
                  col.names = c("asv_id", "tax", "strand", "confidence"))
  
  # Extract species from USEARCH format: s:Species name
  x$species <- sub(".*s:([^,\\(]+).*", "\\1", x$tax, perl = TRUE)
  x$species <- trimws(x$species)
  x$species[x$species == "" |
              grepl("^unassigned", x$species, ignore.case = TRUE) |
              is.na(x$tax)] <- NA_character_
  
  x |> select(asv_id, species)
}

sintax_sens <- lapply(sintax_grid, function(cut) {
  cat(sprintf("  sintax_cutoff = %.2f\n", cut))
  pred <- run_sintax_sens(mock_fasta, sintax_ref, vsearch_exe, sens_dir, cut)
  evaluate_sens(pred, truth_df, "SINTAX", sprintf("%.2f bootstrap", cut))
})
sintax_sens_df <- bind_rows(sintax_sens)
print(sintax_sens_df)

## QIIME2
wsl_sens  <- to_wsl_path(sens_dir)
wsl_q2_fa <- to_wsl_path(q2_ref_fasta)
wsl_q2_tx <- to_wsl_path(q2_tax_tsv)
wsl_mock  <- to_wsl_path(mock_fasta)
wsl_conda <- "/home/sora8/miniforge3/etc/profile.d/conda.sh"

qiime_sens_bash <- sprintf(
  '#!/bin/bash
set -e
source %s
conda activate %s
cd %s

echo "=== Training QIIME2 classifier ==="
qiime tools import --type "FeatureData[Sequence]" --input-path %s --output-path ref.qza
qiime tools import --type "FeatureData[Taxonomy]" --input-format HeaderlessTSVTaxonomyFormat --input-path %s --output-path tax.qza
qiime feature-classifier fit-classifier-naive-bayes --i-reference-reads ref.qza --i-reference-taxonomy tax.qza --o-classifier classifier.qza

echo "=== Classifying with --p-confidence 0 (accept all) ==="
qiime tools import --type "FeatureData[Sequence]" --input-path %s --output-path query.qza
qiime feature-classifier classify-sklearn --i-classifier classifier.qza --i-reads query.qza --p-confidence 0 --o-classification class_all.qza
qiime tools export --input-path class_all.qza --output-path exported_all

echo "Done. Results in exported_all/taxonomy.tsv"
',
  wsl_conda, qiime_env_name, wsl_sens,
  wsl_q2_fa, wsl_q2_tx, wsl_mock
)

qiime_sens_script <- file.path(sens_dir, "run_qiime2_sens.sh")
# Write with Unix line endings
con_out <- file(qiime_sens_script, open = "wb")
writeChar(paste(qiime_sens_bash, collapse = "\n"), con_out, eos = NULL)
close(con_out)

cat("  Script written to:", qiime_sens_script, "\n")
cat("  Run in WSL:\n")
cat("    cd", wsl_sens, "\n")
cat("    bash run_qiime2_sens.sh\n\n")

q2_all_path <- file.path(sens_dir, "exported_all", "taxonomy.tsv")
if (!file.exists(q2_all_path)) {
  stop("QIIME2 sensitivity output not found. Run the WSL script first.")
}

q2_all <- read.table(q2_all_path, sep = "\t", header = TRUE,
                     stringsAsFactors = FALSE, check.names = FALSE, quote = "")

# Columns: Feature ID, Taxon, Confidence
# Taxon format: "d__Metazoa; p__Arthropoda; ... s__Leuctra cingulata"
# Confidence: numeric posterior probability of the DEEPEST assigned rank

extract_sp_q2 <- function(tax_str) {
  if (is.na(tax_str) || !nzchar(tax_str)) return(NA_character_)
  m <- regmatches(tax_str, regexpr("s__[^;]*", tax_str))
  if (length(m) == 0 || m == "s__") return(NA_character_)
  trimws(sub("^s__", "", m))
}

q2_all$species <- vapply(q2_all[["Taxon"]], extract_sp_q2, character(1))
q2_all$conf    <- as.numeric(q2_all[["Confidence"]])

# Post-hoc filtering: at threshold T, only accept assignments where
# confidence >= T AND species is not NA
q2_sens <- lapply(q2_conf_grid, function(thr) {
  cat(sprintf("  --p-confidence = %.2f\n", thr))
  pred <- q2_all |>
    filter(conf >= thr, !is.na(species)) |>
    select(asv_id = `Feature ID`, species)
  evaluate_sens(pred, truth_df, "QIIME2-NB", sprintf("%.2f posterior", thr))
})
q2_sens_df <- bind_rows(q2_sens)
print(q2_sens_df)

## Exact matching
t_rb_exact <- system.time({
  res_rb_exact <- rb_assign_edna(
    mock_fasta, con = con, table = table_name,
    marker = "COI", method = "exact"
  )
})
pred_rb_exact <- res_rb_exact |> select(asv_id, species)
exact_point <- evaluate_sens(pred_rb_exact, truth_df, "Exact", "100% match")

## Combined all

all_sens <- bind_rows(blast_sens_df, sintax_sens_df, q2_sens_df, exact_point)
write.csv(all_sens, file.path(sens_dir, "sensitivity_results.csv"), row.names = FALSE)
cat("\nSensitivity results saved to:", file.path(sens_dir, "sensitivity_results.csv"), "\n")

## Plot: Precision-sensitivity tradeoff
library(ggplot2)

plot_df <- all_sens |>
  select(Method, Threshold, Precision, Sensitivity, FDR) |>
  pivot_longer(cols = c(Precision, Sensitivity, FDR),
               names_to = "Metric", values_to = "Value") |>
  mutate(Threshold_num = as.numeric(sub("[^0-9.].*$", "", Threshold)),
         Threshold_pct = ifelse(Threshold_num < 1, Threshold_num*100, Threshold_num))

p <- ggplot(plot_df, aes(x = Threshold_pct, y = Value, color = Method, linetype = Metric)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_linetype_manual(values = c("Precision" = "solid",
                                   "Sensitivity" = "dashed",
                                   "FDR" = "dotted")) +
  scale_color_brewer(palette = "Set1") +
  labs(
    x = "Threshold (identity % / bootstrap / posterior probability)",
    y = "Value",
    title = "Threshold sensitivity across assignment methods",
    subtitle = "Mock community with 0–2% simulated sequencing errors\n(Plecoptera COI reference, Vuataz et al. 2024)",
    color = "Method",
    linetype = "Metric"
  ) +
  theme_classic(base_size = 12) +
  theme(legend.position = "bottom") +
  ylim(0, 1)

### BENCHMARKING

# --- 5. Run regionbarcoder methods -------------------------------------------
cat("Running regionbarcoder (Exact)...\n")

cat("Running regionbarcoder (BLASTn)...\n")
t_rb_blast <- system.time({
  res_rb_blast <- rb_assign_edna(
    mock_fasta, con = con, table = table_name,
    marker = "COI", method = "blastn", min_identity = 97,
    blastn = "C:/Program Files/NCBI/blast-2.17.0+/bin/blastn.exe",
    makeblastdb = "C:/Program Files/NCBI/blast-2.17.0+/bin/makeblastdb.exe"
  )
})
pred_rb_blast <- res_rb_blast |> select(asv_id, species)


# --- 6. Run SINTAX via VSEARCH (native Windows) ------------------------------
cat("Running VSEARCH SINTAX...\n")
sintax_out <- file.path(bench_dir, "sintax_res.tsv")

t_sintax <- system.time({
  system2(vsearch_exe, c(
    "--sintax", shQuote(mock_fasta),
    "--db", shQuote(sintax_ref),
    "--tabbedout", shQuote(sintax_out),
    "--sintax_cutoff", "0.8",
    "--threads", "4"
  ), stdout = FALSE, stderr = FALSE)
})

# Parse SINTAX output
# rb_export_usearch writes headers as: >id tax=d__...; s__Species name
# SINTAX tabbed output col2 contains the full taxonomy string with bootstrap
sintax_res <- read.table(sintax_out, sep = "\t", header = FALSE,
                         stringsAsFactors = FALSE, quote = "",
                         col.names = c("asv_id", "tax", "strand", "score"))

# Extract species: capture text after "s__" up to next comma, semicolon, or paren
sintax_res$species <- sub(".*s:([^,\\(]+).*", "\\1", sintax_res$tax, perl = TRUE)
sintax_res$species <- trimws(sintax_res$species)
sintax_res$species[sintax_res$species == "" |
                     grepl("^unassigned", sintax_res$species, ignore.case = TRUE) |
                     is.na(sintax_res$tax)] <- NA_character_

pred_sintax <- sintax_res |> select(asv_id, species)
cat("SINTAX assigned:", sum(!is.na(pred_sintax$species)), "of", nrow(pred_sintax), "\n")


# --- 7. QIIME2 Naive Bayes (WSL) ----------------------------
# Run this section separately in WSL if desired.
# The bash script below is auto-generated; execute it in your WSL terminal:
#   wsl bash /mnt/c/Users/sora8/Documents/GitHub/regionbarcoder/inst/extdata/benchmark/run_qiime2.sh
# Then uncomment the result-loading block in Section 8.


wsl_bench  <- to_wsl_path(bench_dir)

qiime_bash <- sprintf(
  '#!/bin/bash
set -e
source %s
conda activate %s
cd %s

echo "=== Training QIIME2 classifier ==="
START_TRAIN=$(date +%%s)
qiime tools import --type "FeatureData[Sequence]" \\
  --input-path %s --output-path ref.qza
qiime tools import --type "FeatureData[Taxonomy]" \\
  --input-format HeaderlessTSVTaxonomyFormat \\
  --input-path %s --output-path tax.qza
qiime feature-classifier fit-classifier-naive-bayes \\
  --i-reference-reads ref.qza \\
  --i-reference-taxonomy tax.qza \\
  --o-classifier classifier.qza
END_TRAIN=$(date +%%s)
echo "Q2_TRAIN_TIME=$((END_TRAIN - START_TRAIN))" > timing_qiime2.txt

echo "=== Classifying mock ASVs ==="
START_CLASS=$(date +%%s)
qiime tools import --type "FeatureData[Sequence]" \\
  --input-path %s --output-path query.qza
qiime feature-classifier classify-sklearn \\
  --i-classifier classifier.qza \\
  --i-reads query.qza \\
  --p-confidence 0.7 \\
  --o-classification class.qza
qiime tools export --input-path class.qza --output-path exported
END_CLASS=$(date +%%s)
echo "Q2_CLASS_TIME=$((END_CLASS - START_CLASS))" >> timing_qiime2.txt

echo "Done. Results in %s/exported/taxonomy.tsv"
',
  wsl_conda,       # %s 1: conda.sh path
  qiime_env_name,  # %s 2: environment name
  wsl_bench,       # %s 3: cd directory
  wsl_q2_fa,       # %s 4: reference FASTA
  wsl_q2_tx,       # %s 5: taxonomy TSV
  wsl_mock,        # %s 6: query FASTA
  wsl_bench        # %s 7: output dir (for final echo)
)

# Write with Unix line endings to avoid needing dos2unix
qiime_script_path <- file.path(bench_dir, "run_qiime2.sh")
con_out <- file(qiime_script_path, open = "wb")
writeChar(paste(qiime_bash, collapse = "\n"), con_out, eos = NULL)
close(con_out)

cat("QIIME2 bash script written to:", qiime_script_path, "\n")
cat("Run in WSL:\n")
cat("  cd", wsl_bench, "\n")
cat("  bash run_qiime2.sh\n")


# --- 8. Load all results and compute performance -----------------------------

# Helper: evaluate one method against ground truth
evaluate <- function(pred, truth, method, train_time = 0, class_time = 0) {
  df <- left_join(truth, pred, by = "asv_id")
  assigned <- !is.na(df$species) & nzchar(df$species)
  is_tie <- assigned & grepl("|", df$species, fixed = TRUE)
  correct_unique <- assigned & !is_tie & (df$species == df$true_species)
  correct_tie <- is_tie & vapply(seq_len(nrow(df)), function(i) {
    if (!is_tie[i]) return(FALSE)
    df$true_species[i] %in% strsplit(df$species[i], "|", fixed = TRUE)[[1]]
  }, logical(1))
  incorrect <- assigned & !correct_unique & !correct_tie
  
  data.frame(
    Method = method,
    Train_Time_s = round(train_time, 2),
    Classify_Time_s = round(class_time, 2),
    Total_ASVs = nrow(truth),
    Assigned = sum(assigned),
    Correct = sum(correct_unique) + sum(correct_tie),
    Correct_unique = sum(correct_unique),
    Correct_tie = sum(correct_tie),
    Incorrect = sum(incorrect),
    Unassigned = sum(!assigned),
    Precision = round((sum(correct_unique) + sum(correct_tie)) / max(sum(assigned), 1), 4),
    Sensitivity = round((sum(correct_unique) + sum(correct_tie)) / nrow(truth), 4),
    FDR = round(sum(incorrect) / max(sum(assigned), 1)),
    stringsAsFactors = FALSE
  )
}

# Build performance list
perf_list <- list(
  evaluate(pred_rb_exact, truth_df, "RB-Exact", 0, t_rb_exact[["elapsed"]]),
  evaluate(pred_rb_blast, truth_df, "RB-BLASTn", 0, t_rb_blast[["elapsed"]]),
  evaluate(pred_sintax,   truth_df, "SINTAX", 0, t_sintax[["elapsed"]])
)

# Load QIIME2 results if they exist (uncomment after running WSL script)
q2_tax_path <- file.path(bench_dir, "exported", "taxonomy.tsv")
q2_timing_path <- file.path(bench_dir, "timing_qiime2.txt")

if (file.exists(q2_tax_path)) {
  cat("Loading QIIME2 results...\n")
  q2_res <- read.table(q2_tax_path, sep = "\t", header = TRUE,
                       stringsAsFactors = FALSE, check.names = FALSE, quote = "")
  
  # Extract species from "d__Metazoa; p__Arthropoda; ... s__Leuctra cingulata"
  extract_sp <- function(tax_str) {
    if (is.na(tax_str) || !nzchar(tax_str)) return(NA_character_)
    m <- regmatches(tax_str, regexpr("s__[^;]*", tax_str))
    if (length(m) == 0 || m == "s__") return(NA_character_)
    sp <- sub("^s__", "", m)
    trimws(sp)
  }
  q2_res$species <- vapply(q2_res[["Taxon"]], extract_sp, character(1))
  pred_qiime2 <- q2_res |> select(asv_id = `Feature ID`, species)
  
  # Load timing
  t_train_q2 <- 0; t_class_q2 <- 0
  if (file.exists(q2_timing_path)) {
    timing_lines <- readLines(q2_timing_path)
    for (line in timing_lines) {
      parts <- strsplit(line, "=")[[1]]
      if (parts[[1]] == "Q2_TRAIN_TIME") t_train_q2 <- as.numeric(parts[[2]])
      if (parts[[1]] == "Q2_CLASS_TIME") t_class_q2 <- as.numeric(parts[[2]])
    }
  }
  
  perf_list[["QIIME2-NB"]] <- evaluate(pred_qiime2, truth_df, "QIIME2-NB",
                                       t_train_q2, t_class_q2)
} else {
  cat("QIIME2 results not found. Skipping (run the WSL script in Section 7).\n")
}

# Compile and save
perf_summary <- bind_rows(perf_list)
print(perf_summary)
write.csv(perf_summary, file.path(bench_dir, "benchmark_performance.csv"),row.names = FALSE)


# --- 9. Per-error-rate breakdown (for threshold sensitivity, R2C8) -----------
evaluate_by_error <- function(pred, truth, method) {
  df <- left_join(truth, pred, by = "asv_id")
  df <- df |>
    mutate(
      assigned = !is.na(species) & nzchar(species),
      is_tie = assigned & grepl("|", species, fixed = TRUE),
      correct = assigned & (
        (!is_tie & species == true_species) |
          (is_tie & vapply(seq_len(nrow(df)), function(i){
            if (!is_tie[i]) return(FALSE)
            df$true_species[i] %in% strsplit(df$species[i], "|", fixed = TRUE)[[1]]
          }, logical(1))))
    ) |>
    group_by(error_rate) |>
    summarise(
      Total = n(),
      Assigned = sum(assigned),
      Correct = sum(correct),
      Incorrect = sum(assigned & !correct),
      Unassigned = sum(!assigned),
      Precision = round(sum(correct) / max(sum(assigned), 1), 4),
      Sensitivity = round(sum(correct) / n(), 4),
      .groups = "drop"
    ) |>
    mutate(Method = method)
}

perf_by_error <- bind_rows(
  evaluate_by_error(pred_rb_exact, truth_df, "RB-Exact"),
  evaluate_by_error(pred_rb_blast, truth_df, "RB-BLASTn"),
  evaluate_by_error(pred_sintax,   truth_df, "SINTAX")
)

if (exists("pred_qiime2")) {
  perf_by_error <- bind_rows(
    perf_by_error,
    evaluate_by_error(pred_qiime2, truth_df, "QIIME2-NB")
  )
}

print(perf_by_error)
write.csv(perf_by_error, file.path(bench_dir, "benchmark_by_error_rate.csv"),row.names = FALSE)


# --- 10. Cleanup --------------------------------------------------------------
rb_disconnect(con)
cat("\nBenchmark complete. Results saved to:", bench_dir, "\n")
cat("Files:\n")
cat("  - benchmark_performance.csv (overall summary)\n")
cat("  - benchmark_by_error_rate.csv (per-error-rate breakdown)\n")
cat("  - sintax_res.tsv (raw SINTAX output)\n")
cat("  - mock_asvs.fasta (generated mock community)\n")
