\name{rb_get_sequences}
\alias{rb_get_sequences}
\alias{rb_list_taxa}
\alias{rb_filter_reference}
\title{Query and filter reference sequences}
\description{
Retrieve sequence records from the curated reference table and apply
reproducible filters for taxonomy, marker, source, occurrence status,
quality-control state, and sequence length.
}
\usage{
rb_get_sequences(con, species = NULL, genus = NULL, family = NULL,
  marker = NULL, source = NULL, occurrence = NULL, qc_flag = "pass")
rb_list_taxa(con, rank = "species", occurrence = NULL, marker = NULL)
rb_filter_reference(data, marker = NULL, source = NULL, occurrence = NULL,
  min_length = NULL, max_length = NULL)
}
\arguments{
\item{con}{A DBI SQLite connection returned by \code{\link{rb_connect}}.}
\item{species, genus, family}{Optional taxonomic filters.}
\item{marker}{Optional marker filter, for example \code{"12S"}, \code{"16S"},
or \code{"COI"}.}
\item{source}{Optional source database or collection filter.}
\item{occurrence}{Optional occurrence filter, for example \code{"native"} or
\code{"introduced"}.}
\item{qc_flag}{Quality-control state to retain. The default keeps records with
\code{qc_flag == "pass"}.}
\item{rank}{Taxonomic rank to list. Supported ranks are kingdom, phylum, class,
order, family, genus, and species.}
\item{data}{A reference sequence data frame, usually returned by
\code{rb_get_sequences()}.}
\item{min_length, max_length}{Optional sequence length limits in base pairs.}
}
\value{
A data frame of sequence records, taxa and counts, or filtered reference
records, depending on the function.
}
\examples{
con <- rb_connect()
native_12s <- rb_get_sequences(con, marker = "12S", occurrence = "native")
head(native_12s)
rb_list_taxa(con, rank = "species", marker = "12S")
rb_filter_reference(native_12s, min_length = 80, max_length = 250)
rb_disconnect(con)
}
