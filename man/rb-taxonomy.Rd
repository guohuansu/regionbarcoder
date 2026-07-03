\name{rb_taxonomy}
\alias{rb_taxonomy}
\alias{rb_build_taxonomy_string}
\title{Read taxonomy and build pipeline taxonomy strings}
\description{
Inspect distinct taxonomy records and convert seven-rank taxonomy columns into
plain or rank-prefixed taxonomy strings for downstream export formats.
}
\usage{
rb_taxonomy(con, species = NULL)
rb_build_taxonomy_string(data, style = c("plain", "rank_prefix"))
}
\arguments{
\item{con}{A DBI SQLite connection returned by \code{\link{rb_connect}}.}
\item{species}{Optional species filter.}
\item{data}{A data frame containing kingdom, phylum, class, order, family,
genus, and species columns.}
\item{style}{Taxonomy string style. \code{"plain"} returns semicolon-separated
rank values; \code{"rank_prefix"} returns strings such as \code{k__Animalia}.}
}
\value{
\code{rb_taxonomy()} returns a data frame of distinct taxonomy records.
\code{rb_build_taxonomy_string()} returns a character vector.
}
\examples{
con <- rb_connect()
tax <- rb_taxonomy(con)
head(tax)
rb_build_taxonomy_string(head(tax), style = "rank_prefix")
rb_disconnect(con)
}
