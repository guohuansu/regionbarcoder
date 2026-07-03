test_that("rb_db_dir uses environment override", {
  cache_dir <- tempfile("regionbarcoder-cache-")
  dir.create(cache_dir)
  withr::local_envvar(RB_YZFISHDB_CACHE_DIR = cache_dir)

  expect_identical(rb_db_dir(), normalizePath(cache_dir, winslash = "/", mustWork = TRUE))
  expect_identical(rb_db_path(), file.path(rb_db_dir(), "YZFishDB.db"))
})

test_that("rb_db_url points to the archived YZFishDB Zenodo release by default", {
  withr::local_envvar(RB_YZFISHDB_URL = NA)
  withr::local_options(list(regionbarcoder.yzfishdb_url = NULL))

  release <- rb_yzfishdb_release()
  expect_identical(release$doi, "10.5281/zenodo.18155084")
  expect_identical(release$filename, "YZFishDB.db")
  expect_identical(release$size_bytes, 635740160)
  expect_identical(release$md5, "0e5e0c3e294c4a55bcc3065c26db9c84")
  expect_identical(
    rb_db_url(),
    "https://zenodo.org/api/records/18155084/files/YZFishDB.db/content"
  )
})

test_that("rb_install_db downloads to the cache and reuses existing files", {
  cache_dir <- tempfile("regionbarcoder-cache-")
  dir.create(cache_dir)
  withr::local_envvar(RB_YZFISHDB_CACHE_DIR = cache_dir)

  source_db <- tempfile("YZFishDB-source-", fileext = ".db")
  writeLines("fake sqlite payload", source_db)

  installed <- rb_install_db(url = source_db, quiet = TRUE)
  expect_true(file.exists(installed))
  expect_identical(installed, rb_db_path())
  expect_identical(readLines(installed), "fake sqlite payload")

  writeLines("changed payload", source_db)
  reused <- rb_install_db(url = source_db, quiet = TRUE)
  expect_identical(reused, installed)
  expect_identical(readLines(reused), "fake sqlite payload")
})

test_that("rb_install_db can overwrite an existing cached database", {
  cache_dir <- tempfile("regionbarcoder-cache-")
  dir.create(cache_dir)
  withr::local_envvar(RB_YZFISHDB_CACHE_DIR = cache_dir)

  source_db <- tempfile("YZFishDB-source-", fileext = ".db")
  writeLines("first payload", source_db)
  rb_install_db(url = source_db, quiet = TRUE)

  writeLines("replacement payload", source_db)
  installed <- rb_install_db(url = source_db, overwrite = TRUE, quiet = TRUE)
  expect_identical(readLines(installed), "replacement payload")
})

test_that("rb_install_db checks md5 when requested", {
  cache_dir <- tempfile("regionbarcoder-cache-")
  dir.create(cache_dir)
  withr::local_envvar(RB_YZFISHDB_CACHE_DIR = cache_dir)

  source_db <- tempfile("YZFishDB-source-", fileext = ".db")
  writeLines("payload", source_db)

  expect_error(
    rb_install_db(url = source_db, md5 = "not-the-right-md5", quiet = TRUE),
    "md5"
  )
})

test_that("rb_install_db explains missing release URL when defaults are disabled", {
  cache_dir <- tempfile("regionbarcoder-cache-")
  dir.create(cache_dir)
  withr::local_envvar(c(
    RB_YZFISHDB_CACHE_DIR = cache_dir,
    RB_YZFISHDB_URL = NA
  ))
  withr::local_options(list(regionbarcoder.yzfishdb_url = ""))

  expect_error(
    rb_install_db(quiet = TRUE),
    "No YZFishDB download URL is configured"
  )
})

test_that("rb_connect can install the database on demand", {
  cache_dir <- tempfile("regionbarcoder-cache-")
  dir.create(cache_dir)
  withr::local_envvar(RB_YZFISHDB_CACHE_DIR = cache_dir)

  source_db <- tempfile("YZFishDB-source-", fileext = ".db")
  source_con <- DBI::dbConnect(RSQLite::SQLite(), source_db)
  on.exit(DBI::dbDisconnect(source_con), add = TRUE)
  DBI::dbWriteTable(source_con, "yzfishdb_final", data.frame(x = 1), overwrite = TRUE)

  con <- rb_connect(download = TRUE, url = source_db)
  on.exit(rb_disconnect(con), add = TRUE)
  expect_true(DBI::dbIsValid(con))
  expect_true(file.exists(rb_db_path()))
})
