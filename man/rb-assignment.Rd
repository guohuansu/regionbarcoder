\name{rb_assign_edna}
\alias{rb_assign_edna}
\alias{rb_score_assignments}
\alias{rb_build_species_matrix}
\title{Assign eDNA ASVs and build species-by-sample matrices}
\description{
Assign ASV FASTA records against a marker-specific regional reference subset, classify assignment confidence using robust alignment metrics, and aggregate ASV count tables to species-level community matrices.
}
\usage{
rb_assign_edna(asv_fasta, con = NULL, db_path = NULL, marker = NULL,
  method = c("blastn", "exact"), min_identity = 99, min_coverage = 0.9,
  max_target_seqs = 100, out_dir = tempfile("regionbarcoder_assign_"),
  blastn = "blastn", makeblastdb = "makeblastdb")
rb_score_assignments(hits, min_identity = 99, min_coverage = 0.9,
  tie_bitscore = 0)
rb_build_species_matrix(assignment, asv_table, include_ambiguous = FALSE,
  unassigned = FALSE)
}
\arguments{
\item{asv_fasta}{FASTA file containing ASV sequences.}
\item{con}{Optional DBI SQLite connection. If omitted, \code{db_path} is used to open a connection.}
\item{db_path}{Optional SQLite database path used when \code{con} is not supplied.}
\item{marker}{Optional marker filter used to select the reference subset.}
\item{method}{Assignment method. \code{"blastn"} uses BLAST+; \code{"exact"} is a dependency-free exact matching mode for tests and demonstrations.}
\item{min_identity}{Minimum percent identity for high-confidence assignment.}
\item{min_coverage}{Minimum combined coverage (\code{ccovs}) for high-confidence assignment. Applied as a proportion (e.g., \code{0.9} for 90\%). Combined coverage is calculated as the geometric mean of query and subject coverage.}
\item{max_target_seqs}{Maximum number of BLAST hits retained per ASV. Defaults to 100 to ensure that ties across many congeneric species are not prematurely dropped by the BLAST algorithm.}
\item{out_dir}{Directory for temporary BLAST reference and output files.}
\item{blastn, makeblastdb}{Executable names or paths for BLAST+.}
\item{hits}{BLAST-like hit table with ASV IDs, taxonomy and match metrics including \code{pident}, \code{qcov}, \code{scovs}, \code{ccovs}, \code{evalue}, \code{bitscore}, and \code{bitscore_pb}.}
\item{tie_bitscore}{Allowed bit-score difference for considering hits tied.}
\item{assignment}{ASV assignment table returned by \code{rb_assign_edna()}.}
\item{asv_table}{ASV count table with an \code{asv_id} column and sample columns.}
\item{include_ambiguous}{Logical. If \code{TRUE}, include ambiguous and \code{"check_full_tie"} assignments when building the species matrix.}
\item{unassigned}{Logical. If \code{TRUE}, keep unassigned ASVs (\code{"no_match"}).}
}
\details{
When \code{method = "blastn"}, BLAST+ must be installed and \code{blastn} and \code{makeblastdb} must be available on the system path. 

The assignment pipeline utilizes advanced alignment metrics to prevent common BLAST biases. It calculates subject coverage (\code{scovs}), combined coverage (\code{ccovs} = \eqn{\sqrt{qcov \times scovs}}), and bitscore per base (\code{bitscore_pb}). Hits are ranked using a robust hierarchy: \code{-bitscore}, \code{-bitscore_pb}, \code{evalue}, \code{-ccovs}, \code{-pident}. 

The \code{assignment_status} column classifies the result: 
\itemize{
\item \code{"unique"}: A single best species match.
\item \code{"ambiguous"}: Multiple species tied, but with slight metric variations.
\item \code{"check_full_tie"}: Multiple species tied with perfectly identical top metrics across the board, requiring manual biogeographical or taxonomic curation.
\item \code{"no_match"}: No hits passed the coverage/identity filters.
}

For ties, the \code{tie_taxa} column contains a pipe-separated (\code{|}) string of the tied species names (e.g., \code{"Species A|Species B"}). If there is no tie, this column is \code{NA}.
}
\value{
\itemize{
\item \code{rb_assign_edna()} and \code{rb_score_assignments()} return a data frame with columns: \code{asv_id}, \code{species}, \code{genus}, \code{family}, \code{pident}, \code{qcov}, \code{scovs}, \code{ccovs}, \code{evalue}, \code{bitscore}, \code{bitscore_pb}, \code{n_best_species}, \code{assignment_status}, \code{confidence}, and \code{tie_taxa}.
\item \code{rb_build_species_matrix()} returns a species-by-sample abundance matrix as a data frame, with species as rows and samples as columns.
}
}
\examples{
con <- rb_connect()
refs <- head(rb_get_sequences(con, marker = "12S"), 1)
asv <- tempfile(fileext = ".fasta")
writeLines(c(">ASV_001", refs$sequence[[1]]), asv)

# Run exact assignment (for demonstration)
assignment <- rb_assign_edna(asv, con = con, marker = "12S", method = "exact")
assignment

# Build species matrix
counts <- data.frame(asv_id = "ASV_001", sample_a = 10, sample_b = 2)
rb_build_species_matrix(assignment, counts)

rb_disconnect(con)
}
