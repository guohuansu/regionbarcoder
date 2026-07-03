\name{rb_connect}
\alias{rb_connect}
\alias{rb_disconnect}
\alias{rb_available_datasets}
\alias{rb_tables}
\alias{rb_read_table}
\title{Connect to and inspect SQLite reference databases}
\description{
Open a YZFishDB or compatible regional reference database, list available
tables, count rows, and read individual tables.
}
\usage{
rb_available_datasets()
rb_connect(path = NULL, download = FALSE, url = rb_db_url())
rb_disconnect(con)
rb_tables(con)
rb_read_table(con, table)
}
\arguments{
\item{path}{Path to a SQLite reference database. If \code{NULL},
\code{rb_connect()} uses a cached full YZFishDB release when available, a local
development copy when present, or the bundled demonstration database.}
\item{download}{Logical. If \code{TRUE} and no cached database is found,
download the full YZFishDB database with \code{\link{rb_install_db}}.}
\item{url}{Optional database download URL passed to \code{\link{rb_install_db}}.}
\item{con}{A DBI SQLite connection returned by \code{rb_connect()}.}
\item{table}{Name of a table to read from the database.}
}
\value{
\code{rb_available_datasets()} and \code{rb_tables()} return data frames.
\code{rb_connect()} returns a DBI SQLite connection. \code{rb_disconnect()}
returns \code{TRUE} invisibly. \code{rb_read_table()} returns a data frame.
}
\examples{
con <- rb_connect()
rb_tables(con)
head(rb_read_table(con, "yzfishdb_final"))
rb_disconnect(con)
}
