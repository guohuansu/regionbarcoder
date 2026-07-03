\name{rb_export_fasta}
\alias{rb_export_fasta}
\alias{rb_export_blastn}
\alias{rb_export_dada2}
\alias{rb_export_qiime2}
\alias{rb_export_usearch}
\title{Export reference subsets for metabarcoding workflows}
\description{
Write the same filtered reference sequence set to FASTA and taxonomy formats
used by BLASTN, DADA2, QIIME2, and USEARCH/VSEARCH-style workflows.
}
\usage{
rb_export_fasta(data, file, format = c("blastn", "dada2", "qiime2", "usearch"),
  taxonomy_file = NULL)
rb_export_blastn(data, fasta_file)
rb_export_dada2(data, fasta_file)
rb_export_qiime2(data, fasta_file, taxonomy_file)
rb_export_usearch(data, fasta_file)
}
\arguments{
\item{data}{A reference sequence data frame returned by
\code{\link{rb_get_sequences}} or \code{\link{rb_filter_reference}}. It must
contain a nucleotide sequence column and seven-rank taxonomy columns.}
\item{file, fasta_file}{Output FASTA file path.}
\item{format}{Export format used by the wrapper \code{rb_export_fasta()}.}
\item{taxonomy_file}{Output taxonomy TSV path required for QIIME2 export.}
}
\value{
The export functions write files and return output paths invisibly. QIIME2
export returns a list containing the FASTA and taxonomy file paths.
}
\examples{
con <- rb_connect()
refs <- head(rb_get_sequences(con, marker = "12S"), 3)
out <- tempfile(fileext = ".fasta")
rb_export_dada2(refs, out)
readLines(out, n = 4)
rb_disconnect(con)
}
