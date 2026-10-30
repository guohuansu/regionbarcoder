test_that("rb_get_sequences works with explicit default table", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  seqs_default <- rb_get_sequences(con, marker = "12S")
  seqs_explicit <- rb_get_sequences(con, marker = "12S", table = "yzfishdb_final")
  expect_equal(nrow(seqs_default), nrow(seqs_explicit))
})

test_that("rb_get_sequences errors gracefully on nonexistent table", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  expect_error(
    rb_get_sequences(con, table = "nonexistent_table_xyz"),
    "not found in database"
  )
})

test_that("rb_list_taxa works with explicit table parameter", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  taxa_default <- rb_list_taxa(con)
  taxa_explicit <- rb_list_taxa(con, table = "yzfishdb_final")
  expect_equal(nrow(taxa_default), nrow(taxa_explicit))
})

test_that("rb_assign_edna works with explicit table parameter", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  refs <- head(rb_get_sequences(con, marker = "12S", species = "Abbottina rivularis"), 1)
  asv_file <- tempfile(fileext = ".fasta")
  writeLines(c(">ASV_001", refs$sequence[[1]]), asv_file, useBytes = TRUE)
  assigned <- rb_assign_edna(asv_file, con = con, table = "yzfishdb_final",
                             marker = "12S", method = "exact")
  expect_equal(assigned$species, "Abbottina rivularis")
})

test_that("diagnostic functions work with explicit table parameter", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  cov_default <- rb_marker_coverage(con)
  cov_explicit <- rb_marker_coverage(con, table = "yzfishdb_final")
  expect_equal(nrow(cov_default), nrow(cov_explicit))
})