rb_build_taxonomy_string <- function(data, style = c("plain", "rank_prefix")) {
  style <- match.arg(style)
  ranks <- c("kingdom", "phylum", "class", "order", "family", "genus", "species")
  rb_required_columns(data, ranks)
  prefixes <- c("k", "p", "c", "o", "f", "g", "s")
  apply(data[, ranks, drop = FALSE], 1, function(row) {
    vals <- as.character(row)
    vals[is.na(vals) | vals == ""] <- "unassigned"
    if (identical(style, "rank_prefix")) vals <- paste0(prefixes, "__", vals)
    paste(vals, collapse = ";")
  })
}
