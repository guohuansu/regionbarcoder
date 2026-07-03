test_that("rb_read_barcode_gap reads and filters released barcode gap metrics", {
  gap <- rb_read_barcode_gap(species = "Abbottina rivularis", marker = "COI")
  expect_true(nrow(gap) > 0)
  expect_true(all(gap$species == "Abbottina rivularis"))
  expect_true(all(gap$marker == "COI"))
  expect_true(all(c("n_sequences", "median_intra", "median_inter") %in% names(gap)))
})

test_that("rb_read_ambiguity reads manually curated ambiguous sequence records", {
  amb <- rb_read_ambiguity()
  expect_true(nrow(amb) > 0)
  expect_true(all(c("species", "seq_type", "sequence_id", "action") %in% names(amb)))
})
