test_that("rb_marker_coverage returns marker counts", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  cov <- rb_marker_coverage(con)
  expect_true(all(c("species", "seq_type", "n_sequences") %in% names(cov)))
  expect_true(nrow(cov) > 0)
})

test_that("rb_qc_summary returns second-pass QC counts", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  qc <- rb_qc_summary(con)
  expect_true(all(c("qc_flag", "n_sequences") %in% names(qc)))
  expect_true(nrow(qc) > 0)
})
