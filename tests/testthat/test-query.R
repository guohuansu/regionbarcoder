test_that("rb_list_taxa lists species from final table", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  taxa <- rb_list_taxa(con)
  expect_true("species" %in% names(taxa))
  expect_true(nrow(taxa) > 0)
})

test_that("rb_get_sequences filters by marker and occurrence", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  seqs <- rb_get_sequences(con, marker = "12S", occurrence = "native")
  expect_true(nrow(seqs) > 0)
  expect_true(all(seqs$seq_type == "12S"))
  expect_true(all(seqs$occurrence == "native"))
})

test_that("rb_build_taxonomy_string creates seven-rank lineage", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  seqs <- rb_get_sequences(con, marker = "12S")
  tax <- rb_build_taxonomy_string(seqs[1, ], style = "plain")
  expect_equal(length(strsplit(tax, ";", fixed = TRUE)[[1]]), 7)
})
