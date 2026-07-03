# regionbarcoder

`regionbarcoder` is an R framework for querying, auditing, exporting, and
reporting regional DNA reference databases for ecological metabarcoding.

The first flagship dataset is YZFishDB, a curated DNA reference database for
fishes of the Yangtze River Basin. The package ships with a small demonstration
SQLite database for examples and tests. The full YZFishDB release can be used
from a local SQLite path.

## Installation

Install the development version from GitHub:

```r
install.packages("remotes")
remotes::install_github("guohuansu/regionbarcoder")
```

The R package does not bundle the full YZFishDB database because the SQLite
release is large. The recommended release model is:

- install the R package from GitHub;
- archive the full `YZFishDB.db` release on Zenodo or a GitHub Release;
- let `regionbarcoder` download and cache the database on first use.

After the full database release URL is available, users can install it with:

```r
library(regionbarcoder)

rb_install_db(
  url = "https://zenodo.org/records/<record-id>/files/YZFishDB.db?download=1"
)

con <- rb_connect()
```

For a lab or manuscript workflow, the URL can also be configured once:

```r
Sys.setenv(
  RB_YZFISHDB_URL = "https://zenodo.org/records/<record-id>/files/YZFishDB.db?download=1"
)

con <- rb_connect(download = TRUE)
```

Advanced users can still point `regionbarcoder` to an existing local database:

```r
Sys.setenv(
  RB_YZFISHDB_PATH = "path/to/YZFishDB.db",
  RB_YZFISHDB_DATA_DIR = "path/to/data"
)
```

For BLASTN-based ASV assignment, install BLAST+ and make sure `blastn` and
`makeblastdb` are available on `PATH`. Without BLAST+, use `method = "exact"`
for demonstrations and exact sequence matching.

## Quick start

```r
library(regionbarcoder)

# Uses the bundled demo database unless a full YZFishDB path/cache is available.
con <- rb_connect()
rb_tables(con)

seqs <- rb_get_sequences(con, marker = "12S", occurrence = "native")
rb_export_dada2(seqs, "yzfishdb_12s_dada2.fasta")
rb_marker_coverage(con)

rb_disconnect(con)
```

Users with Yangtze River Basin fish eDNA ASVs can also assign ASV sequences
directly against YZFishDB:

```r
con <- rb_connect(download = TRUE)

assignment <- rb_assign_edna(
  asv_fasta = "my_asvs.fasta",
  con = con,
  marker = "12S",
  method = "blastn",
  min_identity = 99,
  min_coverage = 0.90
)

species_matrix <- rb_build_species_matrix(
  assignment = assignment,
  asv_table = read.csv("asv_counts.csv")
)

rb_disconnect(con)
```

When BLAST+ is not installed, `method = "exact"` provides a lightweight exact
sequence matching mode for demonstrations and tests.

The package is designed to support manuscript-scale reproducibility: users can
inspect marker coverage, source contributions, quality-control outcomes, and
pipeline-specific exports before interpreting eDNA assignments.
