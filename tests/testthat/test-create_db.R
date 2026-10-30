library(testthat)
library(DBI)
library(RSQLite)

# Note: When run via devtools::test(), the internal functions 
# (like rb_read_fasta and rb_clean_sequence) are available in the environment.

test_that("rb_create_db creates a valid SQLite database from FASTA and CSV", {
  # Setup temporary directory and files
  temp_dir <- tempdir()
  fasta_file <- file.path(temp_dir, "test.fasta")
  csv_file <- file.path(temp_dir, "test_meta.csv")
  db_file <- file.path(temp_dir, "test.db")
  
  # Create mock FASTA
  writeLines(c(
    ">seq1",
    "ATCGATCG",
    ">seq2",
    "GGGGCCCC"
  ), fasta_file)
  
  # Create mock CSV
  meta_df <- data.frame(
    seq_id = c("seq1", "seq2"),
    species = c("Species A", "Species B"),
    marker = c("12S", "12S"),
    source = c("local", "local"),
    stringsAsFactors = FALSE
  )
  write.csv(meta_df, csv_file, row.names = FALSE)
  
  # Run function
  res <- rb_create_db(
    fasta_path = fasta_file,
    metadata_path = csv_file,
    db_path = db_file,
    join_by = "seq_id",
    overwrite = TRUE
  )
  
  # Check return value and file existence
  expect_equal(normalizePath(res), normalizePath(db_file))
  expect_true(file.exists(db_file))
  
  # Connect and check table structure
  con <- dbConnect(SQLite(), db_file)
  on.exit(dbDisconnect(con), add = TRUE)
  
  expect_true("reference_final" %in% dbListTables(con))
  
  db_data <- dbReadTable(con, "reference_final")
  
  # Check rows and essential columns
  expect_equal(nrow(db_data), 2)
  expect_true(all(c("species", "sequence", "seq_type", "source", "qc_flag", "unique_code") %in% names(db_data)))
  
  # Check standardized values
  expect_equal(db_data$sequence, c("ATCGATCG", "GGGGCCCC"))
  expect_equal(db_data$seq_type, c("12S", "12S"))
  expect_equal(db_data$qc_flag, c("pass", "pass"))
})

test_that("rb_create_db handles missing taxonomy correctly", {
  temp_dir <- tempdir()
  fasta_file <- file.path(temp_dir, "test_notax.fasta")
  csv_file <- file.path(temp_dir, "test_notax_meta.csv")
  db_file <- file.path(temp_dir, "test_notax.db")
  
  writeLines(c(">seq1", "ATCG"), fasta_file)
  
  # Missing 'species' column
  meta_df <- data.frame(seq_id = "seq1", marker = "12S", stringsAsFactors = FALSE)
  write.csv(meta_df, csv_file, row.names = FALSE)
  
  expect_error(
    rb_create_db(fasta_path = fasta_file, metadata_path = csv_file, db_path = db_file),
    "Missing required column: 'species'"
  )
})

test_that("rb_create_db throws errors for missing files", {
  temp_dir <- tempdir()
  csv_file <- file.path(temp_dir, "test_err_meta.csv")
  db_file <- file.path(temp_dir, "test_err.db")
  
  meta_df <- data.frame(seq_id = "seq1", species = "Sp A", stringsAsFactors = FALSE)
  write.csv(meta_df, csv_file, row.names = FALSE)
  
  expect_error(
    rb_create_db(fasta_path = "nonexistent.fasta", metadata_path = csv_file, db_path = db_file),
    "FASTA file does not exist"
  )
})