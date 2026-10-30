library(testthat)

test_that("rb_apply_curation correctly updates assignments", {
  # 1. Mock assignment data
  assignments <- data.frame(
    asv_id = c("ASV_1", "ASV_2", "ASV_3"),
    species = c("SpA|SpB", "SpC|SpD", "SpE"),
    tie_taxa = c("SpA|SpB", "SpC|SpD", NA),
    assignment_status = c("check_full_tie", "check_full_tie", "unique"),
    confidence = c("ambiguous", "ambiguous", "high"),
    stringsAsFactors = FALSE
  )
  
  # 2. Mock curation log
  curation_log <- data.frame(
    asv_id = c("ASV_1", "ASV_2"),
    selected_taxon = c("SpA", "UNRESOLVED"),
    justification = c("Local occurrence", "Insufficient evidence"),
    curator = c("Curator1", "Curator1"),
    stringsAsFactors = FALSE
  )
  
  # 3. Apply curation
  res <- rb_apply_curation(assignments, curation_log)
  
  # 4. Assertions
  # ASV_1 should be resolved to SpA
  expect_equal(res$species[1], "SpA")
  expect_equal(res$assignment_status[1], "resolved_manual")
  expect_equal(res$confidence[1], "high")
  expect_equal(res$justification[1], "Local occurrence")
  
  # ASV_2 was marked UNRESOLVED in log, so it should remain unchanged
  expect_equal(res$species[2], "SpC|SpD")
  expect_equal(res$assignment_status[2], "check_full_tie")
  
  # ASV_3 was not in log, should remain unchanged
  expect_equal(res$species[3], "SpE")
  expect_equal(res$assignment_status[3], "unique")
})

test_that("rb_apply_curation throws error on missing columns", {
  assignments <- data.frame(asv_id = "A1", species = "SpA")
  bad_log <- data.frame(asv = "A1", taxon = "SpA") # Wrong column names
  
  expect_error(
    rb_apply_curation(assignments, bad_log),
    "curation_log must contain at least"
  )
})