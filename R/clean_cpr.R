#' Standardise CPR numbers
#'
#' Cleans a vector of Danish CPR numbers to the canonical 10-digit form:
#' separators are stripped, and nine-digit values consisting only of
#' digits are zero-padded on the left. The padding is well-founded: birth
#' days 01-09 mean that roughly a third of all CPR numbers legitimately
#' start with a zero, which Excel silently drops from numeric cells.
#'
#' Separators are dashes and spaces, and the characters that Excel, Word and
#' copy-paste leave in their place and that cannot be told apart on screen:
#' tabs and line breaks, the no-break space, and the typographic dashes
#' (such as the en dash Word makes of a hyphen). Removing them never changes
#' a digit.
#'
#' This is standardisation only, not validation. Values that cannot be
#' brought to 10 digits are returned cleaned but otherwise untouched, so a
#' malformed number stays visibly malformed for downstream checks. Use
#' [pnrr::diagnose_cpr()] to see what is wrong with a column, and
#' [pnrr::add_cpr_info()] for validity per row.
#'
#' [pnrr::add_cpr_info()] applies this cleaning internally for its
#' calculations, while preserving the original CPR column in its output.
#' Both functions use the same native normalisation rules. Cleaning is
#' optional before `add_cpr_info()`; use it when you need a standardised
#' identifier for joins or export. Already clean character vectors are
#' returned without allocating a replacement vector.
#'
#' @param x A character vector of CPR numbers. Numeric vectors and factors
#'   are converted with `as.character()` first. Data frames and lists are an
#'   error: pass the column, e.g. `df$pnr`.
#'
#' @return A character vector of the same length.
#'
#' @examples
#' clean_cpr(c("111111-1118", "1111111118", "101004007", NA))
#'
#' # Typical use: standardise the join key on both sides
#' # df  |> dplyr::mutate(pnr = clean_cpr(pnr))
#'
#' @seealso [pnrr::add_cpr_info()], [pnrr::diagnose_cpr()]
#'
#' @export
clean_cpr <- function(x) {
  # Lists only: a matrix or other atomic input keeps its attributes.
  if (is.list(x)) {
    cli::cli_abort("{.arg x} in {.code clean_cpr()} must be a vector of CPR numbers, e.g. {.code df$pnr}.")
  }
  x <- .cpr_text(x)
  .Call(C_pnrr_clean_cpr, x)
}
