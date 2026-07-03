# regionbarcoder: an R framework for assigning ecological metabarcoding ASVs with auditable regional DNA reference databases

## Abstract

Regional DNA reference databases are essential for accurate ecological
metabarcoding, particularly in species-rich and underrepresented ecosystems.
However, many curated databases are distributed as static FASTA files, database
dumps, or project-specific scripts, which makes it difficult for users to audit
taxonomic coverage, reproduce filtering decisions, export references across
bioinformatic pipelines, or benchmark assignment outcomes. We present
`regionbarcoder`, an R framework for assigning amplicon sequence variants
(ASVs) against auditable regional DNA reference databases. The package provides
a stable interface to SQLite reference releases, functions for filtering
sequences by taxonomy, marker, source, occurrence status, and quality-control
state, exporters for DADA2, QIIME2, BLASTN, and USEARCH/VSEARCH workflows, and
direct ASV assignment functions that report unique, ambiguous, low-confidence,
and unmatched sequences. It also summarizes marker coverage, source
contributions, quality-control outcomes, barcode gap metrics, and ambiguous
sequence records. We demonstrate the framework using YZFishDB, a curated
mitochondrial DNA reference database for fishes of the Yangtze River Basin
containing 54,546 curated sequences. In the current SQLite release, these
records represent 504 species-name entries, including 502 single-species names
and two unresolved composite entries. By converting regional reference databases
into queryable, version-aware, assignment-ready research infrastructure,
`regionbarcoder` improves transparency and reproducibility in DNA-based
biodiversity monitoring.

## Introduction

Environmental DNA and metabarcoding approaches are now central to biodiversity
assessment, conservation genetics, and ecological monitoring. Their taxonomic
resolution depends strongly on the quality, completeness, and regional
relevance of reference databases. This dependence is especially acute in large
freshwater basins, where high species richness, endemism, taxonomic revision,
and uneven public sequence coverage can combine to produce false positives,
ambiguous assignments, or missed detections.

Regional reference databases address part of this problem by combining public
sequences, local expert knowledge, taxonomic checklists, and newly generated
references. Yet the products of these efforts often remain difficult to reuse.
A FASTA file can be used for assignment, but it rarely exposes the curation
history, quality-control decisions, marker coverage, source contribution, or
known ambiguity structure. Project scripts may reproduce a database once, but
they are not always designed as stable user interfaces for monitoring teams,
taxonomic experts, or downstream bioinformaticians.

Here we introduce `regionbarcoder`, an R package that turns regional DNA
reference databases into auditable ASV assignment infrastructure. Rather than
treating a reference database as a static sequence file, `regionbarcoder` treats
it as a versioned research object that can be queried, filtered, diagnosed,
exported, used for ASV assignment, and reported. The package is designed around
common needs in ecological metabarcoding: selecting marker-specific references,
restricting databases to a regional species pool, assigning ASV FASTA records to
regional taxa, generating sample-by-species matrices, documenting quality
control, and summarizing limits in taxonomic resolution before interpreting
assignment results.

## Software overview

`regionbarcoder` is organized around five linked tasks: data access, query,
export, ASV assignment, and diagnostics. The data access layer connects to SQLite reference
database releases and lists available tables with row counts. This design keeps
large databases on disk and avoids forcing users to load hundreds of megabytes
of sequence data into memory before filtering.

The query layer exposes explicit filters for taxonomy, marker, source,
occurrence status, and quality-control state. Users can retrieve all native 12S
references, all COI references from a given family, or all sequences associated
with a species or genus using the same function signature. Because these filters
are applied as SQL conditions, they remain reproducible and scalable for large
reference releases.

The export layer writes reference subsets for common metabarcoding workflows.
The current implementation supports DADA2, QIIME2, BLASTN, and
USEARCH/VSEARCH-style exports. Each exporter uses a consistent seven-rank
lineage composed of kingdom, phylum, class, order, family, genus, and species,
but adapts FASTA headers and taxonomy mapping files to the conventions expected
by each pipeline.

The ASV assignment layer begins downstream of read processing tools such as
DADA2 and QIIME2. Users provide an ASV FASTA file and select the appropriate
marker-specific reference subset. When BLAST+ is available,
`rb_assign_edna()` builds a temporary reference database, runs BLASTN, joins
hits to YZFishDB taxonomy, and reports a best assignment for each ASV. The
assignment table distinguishes unique high-confidence assignments, ambiguous
best hits, low-confidence hits, and ASVs without matches. A lightweight exact
matching mode is also provided for reproducible tests and demonstrations. If an
ASV count table is available, `rb_build_species_matrix()` aggregates assigned
ASVs into a sample-by-species community matrix.

The diagnostics layer summarizes features that are usually hidden when a
reference database is distributed only as FASTA. These include marker coverage
by taxonomic rank, source contributions by marker, quality-control outcomes,
barcode gap metrics, and manually curated ambiguous sequence records when these
tables are available. The aim is not only to prepare a reference database for
assignment, but also to make the limits of that database visible before
ecological conclusions are drawn.

## Case study: YZFishDB

We demonstrate `regionbarcoder` using YZFishDB, a curated DNA reference database
for ray-finned fishes of the Yangtze River Basin. YZFishDB integrates sequences
from BOLD, NCBI, MIDORI2, MitoFish, and local collections, and stores the
curated release in a SQLite database with source tables, raw sequence tables,
quality-control tables, and a final curated reference table. The final SQLite
release contains 54,546 curated sequences. Reproducible summaries generated by
`manuscript/build_manuscript_assets.R` report 504 species-name entries, of
which 502 are single-species names and two are unresolved composite entries.
This species-name count should be harmonized with the 503-taxon count reported
in the original YZFishDB database article before submission.

In the `regionbarcoder` workflow, users connect to the YZFishDB SQLite release,
inspect its tables, query reference subsets, and export those subsets for
downstream assignment. For example, a user can retrieve native 12S references
from the final curated table and export the result directly to DADA2 or QIIME2
without manually rewriting FASTA headers. The same database can be summarized to
show how marker coverage varies among taxa and how source databases contribute
to the final release. The first generated manuscript assets include marker
sequence counts (`manuscript/figures/marker_sequence_counts.png`),
source-by-marker contributions
(`manuscript/figures/source_marker_contribution.png`), and barcode gap status by
marker (`manuscript/figures/barcode_gap_status.png`).

This case study illustrates the broader software contribution. The original
database curation produced a high-quality regional reference resource.
`regionbarcoder` adds a stable interface for deployment and reuse: it separates
the database release from downstream export and assignment decisions, makes
filtering choices explicit, enables direct ASV-to-species workflows for Yangtze
River Basin fish eDNA data, and allows diagnostic summaries to be regenerated as
the database is updated.

## Demonstration workflow

A typical workflow begins by opening a database connection:

```r
library(regionbarcoder)

rb_install_db()
con <- rb_connect()
rb_tables(con)
```

The default database installer retrieves the archived YZFishDB SQLite release
from Zenodo (DOI: 10.5281/zenodo.18155084), caches it in the user's R data
directory, and verifies the archived file size and md5 checksum before use.

Users then retrieve a reference subset:

```r
native_12s <- rb_get_sequences(con, marker = "12S", occurrence = "native")
```

The selected sequences can be exported for multiple pipelines:

```r
rb_export_dada2(native_12s, "yzfishdb_native_12s_dada2.fasta")
rb_export_qiime2(native_12s, "yzfishdb_native_12s_qiime2.fasta",
                 "yzfishdb_native_12s_taxonomy.tsv")
rb_export_blastn(native_12s, "yzfishdb_native_12s_blastn.fasta")
rb_export_usearch(native_12s, "yzfishdb_native_12s_usearch.fasta")
```

Alternatively, users can assign ASVs directly:

```r
assignment <- rb_assign_edna("asvs.fasta", con = con, marker = "12S",
                             method = "blastn", min_identity = 99,
                             min_coverage = 0.90)
species_matrix <- rb_build_species_matrix(assignment, read.csv("asv_counts.csv"))
```

Before interpreting assignment results, users can summarize reference coverage
and quality-control outcomes:

```r
rb_marker_coverage(con)
rb_source_coverage(con)
rb_qc_summary(con)
```

This workflow makes database use reproducible at the level of code, not only at
the level of downloaded files. It also allows monitoring projects to report
which database version, marker subset, occurrence filter, and export convention
were used.

## Discussion

`regionbarcoder` addresses a gap between database curation and database use.
Regional DNA reference databases increasingly require expert taxonomic
decisions, local occurrence knowledge, contaminant screening, marker
classification, and sequence-level quality control. These decisions are
scientifically important, but they are easily flattened when a database is
distributed only as a final FASTA file. By providing a software interface for
querying and diagnosing reference databases, `regionbarcoder` helps keep these
decisions visible and reusable.

The framework is deliberately regional rather than global. This focus reflects
the practical needs of biomonitoring programs, where the relevant species pool,
non-native species list, marker choice, and acceptable ambiguity structure are
often region-specific. A regional database cannot eliminate all assignment
uncertainty. Recently diverged taxa, shared haplotypes, short amplicons, and
incomplete public data can still limit species-level resolution. However,
explicit diagnostics allow these limits to be reported before biodiversity
patterns are overinterpreted.

The first implementation prioritizes deployment, query, export, and diagnostics.
Full database rebuilding from public repositories requires additional external
tools such as BLAST+, MAFFT, and FastTree, and will be maintained as an
advanced workflow rather than a requirement for routine users. This separation
keeps the package useful for monitoring teams that need stable reference
exports while preserving a path for database curators to update future
releases.

The current asset-generation script writes the first quantitative manuscript
tables, including database table sizes, marker composition, source-marker
contributions, species-marker coverage, barcode gap summaries, and ambiguity
curation summaries. These tables should be treated as reproducible draft
outputs: they establish the analysis workflow, but values and labels should be
reviewed by the database authors before final submission.

For Molecular Ecology Resources or Methods in Ecology and Evolution, the key
contribution is not merely the availability of YZFishDB as an R object. The
contribution is a general framework for making regional reference databases
auditable, version-aware, interoperable with common metabarcoding pipelines, and
directly usable for ASV taxonomic assignment. YZFishDB provides a demanding case
study because it covers a large, species-rich, conservation-relevant river basin
with heterogeneous source data and documented curation decisions.

## Data and code availability

The `regionbarcoder` package is developed in R and will be archived with a
versioned release. The full YZFishDB SQLite database, source tables, quality
control outputs, barcode gap metrics, and workflow scripts are available in the
associated data release. The package supports local use of the full database
and includes tests that verify connection, query, export, and diagnostic
behavior.

## Acknowledgements

We thank the researchers and field teams who contributed to the construction of
YZFishDB and the broader Yangtze River Basin fish biodiversity monitoring
effort. Development of this software builds on the database curation workflow
and sequence resources assembled for YZFishDB.

## References

Callahan, B. J., McMurdie, P. J., Rosen, M. J., Han, A. W., Johnson, A. J. A.,
and Holmes, S. P. 2016. DADA2: High-resolution sample inference from Illumina
amplicon data. Nature Methods.

Iwasaki, W., Fukunaga, T., Isagozawa, R., Yamada, K., Maeda, Y., Satoh, T. P.,
Sado, T., Mabuchi, K., Takeshima, H., Miya, M., and others. 2013. MitoFish and
MitoAnnotator: A mitochondrial genome database of fish with an accurate and
automatic annotation pipeline. Molecular Biology and Evolution.

Kua, Z. X., Bing, H., Wu, Y., Shen, Y., Brosse, S., Zhang, J., Hu, Y., He, J.,
Xu, J., and Su, G. 2026. YZFishDB: A curated DNA reference database for the
fishes of the Yangtze River Basin. Aquatic Diversity and Ecology.

Leray, M., Knowlton, N., and Machida, R. J. 2022. MIDORI2: A collection of
quality controlled, preformatted, and regularly updated reference databases for
taxonomic assignment of eukaryotic mitochondrial sequences. Environmental DNA.
