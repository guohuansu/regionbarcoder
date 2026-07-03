source_db <- file.path("..", "zenodo", "data", "YZFishDB.db")
out_db <- Sys.getenv("RB_OUT_DB", file.path("inst", "extdata", "small_yzfishdb.sqlite"))
if (!file.exists(source_db)) {
  source_db <- file.path("zenodo", "data", "YZFishDB.db")
}
stopifnot(file.exists(source_db))

dir.create(dirname(out_db), recursive = TRUE, showWarnings = FALSE)
if (file.exists(out_db)) unlink(out_db)
source_db <- normalizePath(source_db, winslash = "/", mustWork = TRUE)
out_db <- normalizePath(out_db, winslash = "/", mustWork = FALSE)

src <- DBI::dbConnect(RSQLite::SQLite(), source_db)
dst <- DBI::dbConnect(RSQLite::SQLite(), out_db)
on.exit({
  DBI::dbDisconnect(src)
  DBI::dbDisconnect(dst)
}, add = TRUE)

species <- c(
  "Abbottina rivularis",
  "Acanthogobius elongatus",
  "Siniperca chuatsi",
  "Hypophthalmichthys molitrix",
  "Oryzias sinensis"
)
quoted <- paste(DBI::dbQuoteString(src, species), collapse = ",")

final_sql <- paste0(
  "select * from yzfishdb_final where species in (", quoted, ") ",
  "and seq_type in ('12S','16S','COI') limit 120"
)
final <- DBI::dbGetQuery(src, final_sql)
DBI::dbWriteTable(dst, "yzfishdb_final", final)

raw <- DBI::dbGetQuery(src, paste0(
  "select * from yzfishdb_raw where species in (", quoted, ") limit 120"
))
DBI::dbWriteTable(dst, "yzfishdb_raw", raw)

qc <- DBI::dbGetQuery(src, paste0(
  "select * from qc_reference_p2 where species in (", quoted, ") limit 120"
))
DBI::dbWriteTable(dst, "qc_reference_p2", qc)

barcode_path <- file.path("..", "zenodo", "data", "barcode_gap_metrics_enhanced.csv")
if (!file.exists(barcode_path)) {
  barcode_path <- file.path("zenodo", "data", "barcode_gap_metrics_enhanced.csv")
}
if (file.exists(barcode_path)) {
  barcode <- utils::read.csv(barcode_path, stringsAsFactors = FALSE)
  barcode <- barcode[barcode$species %in% species, , drop = FALSE]
  DBI::dbWriteTable(dst, "barcode_gap_metrics", barcode)
}

amb_path <- file.path("..", "zenodo", "data", "ambiguous_sequences_tbl_cleaned.csv")
if (!file.exists(amb_path)) {
  amb_path <- file.path("zenodo", "data", "ambiguous_sequences_tbl_cleaned.csv")
}
if (file.exists(amb_path)) {
  amb <- utils::read.csv(amb_path, stringsAsFactors = FALSE)
  amb <- head(amb, 50)
  DBI::dbWriteTable(dst, "ambiguous_sequences", amb)
}

message("Created ", out_db, " with ", nrow(final), " final reference rows.")
