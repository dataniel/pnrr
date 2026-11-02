#' Diagnose a column of CPR numbers
#'
#' Reports what is wrong with a vector of CPR numbers before it is used as a
#' join key or passed on: how many are missing, which are malformed and why,
#' and the signs that a column has been through Excel or a numeric
#' conversion on the way. It is the question to ask of a CPR column you did
#' not produce yourself.
#'
#' @param x A vector of CPR numbers, typically a column such as `df$pnr`.
#'   Numeric vectors and factors are converted with `as.character()` first.
#' @param as_of The date the data describes, as a Date or an ISO date string
#'   (`YYYY-MM-DD`). Birth dates after it, or more than 120 years before it,
#'   are flagged. Defaults to today.
#'
#' @details
#' Every value gets exactly one status. These *problems* sum to the length
#' of `x`:
#'
#' * `valid`: ten digits encoding a real birth date, after the same
#'   cleaning as [pnr::clean_cpr()]. Validity is the same as in
#'   [pnr::add_cpr_info()].
#' * `missing`: `NA`, or empty once dashes and spaces are removed.
#' * `scientific`: written in scientific notation, such as `"1.11111E+09"`.
#'   Excel and some exports do this to long numbers. The trailing digits are
#'   gone and cannot be restored; the source has to be read again with the
#'   column as text.
#'   `"1111111118.0"` and similar decimal forms are counted here too.
#' * `wrong_length`: only digits, but not nine or ten of them.
#' * `non_digit`: contains characters other than digits, dashes and spaces.
#' * `invalid_date`: ten digits, but the first six are not a real date.
#'
#' The *notes* overlap with the problems and with each other. They are not
#' errors, but each says something about where the data has been:
#'
#' * `zero_restored`: nine digits, padded with a leading zero. Birth days
#'   01-09 make about a third of all CPR numbers start with a zero, and
#'   Excel drops it from numeric cells.
#' * `separators`: contained dashes or spaces.
#' * `mod11_fails`: valid, but fails the modulus-11 check. Since 2007 the CPR
#'   office issues numbers that do not satisfy it, so this is not an error by
#'   itself (<https://cpr.dk>). A large share among older birth dates can
#'   still point to typing errors.
#' * `repeated`: valid values that occur more than once. Expected in a panel
#'   with one row per person and year, a problem in a table of persons.
#' * `born_after_as_of` and `older_than_120`: valid numbers whose decoded
#'   birth date is implausible for the data. These are usually typing errors
#'   that happen to form a real date, or a wrong `as_of`.
#'
#' The diagnosis never prints a CPR number, only counts and row numbers, so
#' its output can go into a log. The row numbers of every check are kept in
#' the returned object.
#'
#' @return A `pnr_diagnosis` object, printed as a short report. It is a list
#'   with `n` (the number of values), `checks` (a data frame with one row per
#'   check: `check`, `kind` (`"problem"` or `"note"`), `n`, and `rows`, a list
#'   column of row numbers), `distinct` (the number of distinct valid
#'   numbers), `birth_range` (the earliest and latest valid birth date),
#'   `male_share` (the share of valid numbers with an odd final digit), and
#'   `as_of`.
#'
#' @examples
#' x <- c("0101004007", "010100-4007", "101004007", "1.01004E+08",
#'        "3102004007", "12345", "ukendt", NA, "1111111118")
#' diagnose_cpr(x, as_of = "2025-01-01")
#'
#' # The rows behind a check
#' d <- diagnose_cpr(x, as_of = "2025-01-01")
#' d$checks$rows[d$checks$check == "scientific"][[1]]
#'
#' @seealso [pnr::clean_cpr()], [pnr::add_cpr_info()]
#' @export
diagnose_cpr <- function(x, as_of = Sys.Date()) {
  if (!is.atomic(x) || !is.null(dim(x))) {
    cli::cli_abort("{.arg x} must be a vector of CPR numbers, e.g. {.code df$pnr}.")
  }
  as_of <- .as_of_date(as_of)
  if (!is.character(x)) x <- as.character(x)
  oldest <- as.POSIXlt(as_of)
  oldest$year <- oldest$year - 120L
  oldest <- as.Date(oldest)

  # One native pass classifies every value and collects the row numbers;
  # only repeats are found here, from a numeric key of the valid values.
  res <- .Call(C_pnr_cpr_diagnose, x, as.double(as_of), as.double(oldest))
  rows <- res[[1L]]
  valid_rows <- rows[[1L]]
  v <- res[[2L]][valid_rows]
  first <- duplicated(v)
  repeated <- valid_rows[first | duplicated(v, fromLast = TRUE)]
  rows <- c(rows[1:9], list(repeated), rows[10:11])

  problems <- c("valid", "missing", "scientific", "wrong_length", "non_digit", "invalid_date")
  notes <- c("zero_restored", "separators", "mod11_fails", "repeated",
             "born_after_as_of", "older_than_120")
  checks <- data.frame(
    check = c(problems, notes),
    kind = rep(c("problem", "note"), c(length(problems), length(notes))),
    n = lengths(rows)
  )
  checks$rows <- rows

  n_valid <- length(valid_rows)
  structure(list(
    n = length(x),
    checks = checks,
    distinct = n_valid - sum(first),
    birth_range = as.Date(res[[3L]]),
    male_share = if (n_valid) res[[4L]] / n_valid else NA_real_,
    as_of = as_of
  ), class = "pnr_diagnosis")
}

.as_of_date <- function(as_of) {
  ok <- length(as_of) == 1L && !is.na(as_of)
  if (ok && is.character(as_of)) {
    ok <- grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", as_of)
    as_of <- if (ok) as.Date(as_of, optional = TRUE) else NA
    ok <- ok && !is.na(as_of)
  } else if (ok) {
    ok <- inherits(as_of, "Date") && is.finite(as_of)
  }
  if (!ok) cli::cli_abort("{.arg as_of} must be one Date or ISO date string (YYYY-MM-DD).")
  as_of
}

#' @export
format.pnr_diagnosis <- function(x, ...) {
  ck <- x$checks
  get <- function(check) ck[ck$check == check, , drop = FALSE]
  num <- function(k) format(k, big.mark = ",", scientific = FALSE, trim = TRUE)
  where <- function(rows) {
    shown <- paste(num(utils::head(rows, 5L)), collapse = ", ")
    if (length(rows) > 5L) shown <- paste0(shown, ", ... and ", num(length(rows) - 5L), " more")
    paste0(" (row", if (length(rows) > 1L) "s", " ", shown, ")")
  }
  line <- function(check, text) {
    r <- get(check)
    if (!r$n) return(NULL)
    rows <- r$rows[[1L]]
    paste0(num(r$n), " ", text, if (check != "valid") where(rows))
  }
  valid <- get("valid")$n
  problem_text <- c(
    missing = "missing",
    scientific = "in scientific or decimal notation: digits are lost, read the source again as text",
    wrong_length = "with the wrong number of digits",
    non_digit = "with characters other than digits, dashes and spaces",
    invalid_date = "with ten digits but no real birth date"
  )
  note_text <- c(
    zero_restored = "had lost a leading zero (Excel), restored by cleaning",
    separators = "contained dashes or spaces",
    mod11_fails = "valid but fail modulus 11 (allowed since 2007)",
    repeated = "valid, sharing their CPR number with another row",
    born_after_as_of = paste("born after", format(x$as_of)),
    older_than_120 = paste("older than 120 on", format(x$as_of))
  )
  problems <- unlist(lapply(names(problem_text), function(p) line(p, problem_text[[p]])))
  notes <- unlist(lapply(names(note_text), function(p) line(p, note_text[[p]])))
  summary <- paste0(num(valid), " of ", num(x$n), " valid",
    if (valid) paste0(" (", num(x$distinct), " distinct)"))
  profile <- if (valid) paste0("Birth dates ", format(x$birth_range[1L]), " to ",
    format(x$birth_range[2L]), "; ", sprintf("%.1f", 100 * x$male_share), "% male.")
  list(summary = summary, problems = problems, notes = notes, profile = profile)
}

#' @export
print.pnr_diagnosis <- function(x, ...) {
  f <- format(x)
  cli::cli_rule(left = "CPR diagnosis")
  esc <- function(s) gsub("}", "}}", gsub("{", "{{", s, fixed = TRUE), fixed = TRUE)
  if (length(f$problems)) cli::cli_alert_warning(esc(f$summary)) else cli::cli_alert_success(esc(f$summary))
  for (p in f$problems) cli::cli_alert_danger(esc(p))
  for (p in f$notes) cli::cli_alert_info(esc(p))
  if (!is.null(f$profile)) cli::cli_text(esc(f$profile))
  invisible(x)
}
