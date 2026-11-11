# Age from CPR numbers

The vector version of the `age` selection in
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md):
CPR numbers in, ages in completed calendar years out. It takes the same
reference as
[`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md), but
as a value rather than a column name, so it fits inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Usage

``` r
cpr_age(x, ref, at = "primo")
```

## Arguments

- x:

  A vector of CPR numbers, cleaned as in
  [`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md).

- ref:

  The reference: whole numbers are years, a Date vector or ISO date
  strings (`"YYYY-MM-DD"`) are dates. One for all, or one per CPR
  number. Inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  this can be a column, e.g. `cpr_age(pnr, year)`. Left out, the age is
  today's.

- at:

  The day in the year, when `ref` is a year: `"primo"` (default, 31
  December of the year before), `"jan1"`, `"medio"` (1 July) or
  `"ultimo"` (31 December). As in
  [`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md).

## Value

An integer vector of the same length as `x`.

## Details

Use an explicit reference for reproducible analysis; today's date
changes between runs. `cpr_age(x, 2025)` is the age on 31 December 2024:
primo is the closing of the year before, so opening ages equal the
previous year's closing ages. See
[`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md) for
the reasoning and
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
for leap-day birthdays.

Ages are `NA` for CPR numbers that are not valid (see
[`cpr_valid()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md))
and for missing references.

## See also

[`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md),
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md),
[`cpr_birth_date()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)

## Examples

``` r
x <- c("0101004007", "111111-1118", "3102004007")
cpr_age(x, 2025)
#> [1]  24 113  NA
cpr_age(x, 2025, "ultimo")
#> [1]  25 114  NA
cpr_age(x, "2025-07-01")
#> [1]  25 113  NA
cpr_age(x, c(2024, 2025, 2025))
#> [1]  23 113  NA

# df |> dplyr::mutate(alder = cpr_age(pnr, year))
```
