\name{rb_install_db}
\alias{rb_install_db}
\alias{rb_yzfishdb_release}
\alias{rb_db_url}
\alias{rb_db_dir}
\alias{rb_db_path}
\alias{rb_db_available}
\title{Download, cache, and locate the YZFishDB SQLite release}
\description{
Install and locate the full YZFishDB SQLite database used by
\pkg{regionbarcoder}. The database is stored outside the R package because the
archived \code{YZFishDB.db} file is approximately 606 MB.
}
\usage{
rb_yzfishdb_release()
rb_db_url()
rb_db_dir(create = TRUE)
rb_db_path(filename = "YZFishDB.db")
rb_db_available(path = rb_db_path())
rb_install_db(url = rb_db_url(), destfile = rb_db_path(), overwrite = FALSE,
  md5 = NULL, sha256 = NULL, min_bytes = 1, quiet = FALSE,
  timeout = 3600, retries = 3)
}
\arguments{
\item{create}{Logical. If \code{TRUE}, create the user-level database cache
directory when it does not already exist.}
\item{filename}{Database filename inside the cache directory.}
\item{path}{Path to a cached or manually downloaded database file.}
\item{url}{Download URL for \code{YZFishDB.db}. By default this points to the
Zenodo record \doi{10.5281/zenodo.18155084}. Users can override it with the
\code{RB_YZFISHDB_URL} environment variable or the
\code{regionbarcoder.yzfishdb_url} option.}
\item{destfile}{Destination path where the database should be cached.}
\item{overwrite}{Logical. If \code{TRUE}, replace an existing cached database.}
\item{md5}{Optional expected MD5 checksum. The default Zenodo release uses the
archived checksum \code{0e5e0c3e294c4a55bcc3065c26db9c84}.}
\item{sha256}{Optional expected SHA-256 checksum.}
\item{min_bytes}{Minimum accepted downloaded file size in bytes.}
\item{quiet}{Logical. If \code{TRUE}, suppress download progress messages.}
\item{timeout}{Download timeout in seconds. Increase this on slow networks.}
\item{retries}{Number of download attempts before failing.}
}
\details{
\code{rb_install_db()} downloads the database to \code{rb_db_path()}, checks the
file size, and validates checksums when available. It temporarily increases the
R download timeout and restores the user's previous timeout setting afterwards.
If repeated downloads fail, download \code{YZFishDB.db} manually from Zenodo and
set \code{RB_YZFISHDB_PATH} to the local file.
}
\value{
\code{rb_yzfishdb_release()} returns a one-row data frame describing the
archived release. \code{rb_db_url()}, \code{rb_db_dir()}, and \code{rb_db_path()}
return character paths or URLs. \code{rb_db_available()} returns a logical value.
\code{rb_install_db()} returns the normalized path to the cached SQLite file.
}
\examples{
\dontrun{
rb_yzfishdb_release()
rb_install_db(timeout = 7200, retries = 5)
rb_db_path()
rb_db_available()
}
}
