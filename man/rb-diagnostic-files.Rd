\name{rb_read_barcode_gap}
\alias{rb_read_barcode_gap}
\alias{rb_read_ambiguity}
\title{Read external barcode-gap and ambiguity diagnostic tables}
\description{
Read barcode-gap metrics and curated ambiguity tables from CSV files included
with the package demo data or supplied by a full YZFishDB data release.
}
\usage{
rb_read_barcode_gap(path = NULL, species = NULL, marker = NULL)
rb_read_ambiguity(path = NULL, action = NULL)
}
\arguments{
\item{path}{Optional CSV file path. If \code{NULL}, the function searches the
configured YZFishDB data directory and then bundled demonstration files.}
\item{species}{Optional species filter for barcode-gap metrics.}
\item{marker}{Optional marker filter for barcode-gap metrics.}
\item{action}{Optional ambiguity curation action filter.}
}
\value{
A data frame containing barcode-gap or ambiguity records.
}
\examples{
head(rb_read_barcode_gap())
head(rb_read_ambiguity())
}
