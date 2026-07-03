\name{regionbarcoder}
\alias{regionbarcoder}
\alias{rb_ambiguity}
\alias{rb_available_datasets}
\alias{rb_barcode_gap}
\alias{rb_build_taxonomy_string}
\alias{rb_connect}
\alias{rb_db_available}
\alias{rb_db_dir}
\alias{rb_db_path}
\alias{rb_db_url}
\alias{rb_disconnect}
\alias{rb_export_blastn}
\alias{rb_export_dada2}
\alias{rb_export_fasta}
\alias{rb_export_qiime2}
\alias{rb_export_usearch}
\alias{rb_filter_reference}
\alias{rb_get_sequences}
\alias{rb_install_db}
\alias{rb_list_taxa}
\alias{rb_marker_coverage}
\alias{rb_qc_summary}
\alias{rb_read_table}
\alias{rb_read_barcode_gap}
\alias{rb_read_ambiguity}
\alias{rb_assign_edna}
\alias{rb_score_assignments}
\alias{rb_build_species_matrix}
\alias{rb_source_coverage}
\alias{rb_tables}
\alias{rb_taxonomy}
\alias{rb_yzfishdb_release}
\title{Audit, deploy, and export regional DNA reference databases}
\description{
The \pkg{regionbarcoder} package provides functions for connecting to regional
DNA reference databases, querying marker-specific sequence subsets, exporting
pipeline-ready FASTA files, assigning ASV FASTA records, building sample-by-
species matrices, and summarizing database diagnostics.
}
\usage{
rb_connect(path = NULL, download = FALSE, url = rb_db_url())
rb_disconnect(con)
rb_available_datasets()
rb_db_url()
rb_db_dir(create = TRUE)
rb_db_path(filename = "YZFishDB.db")
rb_db_available(path = rb_db_path())
rb_yzfishdb_release()
rb_install_db(url = rb_db_url(), destfile = rb_db_path(), overwrite = FALSE,
  md5 = NULL, sha256 = NULL, min_bytes = 1, quiet = FALSE,
  timeout = 3600, retries = 3)
rb_tables(con)
rb_read_table(con, table)
rb_get_sequences(con, species = NULL, genus = NULL, family = NULL,
  marker = NULL, source = NULL, occurrence = NULL, qc_flag = "pass")
rb_list_taxa(con, rank = "species", occurrence = NULL, marker = NULL)
rb_filter_reference(data, marker = NULL, source = NULL, occurrence = NULL,
  min_length = NULL, max_length = NULL)
rb_taxonomy(con, species = NULL)
rb_build_taxonomy_string(data, style = c("plain", "rank_prefix"))
rb_export_fasta(data, file, format = c("blastn", "dada2", "qiime2", "usearch"),
  taxonomy_file = NULL)
rb_export_blastn(data, fasta_file)
rb_export_dada2(data, fasta_file)
rb_export_qiime2(data, fasta_file, taxonomy_file)
rb_export_usearch(data, fasta_file)
rb_marker_coverage(con, rank = "species")
rb_source_coverage(con)
rb_qc_summary(con)
rb_barcode_gap(con, species = NULL, marker = NULL)
rb_ambiguity(con)
rb_read_barcode_gap(path = NULL, species = NULL, marker = NULL)
rb_read_ambiguity(path = NULL, action = NULL)
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
\item{path}{Path to a SQLite regional reference database, cached database, or external
diagnostic CSV file, depending on the function. If \code{NULL}, the package
looks for a bundled demo database, a local YZFishDB release, or a local YZFishDB
data directory.}
\item{download}{Whether \code{rb_connect()} should download the full YZFishDB
database when the local cache is missing.}
\item{url}{Download URL for the full YZFishDB SQLite release. If omitted,
\code{rb_install_db()} reads \code{RB_YZFISHDB_URL}, the
\code{regionbarcoder.yzfishdb_url} option, or the default Zenodo release
archived at \doi{10.5281/zenodo.18155084}.}
\item{create}{Whether to create the user-level database cache directory.}
\item{filename}{Database filename inside the cache directory.}
\item{destfile}{Destination path for the downloaded YZFishDB database.}
\item{overwrite}{Whether to replace an existing cached database.}
\item{md5}{Optional expected MD5 checksum for the downloaded database. The
default Zenodo release uses its archived checksum.}
\item{sha256}{Optional expected SHA-256 checksum for the downloaded database.}
\item{min_bytes}{Minimum accepted downloaded file size.}
\item{quiet}{Whether to silence download progress messages.}
\item{timeout}{Download timeout in seconds. The default is one hour because
the archived YZFishDB SQLite file is approximately 606 MB.}
\item{retries}{Number of download attempts before failing.}
\item{con}{A DBI SQLite connection.}
\item{table}{Name of a database table to read.}
\item{species, genus, family}{Optional taxonomic filters.}
\item{marker}{Optional marker filter such as \code{"12S"}, \code{"16S"}, or
\code{"COI"}.}
\item{source}{Optional source database filter.}
\item{occurrence}{Optional occurrence filter such as \code{"native"} or
\code{"introduced"}.}
\item{qc_flag}{Quality-control state to retain.}
\item{rank}{Taxonomic rank used for summaries.}
\item{data}{A reference sequence data frame returned by \code{rb_get_sequences}.}
\item{min_length, max_length}{Optional sequence length filters.}
\item{style}{Taxonomy string style.}
\item{file, fasta_file}{Output FASTA path.}
\item{format}{Export format.}
\item{taxonomy_file}{Output taxonomy TSV path for QIIME2 export.}
\item{action}{Optional ambiguity curation action filter.}
\item{asv_fasta}{FASTA file containing ASV sequences.}
\item{db_path}{Optional SQLite database path used when \code{con} is not supplied.}
\item{method}{Assignment method. \code{"blastn"} uses BLAST+; \code{"exact"} is a dependency-free exact-match mode for testing and simple demonstrations.}
\item{min_identity}{Minimum percent identity for high-confidence assignment.}
\item{min_coverage}{Minimum query coverage for high-confidence assignment.}
\item{max_target_seqs}{Maximum number of BLAST hits retained per ASV.}
\item{out_dir}{Directory for temporary BLAST reference and output files.}
\item{blastn, makeblastdb}{Executable names or paths for BLAST+.}
\item{hits}{BLAST-like hit table with ASV IDs, taxonomy and match metrics.}
\item{tie_bitscore}{Allowed bit-score difference for considering hits tied.}
\item{assignment}{ASV assignment table returned by \code{rb_assign_edna}.}
\item{asv_table}{ASV count table with an \code{asv_id} column and sample columns.}
\item{include_ambiguous}{Whether to include ambiguous assignments in species matrices.}
\item{unassigned}{Whether to keep unassigned ASVs.}
}
\value{
Connection functions return DBI connections or metadata tables. Query and
diagnostic functions return data frames. Export functions write files and
return output paths invisibly.
}
\examples{
\dontrun{
rb_install_db()
# Use a longer timeout on slow networks:
rb_install_db(timeout = 7200, retries = 5)
con <- rb_connect()
rb_yzfishdb_release()
seqs <- rb_get_sequences(con, marker = "12S", occurrence = "native")
rb_export_dada2(seqs, "yzfishdb_12s_dada2.fasta")
rb_marker_coverage(con)
rb_disconnect(con)
}
}
