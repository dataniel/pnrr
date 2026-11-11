#' Derive one piece of information from CPR numbers
#'
#' Vector versions of the selections in [pnrr::add_cpr_info()]: a vector of
#' CPR numbers in, one vector of the same length out. They belong inside
#' `dplyr::mutate()`, `dplyr::filter()` or `ifelse()`, where a data frame
#' function does not fit.
#'
#' @param x A vector of CPR numbers. Values are read after the same cleaning
#'   as [pnrr::clean_cpr()], so dashes, spaces and a lost leading zero do not
#'   matter. Numbers are read as their digits, and factors as their labels.
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
#' | `cpr_koen()` | `koen` | integer, 1 male, 2 female |
#' | `cpr_valid()` | `valid` | logical, never `NA` |
#' | `cpr_status()` | `status` | factor, never `NA` |
#' | `cpr_mod11()` | `mod11` | logical, `NA` when not ten digits |
#'
#' Birth date, birth year and sex are `NA` where `cpr_valid()` is `FALSE`.
#' `cpr_valid()` checks ten digits and a real encoded date, not whether the
#' number was assigned to a person; modulus 11 is not part of it, because
#' the CPR office has issued numbers that fail it since 2007.
#'
#' `cpr_status()` says why. Its levels are `valid`, `missing`, `scientific`,
#' `wrong_length`, `non_digit` and `invalid_date`: the problems of
#' [pnrr::diagnose_cpr()], where each is explained, and always in agreement
#' with it. `cpr_status(x) == "valid"` is `cpr_valid(x)`. It is a factor so
#' that `table(cpr_status(x))` also shows the problems that did not occur.
#'
#' `cpr_sex()` and `cpr_koen()` hold the same information in two codings.
#' `cpr_sex()` is 0/1, which sums and averages directly. `cpr_koen()` is 1/2
#' as `KOEN` in the registers of Statistics Denmark, so the two can be
#' compared without recoding.
#'
#' Birth year is its own function rather than an option of
#' `cpr_birth_date()`, so each function always returns one type.
#'
#' Each call parses the CPR numbers again. That costs little, a few
#' hundredths of a second per million values, but when you need several
#' columns, [pnrr::add_cpr_info()] parses once for all of them.
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
#' cpr_koen(x)
#' cpr_valid(x)
#' cpr_status(x)
#' table(cpr_status(x))
#' cpr_mod11(x)
#'
#' # Typical use
#' # df |>
#' #   dplyr::filter(cpr_valid(pnr)) |>
#' #   dplyr::mutate(koen = ifelse(cpr_sex(pnr) == 1L, "Mand", "Kvinde"))
#'
#' @seealso [pnrr::cpr_age()], [pnrr::add_cpr_info()], [pnrr::diagnose_cpr()]
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
cpr_koen <- function(x) .cpr_one(x, 6L, "cpr_koen()")

#' @rdname cpr_birth_date
#' @export
cpr_status <- function(x) .cpr_one(x, 7L, "cpr_status()")

#' @rdname cpr_birth_date
#' @export
cpr_mod11 <- function(x) .cpr_one(x, 3L, "cpr_mod11()")

#' Age from CPR numbers
#'
#' The vector version of the `age` selection in [pnrr::add_cpr_info()]: CPR
#' numbers in, ages in completed calendar years out. It takes the same
#' reference as [pnrr::age_at()], but as a value rather than a column name,
#' so it fits inside `dplyr::mutate()`.
#'
#' @param x A vector of CPR numbers, cleaned as in [pnrr::clean_cpr()].
#' @param ref The reference: whole numbers are years, a Date vector or ISO
#'   date strings (`"YYYY-MM-DD"`) are dates. One for all, or one per CPR
#'   number. Inside `dplyr::mutate()` this can be a column, e.g.
#'   `cpr_age(pnr, year)`. Left out, the age is today's.
#' @param at The day in the year, when `ref` is a year: `"primo"` (default,
#'   31 December of the year before), `"jan1"`, `"medio"` (1 July) or
#'   `"ultimo"` (31 December). As in [pnrr::age_at()].
#'
#' @details
#' Use an explicit reference for reproducible analysis; today's date changes
#' between runs. `cpr_age(x, 2025)` is the age on 31 December 2024: primo is
#' the closing of the year before, so opening ages equal the previous year's
#' closing ages. See [pnrr::age_at()] for the reasoning and
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
#' cpr_age(x, "2025-07-01")
#' cpr_age(x, c(2024, 2025, 2025))
#'
#' # df |> dplyr::mutate(alder = cpr_age(pnr, year))
#'
#' @seealso [pnrr::age_at()], [pnrr::add_cpr_info()], [pnrr::cpr_birth_date()]
#' @export
cpr_age <- function(x, ref, at = "primo") {
  x <- .cpr_input(x, "cpr_age()")
  # The value is captured as a constant quosure: nothing is looked up by name.
  ref <- if (!missing(ref)) rlang::quo(!!ref)
  spec <- .age_spec(ref, at, !missing(at), "cpr_age()")
  reference <- .cpr_reference_value(spec, rlang::eval_tidy(spec$reference), length(x), "cpr_age()")
  .Call(C_pnrr_cpr_info, x, 1L, list(reference))[[1L]]
}

.cpr_one <- function(x, code, fn) {
  # status describes the written form, so numbers are written out for it.
  x <- if (code == 7L) .cpr_text(.cpr_input(x, fn)) else .cpr_input(x, fn)
  .Call(C_pnrr_cpr_info, x, code, list(NULL))[[1L]]
}

.cpr_input <- function(x, fn) {
  if (!is.atomic(x) || !is.null(dim(x))) {
    cli::cli_abort("{.arg x} in {.code {fn}} must be a vector of CPR numbers, e.g. {.code df$pnr}.")
  }
  .cpr_values(x)
}

# Input for the native kernel. Character and plain numeric vectors go as
# they are: the kernel reads the digits of a number directly, which is
# many times faster than as.character() on a long column. Everything else,
# such as a factor, is converted first.
.cpr_values <- function(x) {
  if (is.character(x) || (is.numeric(x) && !is.object(x))) x else as.character(x)
}

# Text for the functions that work on the written form. as.character()
# writes whole numbers with many trailing zeros as "1.01e+09"; the digits
# are all there in the number, so those are written out in full.
.cpr_text <- function(x) {
  if (is.character(x)) return(x)
  text <- as.character(x)
  if (is.double(x) && !is.object(x)) {
    sci <- grepl("e", text, fixed = TRUE)
    if (any(sci)) {
      sci <- which(sci & is.finite(x) & x == trunc(x) & abs(x) < 1e15)
      text[sci] <- sprintf("%.0f", x[sci])
    }
  }
  text
}
