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
  marker = NULL, source = NULL, occurrence = NULL, qc_flag = "pass", exact = FALSE)
rb_list_taxa(con, rank = "species", occurrence = NULL, marker = NULL, qc_flag = "pass", exact = FALSE)
rb_filter_reference(data, marker = NULL, source = NULL, occurrence = NULL,
  min_length = NULL, max_length = NULL, qc_flag = "pass", exact = FALSE)
}
\arguments{
\item{con}{A DBI SQLite connection returned by \code{\link{rb_connect}}.}
\item{species, genus, family}{Optional taxonomic filters.}
\item{marker}{Optional marker filter, for example \code{"12S"}, \code{"16S"},
or \code{"COI"}.}
\item{source}{Optional source database or collection filter.}
\item{occurrence}{Optional occurrence filter, for example \code{"native"} or
\code{"introduced"}.}
\item{qc_flag}{Character vector of quality-control state(s) to retain. Defaults to \code{"pass"}.}
\item{exact}{Logical. If \code{TRUE}, enforces strict equality (\code{==}) for \code{qc_flag} matching, ignoring composite flags. If \code{FALSE} (default), allows partial matching.}
\item{rank}{Taxonomic rank to list. Supported ranks are kingdom, phylum, class,
order, family, genus, and species.}
\item{data}{A reference sequence data frame, usually returned by
\code{rb_get_sequences()}.}
\item{min_length, max_length}{Optional sequence length limits in base pairs.}
}
\value{
\itemize{
\item \code{rb_get_sequences}: A data frame of sequence records containing all columns from the reference database that match the specified filters.
\item \code{rb_list_taxa}: A data frame with two columns: the specified taxonomic \code{rank} and \code{n_sequences} (the count of matching sequences for each taxon).
\item \code{rb_filter_reference}: A filtered data frame of reference sequences, retaining the same column sturcture as the input \code{data}.
}
}

\examples{
con <- rb_connect()

# 1. Basic query with default settings (qc_flag = "pass")
native_12s <- rb_get_sequences(con, marker = "12S", occurrence = "native")
head(native_12s)

# 2. Filter for multiple QC flags using partial matching (default)
# includes rows where qc_flag is composite like "tree_high_length_variation|manual_review_needed"
multi_qc <- rb_get_sequences(con, qc_flag = c("pass", "manual_review_needed"))

# 3. Filter for multiple QC flags using exact matching
# includes ONLY rows where qc_flag is exactly "pass" or "manual_review_needed"
strict_qc <- rb_get_sequences(con, qc_flag = c("pass", "manual_review_needed"))

# 4. List taxa and filter in-memory data

species_counts <- rb_list_taxa(con, rank = "species", marker = "12S")
head(species_counts)

filtered_refs <- rb_filter_reference(native_12s, min_length = 80, max_length = 250)

rb_disconnect(con)
}
