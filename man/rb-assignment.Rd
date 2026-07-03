\name{rb_assign_edna}
\alias{rb_assign_edna}
\alias{rb_score_assignments}
\alias{rb_build_species_matrix}
\title{Assign eDNA ASVs and build species-by-sample matrices}
\description{
Assign ASV FASTA records against a marker-specific regional reference subset,
classify assignment confidence, and aggregate ASV count tables to species-level
community matrices.
}
\usage{
rb_assign_edna(asv_fasta, con = NULL, db_path = NULL, marker = NULL,
  method = c("blastn", "exact"), min_identity = 99, min_coverage = 0.9,
  max_target_seqs = 20, out_dir = tempfile("regionbarcoder_assign_"),
  blastn = "blastn", makeblastdb = "makeblastdb")
rb_score_assignments(hits, min_identity = 99, min_coverage = 0.9,
  tie_bitscore = 0)
rb_build_species_matrix(assignment, asv_table, include_ambiguous = FALSE,
  unassigned = FALSE)
}
\arguments{
\item{asv_fasta}{FASTA file containing ASV sequences.}
\item{con}{Optional DBI SQLite connection. If omitted, \code{db_path} is used to
open a connection.}
\item{db_path}{Optional SQLite database path used when \code{con} is not
supplied.}
\item{marker}{Optional marker filter used to select the reference subset.}
\item{method}{Assignment method. \code{"blastn"} uses BLAST+; \code{"exact"} is
a dependency-free exact matching mode for tests and demonstrations.}
\item{min_identity}{Minimum percent identity for high-confidence assignment.}
\item{min_coverage}{Minimum query coverage for high-confidence assignment.}
\item{max_target_seqs}{Maximum number of BLAST hits retained per ASV.}
\item{out_dir}{Directory for temporary BLAST reference and output files.}
\item{blastn, makeblastdb}{Executable names or paths for BLAST+.}
\item{hits}{BLAST-like hit table with ASV IDs, taxonomy and match metrics.}
\item{tie_bitscore}{Allowed bit-score difference for considering hits tied.}
\item{assignment}{ASV assignment table returned by \code{rb_assign_edna()}.}
\item{asv_table}{ASV count table with an \code{asv_id} column and sample columns.}
\item{include_ambiguous}{Logical. If \code{TRUE}, include ambiguous assignments
when building the species matrix.}
\item{unassigned}{Logical. If \code{TRUE}, keep unassigned ASVs.}
}
\details{
When \code{method = "blastn"}, BLAST+ must be installed and \code{blastn} and
\code{makeblastdb} must be available on the system path. Assignment output uses
\code{assignment_status} values including \code{"unique"}, \code{"ambiguous"},
and \code{"no_match"}, together with confidence values such as \code{"high"},
\code{"low"}, and \code{"none"}.
}
\value{
\code{rb_assign_edna()} and \code{rb_score_assignments()} return assignment data
frames. \code{rb_build_species_matrix()} returns a species-by-sample abundance
matrix as a data frame.
}
\examples{
con <- rb_connect()
refs <- head(rb_get_sequences(con, marker = "12S"), 1)
asv <- tempfile(fileext = ".fasta")
writeLines(c(">ASV_001", refs$sequence[[1]]), asv)
assignment <- rb_assign_edna(asv, con = con, marker = "12S", method = "exact")
assignment
counts <- data.frame(asv_id = "ASV_001", sample_a = 10, sample_b = 2)
rb_build_species_matrix(assignment, counts)
rb_disconnect(con)
}
