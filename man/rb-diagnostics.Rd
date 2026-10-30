\name{rb_marker_coverage}
\alias{rb_marker_coverage}
\alias{rb_source_coverage}
\alias{rb_qc_summary}
\alias{rb_barcode_gap}
\alias{rb_ambiguity}
\title{Summarize reference coverage, QC, barcode gaps, and ambiguity}
\description{
Generate diagnostic summaries that make reference-database limitations visible
before interpreting eDNA assignments.
}
\usage{
rb_marker_coverage(con, rank = "species", table = "yzfishdb_final")
rb_source_coverage(con, table = "yzfishdb_final")
rb_qc_summary(con, table = "yzfishdb_final")
rb_barcode_gap(con, species = NULL, marker = NULL)
rb_ambiguity(con)
}
\arguments{
\item{con}{A DBI SQLite connection returned by \code{\link{rb_connect}}.}
\item{rank}{Taxonomic rank for marker coverage summaries. Supported values are \code{"species"}, \code{"genus"}, \code{"family"}, and \code{"order"}.}
\item{table}{Character. Name of the reference table to query. Default \code{"yzfishdb_final"}. Use this to query user-created databases built with \code{\link{rb_create_db}}.}
\item{species}{Optional species filter for barcode-gap metrics.}
\item{marker}{Optional marker filter for barcode-gap metrics.}
}
\value{
Data frames summarizing marker coverage, source contribution, quality-control
states, barcode-gap metrics, or curated ambiguous records. If optional barcode
gap or ambiguity tables are absent from the SQLite database, the corresponding
function returns an empty data frame.
}
\examples{
con <- rb_connect()
head(rb_marker_coverage(con))
head(rb_source_coverage(con))
rb_qc_summary(con)
rb_disconnect(con)
}
