# Add information derived from Danish CPR numbers

Add selected CPR information without changing the original CPR column.

## Usage

``` r
add_cpr_info(.data, .cpr_col, ..., .overwrite = FALSE)
```

## Arguments

- .data:

  A data frame or tibble.

- .cpr_col:

  CPR column, unquoted or a literal column-name string.

- ...:

  Information to add: `bday`, `byear`, `sex`, `valid`, `mod11`, `age`,
  or [`age()`](https://dataniel.github.io/pnrr/reference/age.md) with a
  reference year or date. Name a selection to choose its output column,
  e.g. `birth_date = bday`. With no selections, adds `bday`, `age`,
  `sex`, `mod11`, and `valid`. Bare `age` uses today's date.

- .overwrite:

  Allow replacing existing output columns? Default `FALSE`. The CPR
  source column cannot be replaced.

## Value

The input data frame with selected columns added in selection order.

## Details

`bday` is a Date; `byear` is the birth year (integer), not among the
defaults; `age` is completed calendar years (integer); `sex` is integer
1 for an odd final digit (male), 0 for even (female). `valid` checks ten
digits and a real encoded calendar date, not whether the number was
assigned to a person. Missing and malformed CPRs give `valid = FALSE`
and missing birth date, age, and sex. `mod11` is a separate logical
checksum, not a requirement for `valid`. Malformed formats give a
missing checksum.

CPR values are cleaned internally with
[`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md).
To also standardise the source column, use
`dplyr::mutate(pnr = clean_cpr(pnr))` explicitly. Rows, row order, and
input columns are preserved unless `.overwrite = TRUE`. Duplicate output
names are always an error.

CPR parsing, calendar validation, and requested outputs share a single
native pass. Multiple age selections reuse the decoded birth date.
Pre-cleaning is optional: use
[`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md)
when the source column itself must be standardised for joins or export.

For a single piece of information inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
or
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html),
the vector functions
[`cpr_birth_date()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md),
[`cpr_age()`](https://dataniel.github.io/pnrr/reference/cpr_age.md) and
friends give the same values. Prefer `add_cpr_info()` when you need
several: it parses each CPR once.

The arguments have a dot prefix, as in dplyr, so that an output name
never reaches them: R matches named arguments by partial name before
`...`, and `d = bday` or `cpr = age(year)` would otherwise be taken as
`data` or `cpr_col`.

For 29 February births, age advances on 1 March in non-leap years. A
reference before birth gives a negative age. Use an explicit reference
for reproducible analysis; today's date changes between runs.

This selection API replaces `add`, `ref_date`, `year`, and `at`
arguments: use `age(year, "primo")` or `age(date = reference_date)`
instead. Unlike the previous API, the source CPR column is preserved.

## See also

[`age()`](https://dataniel.github.io/pnrr/reference/age.md),
[`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md),
[`cpr_birth_date()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)

## Examples

``` r
df <- data.frame(pnr = c("0101004007", "111111-1118"), year = 2024:2025)
add_cpr_info(df, pnr)
#>           pnr year       bday age sex mod11 valid
#> 1  0101004007 2024 2000-01-01  26   1  TRUE  TRUE
#> 2 111111-1118 2025 1911-11-11 114   0  TRUE  TRUE
add_cpr_info(df, pnr, sex, birth_date = bday)
#>           pnr year sex birth_date
#> 1  0101004007 2024   1 2000-01-01
#> 2 111111-1118 2025   0 1911-11-11
add_cpr_info(df, pnr,
  primoalder = age(year), ultimoalder = age(year, "ultimo"), sex)
#>           pnr year primoalder ultimoalder sex
#> 1  0101004007 2024         23          24   1
#> 2 111111-1118 2025        113         114   0
add_cpr_info(df, pnr, alder = age(date = "2025-07-01"))
#>           pnr year alder
#> 1  0101004007 2024    25
#> 2 111111-1118 2025   113
```
