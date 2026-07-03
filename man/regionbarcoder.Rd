\name{regionbarcoder}
\alias{regionbarcoder}
\docType{package}
\title{Audit, deploy, and export regional DNA reference databases}
\description{
\pkg{regionbarcoder} provides an R interface for using regional DNA reference
databases in ecological metabarcoding. It connects to SQLite releases, downloads
and caches the Zenodo-hosted YZFishDB release, queries marker-specific sequence
subsets, exports references for common metabarcoding pipelines, assigns ASV
FASTA records, builds species matrices, and summarizes database diagnostics.
}
\details{
The package is organized into function families:
\itemize{
  \item database installation and cache helpers: \code{\link{rb_install_db}};
  \item SQLite connection and table inspection: \code{\link{rb_connect}};
  \item reference querying and filtering: \code{\link{rb_get_sequences}};
  \item taxonomy strings: \code{\link{rb_build_taxonomy_string}};
  \item pipeline-ready FASTA exports: \code{\link{rb_export_fasta}};
  \item database diagnostics: \code{\link{rb_marker_coverage}};
  \item ASV assignment and community matrices: \code{\link{rb_assign_edna}}.
}
}
\examples{
\dontrun{
library(regionbarcoder)
rb_install_db(timeout = 7200, retries = 5)
con <- rb_connect()
rb_tables(con)
rb_disconnect(con)
}
}
