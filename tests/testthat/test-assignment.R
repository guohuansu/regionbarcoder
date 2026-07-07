test_that("rb_assign_edna assigns exact ASV matches to YZFishDB species", {
  con <- rb_connect()
  on.exit(rb_disconnect(con), add = TRUE)
  refs <- head(rb_get_sequences(con, marker = "12S", species = "Abbottina rivularis"), 1)
  asv_file <- tempfile(fileext = ".fasta")
  writeLines(c(">ASV_001", refs$sequence[[1]]), asv_file, useBytes = TRUE)

  assigned <- rb_assign_edna(asv_file, con = con, marker = "12S", method = "exact")

  expect_equal(assigned$asv_id, "ASV_001")
  expect_equal(assigned$species, "Abbottina rivularis")
  expect_equal(assigned$confidence, "high")
  expect_equal(assigned$assignment_status, "unique")
})

test_that("rb_score_assignments reports ambiguous best species", {
  hits <- data.frame(
    asv_id = c("ASV_amb", "ASV_amb"),
    species = c("Species a", "Species b"),
    genus = c("Species", "Species"),
    family = c("Family", "Family"),
    pident = c(100, 100),
    qcov = c(1, 1),
    scovs = c(1, 1),
    ccovs = c(1, 1),
    evalue = c(1e-50, 1e-50),
    bitscore = c(200, 200),
    bitscore_pb = c(1, 1),
    stringsAsFactors = FALSE
  )

  scored <- rb_score_assignments(hits)

  expect_equal(scored$assignment_status, "check_full_tie")
  expect_equal(scored$confidence, "ambiguous")
  expect_equal(scored$species, "Species a|Species b")
})

test_that("rb_build_species_matrix aggregates ASV counts by assigned species", {
  assignment <- data.frame(
    asv_id = c("ASV_001", "ASV_002", "ASV_003"),
    species = c("Species a", "Species b", NA),
    assignment_status = c("unique", "unique", "no_match"),
    stringsAsFactors = FALSE
  )
  counts <- data.frame(
    asv_id = c("ASV_001", "ASV_002", "ASV_003"),
    site_1 = c(10, 0, 5),
    site_2 = c(1, 3, 7),
    check.names = FALSE
  )

  community <- rb_build_species_matrix(assignment, counts)

  expect_equal(community$species, c("Species a", "Species b"))
  expect_equal(community$site_1, c(10, 0))
  expect_equal(community$site_2, c(1, 3))
})
