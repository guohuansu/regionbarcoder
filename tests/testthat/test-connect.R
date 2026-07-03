test_that("rb_available_datasets reports bundled demo database", {
  datasets <- rb_available_datasets()
  expect_true("small_yzfishdb" %in% datasets$name)
  expect_true(file.exists(datasets$path[datasets$name == "small_yzfishdb"]))
})

test_that("rb_connect opens bundled demo database", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  expect_true(DBI::dbIsValid(con))
  tables <- rb_tables(con)
  expect_true("yzfishdb_final" %in% tables$table)
  expect_true(tables$n_rows[tables$table == "yzfishdb_final"] > 0)
})
