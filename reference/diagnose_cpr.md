# Diagnose a column of CPR numbers

Reports what is wrong with a vector of CPR numbers before it is used as
a join key or passed on: how many are missing, which are malformed and
why, and the signs that a column has been through Excel or a numeric
conversion on the way. It is the question to ask of a CPR column you did
not produce yourself.

## Usage

``` r
diagnose_cpr(x, as_of = Sys.Date())
```

## Arguments

- x:

  A vector of CPR numbers, typically a column such as `df$pnr`. Numeric
  vectors and factors are converted with
  [`as.character()`](https://rdrr.io/r/base/character.html) first.

- as_of:

  The date the data describes, as a Date or an ISO date string
  (`YYYY-MM-DD`). Birth dates after it, or more than 120 years before
  it, are flagged. Defaults to today.

## Value

A `pnrr_diagnosis` object, printed as a short report. It is a list with
`n` (the number of values), `checks` (a data frame with one row per
check: `check`, `kind` (`"problem"` or `"note"`), `n`, and `rows`, a
list column of row numbers), `distinct` (the number of distinct valid
numbers), `birth_range` (the earliest and latest valid birth date),
`male_share` (the share of valid numbers with an odd final digit), and
`as_of`.

## Details

Every value gets exactly one status. These *problems* sum to the length
of `x`:

- `valid`: ten digits encoding a real birth date, after the same
  cleaning as
  [`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md).
  Validity is the same as in
  [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md).

- `missing`: `NA`, or empty once separators are removed.

- `scientific`: written in scientific notation, such as `"1.11111E+09"`.
  Excel and some exports do this to long numbers. The trailing digits
  are gone and cannot be restored; the source has to be read again with
  the column as text. `"1111111118.0"` and similar decimal forms are
  counted here too.

- `wrong_length`: only digits, but not nine or ten of them.

- `non_digit`: contains characters other than digits and separators.

- `invalid_date`: ten digits, but the first six are not a real date.

The *notes* overlap with the problems and with each other. They are not
errors, but each says something about where the data has been:

- `zero_restored`: nine digits, padded with a leading zero. Birth days
  01-09 make about a third of all CPR numbers start with a zero, and
  Excel drops it from numeric cells.

- `separators`: contained dashes, spaces or the invisible separators
  that
  [`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md)
  removes: tabs, line breaks, no-break spaces and typographic dashes.

- `mod11_fails`: valid, but fails the modulus-11 check. Since 2007 the
  CPR office issues numbers that do not satisfy it, so this is not an
  error by itself (<https://cpr.dk>). A large share among older birth
  dates can still point to typing errors.

- `repeated`: valid values that occur more than once. Expected in a
  panel with one row per person and year, a problem in a table of
  persons.

- `born_after_as_of` and `older_than_120`: valid numbers whose decoded
  birth date is implausible for the data. These are usually typing
  errors that happen to form a real date, or a wrong `as_of`.

The diagnosis never prints a CPR number, only counts and row numbers, so
its output can go into a log. The row numbers of every check are kept in
the returned object.

## See also

[`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md),
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)

## Examples

``` r
x <- c("0101004007", "010100-4007", "101004007", "1.01004E+08",
       "3102004007", "12345", "ukendt", NA, "1111111118")
diagnose_cpr(x, as_of = "2025-01-01")
#> ── CPR diagnosis ───────────────────────────────────────────────────────────────
#> ! 4 of 9 valid (2 distinct)
#> ✖ 1 missing (row 8)
#> ✖ 1 in scientific or decimal notation: digits are lost, read the source again as text (row 4)
#> ✖ 1 with the wrong number of digits (row 6)
#> ✖ 1 with characters other than digits and separators (row 7)
#> ✖ 1 with ten digits but no real birth date (row 5)
#> ℹ 1 had lost a leading zero (Excel), restored by cleaning (row 3)
#> ℹ 1 contained dashes, spaces or invisible separators (row 2)
#> ℹ 3 valid, sharing their CPR number with another row (rows 1, 2, 3)
#> Birth dates 1911-11-11 to 2000-01-01; 75.0% male.

# The rows behind a check
d <- diagnose_cpr(x, as_of = "2025-01-01")
d$checks$rows[d$checks$check == "scientific"][[1]]
#> [1] 4
```
