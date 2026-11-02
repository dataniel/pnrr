#' Derive one piece of information from CPR numbers
#'
#' Vector versions of the selections in [pnrr::add_cpr_info()]: a vector of
#' CPR numbers in, one vector of the same length out. They belong inside
#' `dplyr::mutate()`, `dplyr::filter()` or `ifelse()`, where a data frame
#' function does not fit.
#'
#' @param x A vector of CPR numbers. Values are read after the same cleaning
#'   as [pnrr::clean_cpr()], so dashes, spaces and a lost leading zero do not
#'   matter. Numeric vectors and factors are converted with `as.character()`.
#'
#' @details
#' The values are exactly those of the matching selection in
#' [pnrr::add_cpr_info()], from the same native code:
#'
#' | Function | Selection | Type |
#' | --- | --- | --- |
#' | `cpr_birth_date()` | `bday` | Date |
#' | `cpr_birth_year()` | `byear` | integer |
#' | `cpr_sex()` | `sex` | integer, 1 male (odd final digit), 0 female |
#' | `cpr_valid()` | `valid` | logical, never `NA` |
#' | `cpr_mod11()` | `mod11` | logical, `NA` when not ten digits |
#'
#' Birth date, birth year and sex are `NA` where `cpr_valid()` is `FALSE`.
#' `cpr_valid()` checks ten digits and a real encoded date, not whether the
#' number was assigned to a person; modulus 11 is not part of it, because
#' the CPR office has issued numbers that fail it since 2007.
#'
#' Birth year is its own function rather than an option of
#' `cpr_birth_date()`, so each function always returns one type.
#'
#' Each call parses the CPR numbers again. That costs little, about a tenth
#' of a second per million values, but when you need several columns,
#' [pnrr::add_cpr_info()] parses once for all of them.
#'
#' For age, see [pnrr::cpr_age()].
#'
#' @return A vector of the same length as `x`, without names.
#'
#' @examples
#' x <- c("0101004007", "111111-1118", "101004007", "3102004007", NA)
#' cpr_birth_date(x)
#' cpr_birth_year(x)
#' cpr_sex(x)
#' cpr_valid(x)
#' cpr_mod11(x)
#'
#' # Typical use
#' # df |>
#' #   dplyr::filter(cpr_valid(pnr)) |>
#' #   dplyr::mutate(koen = ifelse(cpr_sex(pnr) == 1L, "Mand", "Kvinde"))
#'
#' @seealso [pnrr::cpr_age()], [pnrr::add_cpr_info()]
#' @name cpr_birth_date
NULL

#' @rdname cpr_birth_date
#' @export
cpr_birth_date <- function(x) .cpr_one(x, 0L, "cpr_birth_date()")

#' @rdname cpr_birth_date
#' @export
cpr_birth_year <- function(x) .cpr_one(x, 5L, "cpr_birth_year()")

#' @rdname cpr_birth_date
#' @export
cpr_sex <- function(x) .cpr_one(x, 2L, "cpr_sex()")

#' @rdname cpr_birth_date
#' @export
cpr_valid <- function(x) .cpr_one(x, 4L, "cpr_valid()")

#' @rdname cpr_birth_date
#' @export
cpr_mod11 <- function(x) .cpr_one(x, 3L, "cpr_mod11()")

#' Age from CPR numbers
#'
#' The vector version of the `age` selection in [pnrr::add_cpr_info()]: CPR
#' numbers in, ages in completed calendar years out. It takes the same
#' references as [pnrr::age()], but as values rather than column names, so
#' it fits inside `dplyr::mutate()`.
#'
#' @param x A vector of CPR numbers, cleaned as in [pnrr::clean_cpr()].
#' @param year Numeric whole year(s): one for all, or one per CPR number.
#'   Inside `dplyr::mutate()` this can be a column, e.g. `cpr_age(pnr, year)`.
#' @param at,date,primo As in [pnrr::age()]: `at` is `"primo"`, `"medio"` or
#'   `"ultimo"`; `date` is a Date vector or ISO date strings instead of
#'   `year`; `primo` is the convention for `at = "primo"`.
#'
#' @details
#' With neither `year` nor `date`, age is today's. Use an explicit reference
#' for reproducible analysis. The default `age(year)` convention applies:
#' primo is 31 December of the previous year, so opening ages equal the
#' previous year's closing ages. See [pnrr::age()] for the conventions and
#' [pnrr::add_cpr_info()] for leap-day birthdays.
#'
#' Ages are `NA` for CPR numbers that are not valid (see [pnrr::cpr_valid()])
#' and for missing references.
#'
#' @return An integer vector of the same length as `x`.
#'
#' @examples
#' x <- c("0101004007", "111111-1118", "3102004007")
#' cpr_age(x, 2025)
#' cpr_age(x, 2025, "ultimo")
#' cpr_age(x, date = "2025-07-01")
#' cpr_age(x, year = c(2024, 2025, 2025))
#'
#' # df |> dplyr::mutate(alder = cpr_age(pnr, year))
#'
#' @seealso [pnrr::age()], [pnrr::add_cpr_info()], [pnrr::cpr_birth_date()]
#' @export
cpr_age <- function(x, year, at = "primo", date, primo = "previous_ultimo") {
  x <- .cpr_input(x, "cpr_age()")
  # Values are captured as constant quosures: nothing is looked up by name.
  year <- if (!missing(year)) rlang::quo(!!year)
  date <- if (!missing(date)) rlang::quo(!!date)
  spec <- .age_spec(year, date, at, !missing(at), primo, !missing(primo), "cpr_age()")
  reference <- .cpr_reference_value(spec, rlang::eval_tidy(spec$reference), length(x), "cpr_age()")
  .Call(C_pnrr_cpr_info, x, 1L, list(reference))[[1L]]
}

.cpr_one <- function(x, code, fn) {
  x <- .cpr_input(x, fn)
  .Call(C_pnrr_cpr_info, x, code, list(NULL))[[1L]]
}

.cpr_input <- function(x, fn) {
  if (!is.atomic(x) || !is.null(dim(x))) {
    cli::cli_abort("{.arg x} in {.code {fn}} must be a vector of CPR numbers, e.g. {.code df$pnr}.")
  }
  if (!is.character(x)) x <- as.character(x)
  x
}
