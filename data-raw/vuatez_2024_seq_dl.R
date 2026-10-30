library(ape)
library(tidyverse)

# 1. Read the metadata
# (Assuming you saved the CSV in your data-raw folder)
meta <- read.csv("data-raw/vuatez_2024_table_s2.csv", stringsAsFactors = FALSE, check.names = FALSE)

# 2. Filter for rows that have a valid GenBank ID
meta_gb <- meta[!is.na(meta$`GenBank ID`) & meta$`GenBank ID` != "", ]
meta_gb$`GenBank ID` <- trimws(as.character(meta_gb$`GenBank ID`))

cat(sprintf("Found %d sequences with GenBank IDs.\n", nrow(meta_gb)))

# 3. Download sequences from GenBank in chunks to avoid NCBI API timeouts
chunk_size <- 100
seq_list <- list()

for(i in seq(1, nrow(meta_gb), chunk_size)) {
  chunk_ids <- meta_gb$`GenBank ID`[i:min(i+chunk_size-1, nrow(meta_gb))]
  cat(sprintf("Downloading chunk %d to %d...\n", i, i+length(chunk_ids)-1))
  
  # read.GenBank returns a list of character vectors
  chunk_seqs <- tryCatch(
    read.GenBank(chunk_ids, as.character = TRUE),
    error = function(e) {
      message("Error downloading chunk: ", e$message)
      NULL
    }
  )
  
  if(!is.null(chunk_seqs)) {
    seq_list <- c(seq_list, chunk_seqs)
  }
  Sys.sleep(1) # Be nice to NCBI servers
}

# 4. Format into a dataframe
fasta_df <- data.frame(
  seq_id = names(seq_list),
  sequence = sapply(seq_list, paste, collapse = ""),
  stringsAsFactors = FALSE
)

# 5. Merge back with metadata and standardize columns for rb_create_db()
final_meta <- merge(fasta_df, meta_gb, by.x = "seq_id", by.y = "GenBank ID", all.x = TRUE) |>
  filter(`Morphological ID 2023` != "sp.") |>
  mutate(species = `Morphological ID 2023`,
         marker = "COI",
         source = "Vuataz_et_al_2024",
         qc_flag = "pass",
         unique_code = paste0("Vuatez_", seq_id))

# 6. Save the flat files to disk
write.csv(final_meta, "data-raw/plecoptera_metadata.csv", row.names = FALSE)

fasta_lines <- c()
for(i in 1:nrow(final_meta)) {
  fasta_lines <- c(fasta_lines, paste0(">", final_meta$unique_code[i]), final_meta$sequence[i])
}
writeLines(fasta_lines, "data-raw/plecoptera_sequences.fasta")

cat("Files successfully generated and ready for rb_create_db()!\n")
