test_that("exported functions have function-specific help topics", {
  candidates <- c(".", "../..")
  source_root <- candidates[file.exists(file.path(candidates, "DESCRIPTION")) &
                              dir.exists(file.path(candidates, "man"))]
  rd <- if (length(source_root) > 0) {
    tools::Rd_db(dir = source_root[[1]])
  } else {
    tools::Rd_db(package = "regionbarcoder")
  }
  alias_maps <- lapply(rd, function(topic) {
    aliases <- vapply(topic[tools:::RdTags(topic) == "\\alias"], as.character, character(1))
    title <- paste(unlist(topic[tools:::RdTags(topic) == "\\title"]), collapse = "")
    stats::setNames(rep(title, length(aliases)), aliases)
  })
  alias_to_title <- do.call(c, unname(alias_maps))

  exported <- if (length(source_root) > 0 && file.exists(file.path(source_root[[1]], "NAMESPACE"))) {
    namespace <- readLines(file.path(source_root[[1]], "NAMESPACE"))
    sub("^export\\((.*)\\)$", "\\1", grep("^export\\(", namespace, value = TRUE))
  } else {
    getNamespaceExports("regionbarcoder")
  }
  missing_help <- setdiff(exported, names(alias_to_title))
  expect_equal(missing_help, character())

  generic_title <- "Audit, deploy, and export regional DNA reference databases"
  generic_exports <- exported[alias_to_title[exported] == generic_title]
  expect_equal(generic_exports, character())

  expect_gte(length(unique(alias_to_title[exported])), 7)
})
