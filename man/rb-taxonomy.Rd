\name{rb_taxonomy}
\alias{rb_taxonomy}
\alias{rb_build_taxonomy_string}
\title{Read taxonomy and build pipeline taxonomy strings}
\description{
Inspect distinct taxonomy records and convert seven-rank taxonomy columns into
plain or rank-prefixed taxonomy strings for downstream export formats.
}
\usage{
rb_taxonomy(con, species = NULL, qc_flag = "pass", exact = FALSE)
rb_build_taxonomy_string(data, style = c("plain", "rank_prefix"))
}
\arguments{
\item{con}{A DBI SQLite connection returned by \code{\link{rb_connect}}.}
\item{species}{Optional character vector of species names to filter.}
\item{qc_flag}{Character vector of quality-control state(s) to retain. Defaults to \code{"pass"}.}
\item{exact}{Logical. If \code{TRUE}, enforces strict equality (\code{==}) for \code{qc_flag} matching, ignoring composite flags. If \code{FALSE} (default), allows partial matching.}
\item{data}{A data frame containing \code{kingdom}, \code{phylum}, \code{class}, \code{order}, \code{family}, \code{genus}, and \code{species} columns.}
\item{style}{Taxonomy string style. \code{"plain"} returns semicolon-separated
rank values; \code{"rank_prefix"} returns strings such as \code{k__Animalia}.}
}
\value{
\code{rb_taxonomy()} A data frame of distinct taxonomy records containing the standard seven taxonomic ranks, along with \code{occurrence} and \code{habitat} columns.
\code{rb_build_taxonomy_string()} A character vector of formatted taxonomy strings, with one string per row in the input \code{data}.
}
\examples{
con <- rb_connect()
# 1. Basic query for all taxonomy records (default qc_flag = "pass")
tax <- rb_taxonomy(con)
head(tax)

# 2. Filter for a specific species using multiple QC flags (partial matching)
salmo_tax <- rb_taxonomy(con, species = "Cyprinus carpio", qc_flag = c("pass", "manual_review_needed"))

# 3. Filter using strict/exact QC flag matching
strict_tax <- rb_taxonomy(con, species = "Cyprinus carpio", qc_flag = c("pass", "manual_review_needed"), exact = TRUE)

# 4. Build taxonomy strings for downstream formatting
plain_strings <- rb_build_taxonomy_string(head(tax), style = "plain")
print(plain_strings)

prefixed_strings <- rb_build_taxonomy_string(head(tax), style = "rank_prefix")
print(prefixed_strings)

rb_disconnect(con)
}
