\name{rb_create_db}
\alias{rb_create_db}
\title{Create a regionbarcoder-compatible SQLite database from flat files}
\description{
  Converts a FASTA file and/or a metadata CSV/TSV into a SQLite database
  compatible with regionbarcoder. This function simplifies the process of
  creating a reference database for users who have their own regional data
  but lack the bioinformatic pipeline to construct a SQLite database.
}
\usage{
rb_create_db(
  fasta_path = NULL,
  metadata_path = NULL,
  db_path,
  join_by = "seq_id",
  marker = "other_unknown",
  source = "unknown",
  table_name = "reference_final",
  overwrite = TRUE,
  metadata_sep = ","
)
}
\arguments{
  \item{fasta_path}{Character. Path to a FASTA file containing reference sequences.}
  \item{metadata_path}{Character. Path to a CSV or TSV file containing sequence metadata.}
  \item{db_path}{Character. Path where the SQLite database (.db) will be created.}
  \item{join_by}{Character. The column name in the metadata file that matches the sequence
    headers in the FASTA file. Default is \code{"seq_id"}.}
  \item{marker}{Character. The genetic marker name (e.g., \code{"12S"}, \code{"COI"}). Used if not
    present in the metadata file.}
  \item{source}{Character. The source of the sequences (e.g., \code{"local"}, \code{"ncbi"}). Used if
    not present in the metadata file.}
  \item{table_name}{Character. Name of the main reference table in the SQLite database.
    Default is \code{"reference_final"} (required by regionbarcoder's query functions).}
  \item{overwrite}{Logical. Overwrite existing database file? Default \code{TRUE}.}
  \item{metadata_sep}{Character. The field separator character for the metadata file.
    Default is \code{","} for CSV. Use \code{"\\t"} for TSV.}
}
\value{
  Returns the normalized path to the created database file (invisibly).
}
\details{
  This function reads a FASTA file and a metadata table, merges them based on
  the \code{join_by} column, standardizes required columns (such as \code{species},
  \code{sequence}, \code{seq_type}, \code{source}, \code{qc_flag}), and writes the
  resulting data frame to a SQLite database. It ensures compatibility with
  downstream \code{regionbarcoder} functions like \code{rb_connect()} and
  \code{rb_get_sequences()}.
  
  If a metadata file is not provided, the function will attempt to parse species 
  names from the FASTA headers, assuming a format where the first word is the 
  species name. If neither file contains a \code{species} column, the function 
  will throw an error.
}
\examples{
\dontrun{
  # Create a database from a FASTA and a CSV file
  rb_create_db(
    fasta_path = "references.fasta",
    metadata_path = "metadata.csv",
    db_path = "my_regional_db.db",
    marker = "12S",
    source = "local"
  )
}
}