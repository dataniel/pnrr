# Age from CPR numbers

The vector version of the `age` selection in
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md):
CPR numbers in, ages in completed calendar years out. It takes the same
references as
[`age()`](https://dataniel.github.io/pnrr/reference/age.md), but as
values rather than column names, so it fits inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Usage

``` r
cpr_age(x, year, at = "primo", date, primo = "previous_ultimo")
```

## Arguments

- x:

  A vector of CPR numbers, cleaned as in
  [`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md).

- year:

  Numeric whole year(s): one for all, or one per CPR number. Inside
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
  this can be a column, e.g. `cpr_age(pnr, year)`.

- at, date, primo:

  As in [`age()`](https://dataniel.github.io/pnrr/reference/age.md):
  `at` is `"primo"`, `"medio"` or `"ultimo"`; `date` is a Date vector or
  ISO date strings instead of `year`; `primo` is the convention for
  `at = "primo"`.

## Value

An integer vector of the same length as `x`.

## Details

With neither `year` nor `date`, age is today's. Use an explicit
reference for reproducible analysis. The default `age(year)` convention
applies: primo is 31 December of the previous year, so opening ages
equal the previous year's closing ages. See
[`age()`](https://dataniel.github.io/pnrr/reference/age.md) for the
conventions and
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
for leap-day birthdays.

Ages are `NA` for CPR numbers that are not valid (see
[`cpr_valid()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md))
and for missing references.

## See also

[`age()`](https://dataniel.github.io/pnrr/reference/age.md),
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md),
[`cpr_birth_date()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)

## Examples

``` r
x <- c("0101004007", "111111-1118", "3102004007")
cpr_age(x, 2025)
#> [1]  24 113  NA
cpr_age(x, 2025, "ultimo")
#> [1]  25 114  NA
cpr_age(x, date = "2025-07-01")
#> [1]  25 113  NA
cpr_age(x, year = c(2024, 2025, 2025))
#> [1]  23 113  NA

# df |> dplyr::mutate(alder = cpr_age(pnr, year))
```
