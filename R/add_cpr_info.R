#' Add information derived from Danish CPR numbers
#'
#' Add selected CPR information without changing the original CPR column.
#'
#' @param .data A data frame or tibble.
#' @param .cpr_col CPR column, unquoted or a literal column-name string.
#' @param ... Information to add: `bday`, `byear`, `sex`, `koen`, `valid`,
#'   `status`, `mod11`, `age`, or [pnrr::age_at()] with a reference year or
#'   date. Name a selection to choose its output column, e.g.
#'   `birth_date = bday`. With no selections, adds `bday`, `age`, `sex`,
#'   `mod11`, and `valid`. Bare `age` uses today's date.
#' @param .overwrite Allow replacing existing output columns? Default `FALSE`.
#'   The CPR source column cannot be replaced.
#'
#' @details
#' | Selection | Value |
#' | --- | --- |
#' | `bday` | Birth date, a Date |
#' | `byear` | Birth year, an integer |
#' | `age`, `age_at()` | Completed calendar years, an integer |
#' | `sex` | Integer, 1 male (odd final digit), 0 female |
#' | `koen` | Integer, 1 male, 2 female: the coding of `KOEN` in the registers of Statistics Denmark |
#' | `valid` | Logical: ten digits and a real encoded date |
#' | `status` | Factor: why a value is or is not valid |
#' | `mod11` | Logical: the modulus-11 checksum |
#'
#' `valid` checks ten digits and a real encoded calendar date, not whether
#' the number was assigned to a person. Missing and malformed CPRs give
#' `valid = FALSE` and missing birth date, age, and sex.
#' `mod11` is a separate logical checksum, not a requirement for `valid`.
#' Malformed formats give a missing checksum.
#'
#' `status` says what `valid` cannot: its levels are `valid`, `missing`,
#' `scientific`, `wrong_length`, `non_digit` and `invalid_date`, the problems
#' of [pnrr::diagnose_cpr()], where they are explained. `diagnose_cpr()`
#' answers for a column, `status` for each row, so the rows can be filtered
#' or counted by group.
#'
#' `sex` and `koen` hold the same information in two codings. `sex` is 0/1,
#' which sums and averages directly; `koen` is 1/2 and compares directly
#' with the `KOEN` variable of the registers
#' (<https://www.dst.dk/da/TilSalg/data-til-forskning/generelt-om-data/dokumentation-af-data/hoejkvalitetsvariable/Folketal/KOEN>).
#'
#' CPR values are cleaned internally with [pnrr::clean_cpr()]. To also standardise
#' the source column, use `dplyr::mutate(pnr = clean_cpr(pnr))` explicitly.
#' Rows, row order, and input columns are preserved unless `.overwrite = TRUE`.
#' Duplicate output names are always an error.
#'
#' CPR parsing, calendar validation, and requested outputs share a single
#' native pass. Multiple age selections reuse the decoded birth date.
#' Pre-cleaning is optional: use [pnrr::clean_cpr()] when the source column
#' itself must be standardised for joins or export.
#'
#' For a single piece of information inside `dplyr::mutate()` or
#' `dplyr::filter()`, the vector functions [pnrr::cpr_birth_date()],
#' [pnrr::cpr_age()] and friends give the same values. Prefer
#' `add_cpr_info()` when you need several: it parses each CPR once.
#'
#' The arguments have a dot prefix, as in dplyr, so that an output name
#' never reaches them: R matches named arguments by partial name before
#' `...`, and `d = bday` or `cpr = age_at(year)` would otherwise be taken as
#' `data` or `cpr_col`.
#'
#' For 29 February births, age advances on 1 March in non-leap years.
#' A reference before birth gives a negative age. Use an explicit reference
#' for reproducible analysis; today's date changes between runs.
#'
#' In daos, `add_cpr_info()` took `add`, `ref_date`, `year` and `at`
#' arguments, and later the helper `age()`. Selections and
#' [pnrr::age_at()] replace them; each old form gives an error that points
#' to the new one.
#'
#' @return The input data frame with selected columns added in selection order.
#' @examples
#' df <- data.frame(pnr = c("0101004007", "111111-1118"), year = 2024:2025)
#' add_cpr_info(df, pnr)
#' add_cpr_info(df, pnr, sex, birth_date = bday)
#' add_cpr_info(df, pnr,
#'   primoalder = age_at(year), ultimoalder = age_at(year, "ultimo"), sex)
#' add_cpr_info(df, pnr, alder = age_at("2025-07-01"))
#'
#' # Why a value is not valid, and sex as in the registers
#' bad <- data.frame(pnr = c("0101004007", "3102004007", "1.01004E+08", NA))
#' add_cpr_info(bad, pnr, status, koen)
#' @seealso [pnrr::age_at()], [pnrr::clean_cpr()], [pnrr::cpr_birth_date()]
#' @useDynLib pnrr, .registration = TRUE, .fixes = "C_"
#' @export
add_cpr_info <- function(.data, .cpr_col, ..., .overwrite = FALSE) {
  data <- .data
  overwrite <- .overwrite
  if (!is.data.frame(data)) cli::cli_abort("{.arg .data} must be a data frame or tibble.")
  if (anyNA(names(data)) || any(names(data) == "") || anyDuplicated(names(data))) {
    cli::cli_abort("{.arg .data} must have unique, non-empty column names.")
  }
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    cli::cli_abort("{.arg .overwrite} must be TRUE or FALSE.")
  }
  if (missing(.cpr_col)) {
    if ("cpr_col" %in% names(rlang::enquos(...))) {
      cli::cli_abort("{.arg cpr_col} is now {.arg .cpr_col} in {.fn add_cpr_info}.")
    }
    cli::cli_abort("Name the CPR column in {.arg .cpr_col}, e.g. {.code add_cpr_info(df, pnr)}.")
  }
  col <- rlang::enquo(.cpr_col)
  if (!rlang::quo_is_symbol(col) && !rlang::is_string(rlang::quo_get_expr(col))) {
    cli::cli_abort("{.arg .cpr_col} must be an unquoted column name or a single string.")
  }
  source <- rlang::as_name(col)
  if (!source %in% names(data)) cli::cli_abort("Column {.var {source}} not found in data.")
  if (!is.atomic(data[[source]]) || !is.null(dim(data[[source]]))) {
    cli::cli_abort("The CPR column must be an atomic vector.")
  }
  selections <- rlang::enquos(..., .ignore_empty = "none")
  legacy <- intersect(names(selections), c("add", "ref_date", "year", "at"))
  # Order matches the codes of the native kernel.
  types <- c("bday", "age", "sex", "mod11", "valid", "byear", "koen", "status")
  if (!length(selections)) {
    defaults <- types[1:5]
    selections <- lapply(defaults, function(x) rlang::new_quosure(rlang::sym(x)))
    names(selections) <- rep("", length(defaults))
  }
  specs <- Map(function(q, name) {
    if (rlang::quo_is_missing(q)) cli::cli_abort("Empty CPR selection. Remove the extra comma or choose an information type.")
    expr <- rlang::quo_get_expr(q)
    if (rlang::is_symbol(expr) && rlang::as_string(expr) %in% types) {
      type <- rlang::as_string(expr)
      return(list(type = type, reference = if (type == "age") age_at() else NULL))
    }
    if (rlang::is_call(expr, "age")) {
      cli::cli_abort(c("{.fn age} is now {.fn age_at}.",
        "i" = 'The reference is one argument, a year or a date: {.code age_at(year, "ultimo")}, {.code age_at("2025-07-01")}, {.code age_at(date_column)}.',
        "i" = '{.code primo = "jan1"} is now {.code age_at(year, "jan1")}.'))
    }
    if (!rlang::is_call(expr, "age_at")) {
      if (name %in% c("data", "cpr_col", "overwrite")) {
        cli::cli_abort(c("{.arg {name}} is now {.arg .{name}} in {.fn add_cpr_info}.",
          "i" = "The dot keeps output names such as {.code d = bday} from being taken as arguments."))
      }
      if (length(legacy)) {
        cli::cli_abort(c("The CPR selection API has changed.",
          "i" = 'Use bare selections such as sex and bday, age_at(year, "ultimo"), or age_at(reference_date).',
          "i" = "Name outputs with alder = age_at(year). The old add/ref_date/year/at arguments are no longer supported."))
      }
      label <- rlang::as_label(q)
      cli::cli_abort(c("Unknown CPR selection: {.val {label}}.",
        "i" = 'Choose bday, byear, sex, koen, valid, status, mod11, age, or age_at(year, "ultimo").'))
    }
    # Resolve our helper explicitly; capture its arguments in the caller's
    # environment and evaluate references against data only afterwards.
    expr[[1L]] <- quote(.cpr_age_helper)
    env <- rlang::env(rlang::quo_get_env(q), .cpr_age_helper = age_at)
    list(type = "age", reference = rlang::eval_bare(expr, env))
  }, selections, names(selections))
  output <- names(selections)
  unnamed <- output == ""
  kinds <- vapply(specs, `[[`, character(1), "type")
  output[unnamed] <- kinds[unnamed]
  if (anyDuplicated(output)) {
    cli::cli_abort(c("Duplicate output column names.",
      "i" = 'Give each selection a unique name, e.g. primoalder = age_at(year), ultimoalder = age_at(year, "ultimo").'))
  }
  if (source %in% output) cli::cli_abort("The CPR source column {.var {source}} cannot be overwritten. Choose another output name.")
  collisions <- intersect(output, names(data))
  if (length(collisions) && !overwrite) {
    cli::cli_abort(c("Output columns already exist: {.var {collisions}}.",
      "i" = "Choose different output names or set .overwrite = TRUE."))
  }
  codes <- match(kinds, types) - 1L
  references <- lapply(seq_along(specs), function(i) {
    if (kinds[i] == "age") .cpr_reference(specs[[i]]$reference, data, output[i]) else NULL
  })
  # status describes the written form, so numbers are written out for it.
  cpr <- if ("status" %in% kinds) .cpr_text(data[[source]]) else .cpr_values(data[[source]])
  values <- .Call(C_pnrr_cpr_info, cpr, codes, references)
  # Compute against the original data, before any output is assigned.
  if (inherits(data, "data.table")) {
    # set() keeps the over-allocation that `[[<-` drops; without it the
    # caller's next := warns about a shallow copy.
    result <- data.table::copy(data)
    for (i in seq_along(output)) data.table::set(result, j = output[i], value = values[[i]])
  } else {
    result <- data
    for (i in seq_along(output)) result[[output[i]]] <- values[[i]]
  }
  result
}

#' The reference for an age from CPR numbers
#'
#' Use inside [pnrr::add_cpr_info()] to say when the age is measured:
#' `alder = age_at(year)`. It describes the reference; the age is calculated
#' by `add_cpr_info()`. For a vector of ages, see [pnrr::cpr_age()].
#'
#' @param ref The reference, as a value, a column of the data or an
#'   expression on its columns. Its type decides what it is:
#'
#'   * whole numbers are **years**, and `at` chooses the day in the year;
#'   * a Date vector or ISO date strings (`"YYYY-MM-DD"`) are **dates**.
#'
#'   One value for all rows, or one per row. Left out, the reference is
#'   today, `Sys.Date()`.
#' @param at The day in the year, when `ref` is a year:
#'
#'   * `"primo"` (default): 31 December of the year **before**, the opening
#'     of the year. `age_at(2025)` is the age on 31 December 2024.
#'   * `"jan1"`: 1 January.
#'   * `"medio"`: 1 July.
#'   * `"ultimo"`: 31 December.
#'
#'   Not allowed when `ref` is a date.
#'
#' @details
#' **Why primo is the day before.** In population statistics the opening
#' population of a year is the closing population of the year before, and
#' the ages must agree: `age_at(year)` equals `age_at(year - 1, "ultimo")`.
#' A person born on 1 January 2000 is therefore 0 in `age_at(2001)`. Use
#' `"jan1"` to count that birthday, which gives 1. The choice moves the age
#' reference only, not who is in the population.
#'
#' Missing references give missing ages. A data column takes precedence over
#' a variable of the same name where the function is called; `.env$name` and
#' `.data$name` make the source explicit. A number is always a year: for a
#' date held as a number, convert it with `as.Date()` first.
#'
#' The name says what the argument is, the time the age is measured at. In
#' daos the helper was `age(year, at, date, primo)`. `date` is now the same
#' argument as the year, and `primo = "jan1"` is the `at` value `"jan1"`.
#'
#' @return An age specification for [pnrr::add_cpr_info()].
#' @examples
#' df <- data.frame(pnr = "0101004007", year = 2025L,
#'                  seen = as.Date("2025-07-01"))
#' add_cpr_info(df, pnr, age_at(year), sex)
#' add_cpr_info(df, pnr,
#'   primo = age_at(year),
#'   jan1 = age_at(year, "jan1"),
#'   ultimo = age_at(year, "ultimo"))
#' add_cpr_info(df, pnr, alder = age_at("2025-07-01"))
#' add_cpr_info(df, pnr, alder = age_at(seen))
#' @seealso [pnrr::add_cpr_info()], [pnrr::cpr_age()]
#' @export
age_at <- function(ref, at = "primo") {
  ref <- if (!missing(ref)) rlang::enquo(ref)
  .age_spec(ref, at, !missing(at), "age_at()")
}

# Shared by age_at() and cpr_age(): ref is a quosure or NULL, and fn names
# the function the user called, for the error messages.
.age_spec <- function(ref, at, at_given, fn) {
  if (is.null(ref) && at_given) {
    cli::cli_abort("{.arg at} needs a year in {.code {fn}}; without a reference the age is today's.")
  }
  at <- rlang::arg_match(at, c("primo", "jan1", "medio", "ultimo"))
  structure(list(reference = ref %||% rlang::quo(Sys.Date()), at = at, at_given = at_given),
            class = "pnrr_cpr_age")
}

.cpr_reference <- function(spec, data, output) {
  value <- tryCatch(rlang::eval_tidy(spec$reference, data), error = function(e) {
    cli::cli_abort("Cannot evaluate the age reference for {.var {output}}.", parent = e)
  })
  .cpr_reference_value(spec, value, nrow(data), output)
}

# Validate an evaluated reference and encode it for the native kernel:
# value, kind (0 year, 1 Date, 2 ISO strings), month and day as mmdd for a
# year, the output name, and what is added to a year.
.cpr_reference_value <- function(spec, value, n, output) {
  if (!length(value) %in% c(1L, n) || !is.null(dim(value))) {
    cli::cli_abort("Reference for {.var {output}} must have length 1 or one value per row ({n}).")
  }
  # A column that is all NA is read as logical; it is a missing year.
  if (is.logical(value) && all(is.na(value))) value <- as.integer(value)
  if (is.numeric(value) && !is.object(value)) {
    # Checked natively and passed on as it is, integer or double: on a
    # column of years the same test in R cost more than the whole kernel.
    primo <- spec$at == "primo"
    status <- .Call(C_pnrr_year_status, value, if (primo) 2L else 1L)
    if (status == 1L) {
      cli::cli_abort(c("Years for {.var {output}} must be whole numbers between 1 and 9999.",
        "i" = "A number is read as a year. For a date, give a Date or an ISO date string (YYYY-MM-DD)."))
    }
    if (status == 2L) {
      cli::cli_abort('Years for {.var {output}} must be at least 2 with at = "primo", which is 31 December of the year before.')
    }
    # primo is the ultimo of the year before: 31 December, year - 1.
    mmdd <- switch(spec$at, primo = 1231L, jan1 = 101L, medio = 701L, ultimo = 1231L)
    return(list(value, 0L, mmdd, output, if (primo) -1L else 0L))
  }
  ok <- is.character(value) || (inherits(value, "Date") && !any(is.infinite(value)))
  if (!ok) {
    cli::cli_abort(c("The reference for {.var {output}} must be whole years, a Date vector or ISO date strings (YYYY-MM-DD).",
      "i" = "Convert a date-time with {.fn as.Date} first."))
  }
  if (spec$at_given) {
    cli::cli_abort(c("{.arg at} is only used with a year, and the reference for {.var {output}} is a date.",
      "i" = "Leave {.arg at} out: a date is already a day."))
  }
  if (is.character(value)) return(list(value, 2L, 0L, output))
  list(as.double(value), 1L, 0L, output)
}
