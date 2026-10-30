\name{rb_tie_break}
\alias{rb_tie_break}
\alias{rb_apply_curation}
\title{Resolve ambiguous taxonomic assignments (Tie-breaking)}
\description{
  Functions to handle manual curation of ambiguous taxonomic assignments
  (where an ASV yields multiple top hits with identical alignment scores).
  
  \code{rb_tie_break()} initiates an interactive console session to resolve
  ties sequentially and generates a reproducible audit log.
  
  \code{rb_apply_curation()} programmatically applies a curation log (e.g., 
  imported from a CSV file) to the assignment results.
}
\usage{
rb_tie_break(assignments, curator = NULL)

rb_apply_curation(assignments, curation_log)
}
\arguments{
  \item{assignments}{A data frame of assignment results, typically the output
    of \code{rb_assign_edna()} or \code{rb_score_assignments()}.}
  \item{curator}{Character string identifying the person making the curation
    decisions. If \code{NULL}, \code{rb_tie_break()} will prompt for a name.}
  \item{curation_log}{A data frame containing at least \code{asv_id} and
    \code{selected_taxon} columns. Optional columns include \code{justification}
    and \code{curator}.}
}
\value{
  Both functions return the updated \code{assignments} data frame where 
  resolved ASVs have their \code{assignment_status} changed to 
  \code{"resolved_manual"} and \code{confidence} to \code{"high"}.
  
  \code{rb_tie_break()} additionally attaches the complete curation log as 
  an attribute accessible via \code{attr(result, "curation_log")}.
}
\details{
  \code{rb_tie_break()} presents each tied ASV, its alignment metrics, and 
  the list of tied species. The user can select a taxon by entering its 
  corresponding number, enter \code{0} to leave the ASV unresolved (ambiguous), 
  or \code{S} to skip it.
  
  To export the log for external review, use \code{write.csv(attr(res, "curation_log"), "log.csv")}.
  Once edited, read it back in and use \code{rb_apply_curation()} to update the assignments.
}
\examples{
\dontrun{
  # Interactive resolution
  assignments_curated <- rb_tie_break(assignments, curator = "Dr. Smith")
  
  # Extract and save the audit log
  log <- attr(assignments_curated, "curation_log")
  write.csv(log, "curation_audit.csv", row.names = FALSE)
  
  # Later, apply an external log
  external_log <- read.csv("curation_audit.csv")
  assignments_final <- rb_apply_curation(assignments, external_log)
}
}