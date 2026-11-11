#' Replace CPR numbers with random serial numbers
#'
#' Gives every distinct CPR number a serial number, `1` to the number of
#' distinct values, in random order. The same CPR number gets the same
#' serial number throughout the vector, so persons can still be followed
#' across rows, but the number itself carries nothing about the person.
#'
#' @param x A vector of CPR numbers. Values are matched after the same
#'   cleaning as [pnrr::clean_cpr()], so `"010100-4007"` and `"101004007"`
#'   get the same serial number as `"0101004007"`.
#' @param seed Optional single whole number. With a seed, the same input
#'   gives the same serial numbers on every run; the global random number
#'   stream is left as it was. Without one, every call draws anew. A seed
#'   is a secret: see Details.
#'
#' @details
#' **Why random order.** Numbering in sorted order would make the serial
#' number follow the birth date, the first six digits of the CPR number.
#' Numbering in order of appearance would tie it to the row order of the
#' source file. A random order avoids both.
#'
#' **No key is kept.** The mapping exists only for the duration of the call
#' and is not returned. Two calls therefore give unrelated serial numbers,
#' also on overlapping data. To link several tables, pseudonymise them in
#' one call, for example on the bound key columns, or join first and
#' pseudonymise the result. A fixed `seed` reproduces the numbering only for
#' exactly the same input; it is not a key that links different data sets.
#'
#' **A seed is a secret.** With a seed, the numbering is a fixed shuffle of
#' the CPR numbers in their order of first appearance. Anyone who knows the
#' seed and the number of distinct values can redo the shuffle and read off,
#' for every serial number, where in the source that person first appeared;
#' with the source file, that is the CPR number. Keep the seed, and a script
#' that contains it, inside the secure environment with the source data.
#' Without a seed there is nothing to keep.
#'
#' **Pseudonymous, not anonymous.** Replacing the identifier does not make
#' the data anonymous in the sense of the GDPR. Birth date, sex,
#' municipality and other columns can still single out a person. Derive
#' what you need with [pnrr::add_cpr_info()] before the CPR column is
#' replaced, and remove the original column afterwards.
#'
#' Missing values, and values that are empty after cleaning, stay `NA`.
#' Malformed values that are not empty get a serial number like any other
#' value; check them first with [pnrr::diagnose_cpr()].
#'
#' @return An integer vector of the same length as `x`.
#'
#' @examples
#' x <- c("0101004007", "1111111118", "010100-4007", NA, "101004007")
#' pseudo_cpr(x)
#' pseudo_cpr(x, seed = 1)
#'
#' # Typical use: derive what is needed, then replace the identifier
#' # df |>
#' #   add_cpr_info(pnr, bday, sex) |>
#' #   dplyr::mutate(id = pseudo_cpr(pnr), pnr = NULL)
#'
#' @seealso [pnrr::diagnose_cpr()], [pnrr::clean_cpr()]
#' @export
pseudo_cpr <- function(x, seed = NULL) {
  if (!is.atomic(x) || !is.null(dim(x))) {
    cli::cli_abort("{.arg x} must be a vector of CPR numbers, e.g. {.code df$pnr}.")
  }
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L || is.na(seed) ||
                         seed != trunc(seed) || abs(seed) > .Machine$integer.max)) {
    cli::cli_abort("{.arg seed} must be NULL or a single whole number.")
  }
  x <- .cpr_text(x)
  x <- .Call(C_pnrr_clean_cpr, unname(x))
  x[!is.na(x) & x == ""] <- NA_character_
  keys <- unique(x[!is.na(x)])
  serial <- if (is.null(seed)) sample.int(length(keys)) else .with_seed(seed, sample.int(length(keys)))
  serial[match(x, keys)]
}

# Draw with a fixed seed without disturbing the caller's random stream.
.with_seed <- function(seed, expr) {
  env <- globalenv()
  had <- exists(".Random.seed", envir = env, inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = env, inherits = FALSE)
  on.exit(if (had) assign(".Random.seed", old, envir = env) else
    rm(".Random.seed", envir = env))
  set.seed(seed)
  expr
}
