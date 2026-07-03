root <- normalizePath(file.path(".."), winslash = "/", mustWork = TRUE)
pkg_root <- normalizePath(file.path("."), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(pkg_root, "DESCRIPTION"))) {
  stop("Run this script from the regionbarcoder package directory.", call. = FALSE)
}

for (f in list.files(file.path(pkg_root, "R"), full.names = TRUE, pattern = "\\.R$")) {
  source(f)
}

out_dir <- Sys.getenv("RB_ASSET_OUT_DIR", file.path(pkg_root, "manuscript"))
table_dir <- file.path(out_dir, "tables")
figure_dir <- file.path(out_dir, "figures")
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

db_path <- Sys.getenv("RB_YZFISHDB_PATH", file.path(root, "zenodo", "data", "YZFishDB.db"))
data_dir <- Sys.getenv("RB_YZFISHDB_DATA_DIR", file.path(root, "zenodo", "data"))
Sys.setenv(RB_YZFISHDB_PATH = db_path, RB_YZFISHDB_DATA_DIR = data_dir)

con <- rb_connect(db_path)
on.exit(rb_disconnect(con), add = TRUE)

tables <- rb_tables(con)
utils::write.csv(tables, file.path(table_dir, "database_tables.csv"), row.names = FALSE)

final <- rb_read_table(con, "yzfishdb_final")
database_summary <- data.frame(
  metric = c(
    "curated_sequences",
    "curated_species_name_entries",
    "curated_single_species_names",
    "curated_composite_species_entries",
    "curated_genera",
    "curated_families",
    "native_taxa",
    "introduced_taxa",
    "source_tables"
  ),
  value = c(
    nrow(final),
    length(unique(final$species)),
    length(unique(final$species[!grepl("\\|", final$species)])),
    length(unique(final$species[grepl("\\|", final$species)])),
    length(unique(final$genus)),
    length(unique(final$family)),
    length(unique(final$species[final$occurrence == "native"])),
    length(unique(final$species[final$occurrence %in% c("introduced", "non-native")])),
    sum(tables$table %in% c("bold", "local", "midori", "mitofish", "ncbi"))
  )
)
utils::write.csv(database_summary, file.path(table_dir, "database_summary.csv"), row.names = FALSE)

marker_summary <- aggregate(
  list(n_sequences = final$sequence_id),
  by = list(seq_type = final$seq_type),
  FUN = length
)
marker_summary <- marker_summary[order(marker_summary$n_sequences, decreasing = TRUE), ]
utils::write.csv(marker_summary, file.path(table_dir, "marker_summary.csv"), row.names = FALSE)

source_summary <- rb_source_coverage(con)
utils::write.csv(source_summary, file.path(table_dir, "source_marker_summary.csv"), row.names = FALSE)

coverage <- rb_marker_coverage(con)
utils::write.csv(coverage, file.path(table_dir, "species_marker_coverage.csv"), row.names = FALSE)

gap <- rb_read_barcode_gap()
gap_summary <- aggregate(
  list(n_species_marker = gap$species),
  by = list(marker = gap$marker, gap_exists = gap$gap_exists),
  FUN = length
)
utils::write.csv(gap_summary, file.path(table_dir, "barcode_gap_summary.csv"), row.names = FALSE)

amb <- rb_read_ambiguity()
amb_summary <- aggregate(
  list(n_records = amb$sequence_id),
  by = list(action = amb$action),
  FUN = length
)
utils::write.csv(amb_summary, file.path(table_dir, "ambiguity_action_summary.csv"), row.names = FALSE)

png(file.path(figure_dir, "marker_sequence_counts.png"), width = 1800, height = 1200, res = 180)
par(mar = c(7, 5, 2, 1))
barplot(
  marker_summary$n_sequences,
  names.arg = marker_summary$seq_type,
  las = 2,
  col = "#4C78A8",
  ylab = "Number of curated sequences",
  main = "YZFishDB marker composition"
)
dev.off()

source_matrix <- xtabs(n_sequences ~ source + seq_type, data = source_summary)
png(file.path(figure_dir, "source_marker_contribution.png"), width = 1800, height = 1200, res = 180)
par(mar = c(7, 5, 2, 8), xpd = TRUE)
barplot(
  t(source_matrix),
  beside = FALSE,
  las = 2,
  col = c("#4C78A8", "#F58518", "#54A24B", "#B279A2", "#E45756", "#72B7B2", "#FF9DA6"),
  ylab = "Number of curated sequences",
  main = "Source contributions by marker"
)
legend("topright", inset = c(-0.22, 0), legend = colnames(source_matrix), fill = c("#4C78A8", "#F58518", "#54A24B", "#B279A2", "#E45756", "#72B7B2", "#FF9DA6"), cex = 0.75)
dev.off()

gap_matrix <- xtabs(n_species_marker ~ marker + gap_exists, data = gap_summary)
png(file.path(figure_dir, "barcode_gap_status.png"), width = 1800, height = 1200, res = 180)
par(mar = c(6, 5, 2, 1))
barplot(
  t(gap_matrix),
  beside = TRUE,
  las = 2,
  col = c("#E45756", "#54A24B"),
  ylab = "Species-marker combinations",
  main = "Barcode gap status by marker"
)
legend("topright", legend = colnames(gap_matrix), fill = c("#E45756", "#54A24B"), cex = 0.85)
dev.off()

message("Wrote manuscript tables to: ", table_dir)
message("Wrote manuscript figures to: ", figure_dir)
