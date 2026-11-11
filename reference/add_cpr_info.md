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

  Information to add: `bday`, `byear`, `sex`, `koen`, `valid`, `status`,
  `mod11`, `age`, or
  [`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md) with
  a reference year or date. Name a selection to choose its output
  column, e.g. `birth_date = bday`. With no selections, adds `bday`,
  `age`, `sex`, `mod11`, and `valid`. Bare `age` uses today's date.

- .overwrite:

  Allow replacing existing output columns? Default `FALSE`. The CPR
  source column cannot be replaced.

## Value

The input data frame with selected columns added in selection order.

## Details

|  |  |
|----|----|
| Selection | Value |
| `bday` | Birth date, a Date |
| `byear` | Birth year, an integer |
| `age`, [`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md) | Completed calendar years, an integer |
| `sex` | Integer, 1 male (odd final digit), 0 female |
| `koen` | Integer, 1 male, 2 female: the coding of `KOEN` in the registers of Statistics Denmark |
| `valid` | Logical: ten digits and a real encoded date |
| `status` | Factor: why a value is or is not valid |
| `mod11` | Logical: the modulus-11 checksum |

`valid` checks ten digits and a real encoded calendar date, not whether
the number was assigned to a person. Missing and malformed CPRs give
`valid = FALSE` and missing birth date, age, and sex. `mod11` is a
separate logical checksum, not a requirement for `valid`. Malformed
formats give a missing checksum.

`status` says what `valid` cannot: its levels are `valid`, `missing`,
`scientific`, `wrong_length`, `non_digit` and `invalid_date`, the
problems of
[`diagnose_cpr()`](https://dataniel.github.io/pnrr/reference/diagnose_cpr.md),
where they are explained.
[`diagnose_cpr()`](https://dataniel.github.io/pnrr/reference/diagnose_cpr.md)
answers for a column, `status` for each row, so the rows can be filtered
or counted by group.

`sex` and `koen` hold the same information in two codings. `sex` is 0/1,
which sums and averages directly; `koen` is 1/2 and compares directly
with the `KOEN` variable of the registers
(<https://www.dst.dk/da/TilSalg/data-til-forskning/generelt-om-data/dokumentation-af-data/hoejkvalitetsvariable/Folketal/KOEN>).

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
`...`, and `d = bday` or `cpr = age_at(year)` would otherwise be taken
as `data` or `cpr_col`.

For 29 February births, age advances on 1 March in non-leap years. A
reference before birth gives a negative age. Use an explicit reference
for reproducible analysis; today's date changes between runs.

In daos, `add_cpr_info()` took `add`, `ref_date`, `year` and `at`
arguments, and later the helper `age()`. Selections and
[`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md)
replace them; each old form gives an error that points to the new one.

## See also

[`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md),
[`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md),
[`cpr_birth_date()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)

## Examples

``` r
df <- data.frame(pnr = c("0101004007", "111111-1118"), year = 2024:2025)
add_cpr_info(df, pnr)
#>           pnr year       bday age sex mod11 valid
#> 1  0101004007 2024 2000-01-01  26   1  TRUE  TRUE
#> 2 111111-1118 2025 1911-11-11 115   0  TRUE  TRUE
add_cpr_info(df, pnr, sex, birth_date = bday)
#>           pnr year sex birth_date
#> 1  0101004007 2024   1 2000-01-01
#> 2 111111-1118 2025   0 1911-11-11
add_cpr_info(df, pnr,
  primoalder = age_at(year), ultimoalder = age_at(year, "ultimo"), sex)
#>           pnr year primoalder ultimoalder sex
#> 1  0101004007 2024         23          24   1
#> 2 111111-1118 2025        113         114   0
add_cpr_info(df, pnr, alder = age_at("2025-07-01"))
#>           pnr year alder
#> 1  0101004007 2024    25
#> 2 111111-1118 2025   113

# Why a value is not valid, and sex as in the registers
bad <- data.frame(pnr = c("0101004007", "3102004007", "1.01004E+08", NA))
add_cpr_info(bad, pnr, status, koen)
#>           pnr       status koen
#> 1  0101004007        valid    1
#> 2  3102004007 invalid_date   NA
#> 3 1.01004E+08   scientific   NA
#> 4        <NA>      missing   NA
```
