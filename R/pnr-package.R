#' pnr: Danish CPR numbers in register data
#'
#' The CPR number (personnummer) is the key of almost every Danish register,
#' and it arrives in every shape: with and without a dash, with the leading
#' zero lost in Excel, as a number in scientific notation. pnr holds the
#' functions that work on it. See `vignette("pnr")`.
#'
#' ## Where to start
#'
#' * [diagnose_cpr()]: what is wrong with a CPR column, in counts and row
#'   numbers, never in CPR numbers.
#' * [clean_cpr()]: the canonical ten-digit form, for joins and export.
#' * [add_cpr_info()] with [age()]: birth date, age, sex, modulus 11 and
#'   validity, in one native pass.
#' * [pseudo_cpr()]: random serial numbers in place of the CPR number.
#'
#' ## Why a package of its own
#'
#' `clean_cpr()`, `add_cpr_info()` and `age()` started in the daos package.
#' They moved here, unchanged, when the CPR work grew beyond deriving
#' columns: diagnosing a column and replacing the identifier belong with
#' them and not with the general utilities in daos. pnr depends only on cli
#' and rlang, and daos does not depend on it, or it on daos.
#'
#' @keywords internal
"_PACKAGE"
