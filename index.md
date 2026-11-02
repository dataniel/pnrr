[![R-CMD-check](https://github.com/dataniel/pnr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dataniel/pnr/actions/workflows/R-CMD-check.yaml)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Danish CPR numbers (personnumre) in register data: diagnose the column,
standardise it, derive birth date, age and sex, and replace it with a
serial number before the data leaves a secure environment.

[`clean_cpr()`](https://dataniel.github.io/pnr/reference/clean_cpr.md),
[`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md)
and [`age()`](https://dataniel.github.io/pnr/reference/age.md) moved
here unchanged from [daos](https://github.com/dataniel/daos). pnr
depends only on cli and rlang; the CPR parsing is native C.

## Installation

``` r
pak::pak("dataniel/pnr")
```

## What it looks like

``` r
library(pnr)

diagnose_cpr(persons$pnr, as_of = "2025-12-31")

persons |>
  dplyr::mutate(pnr = clean_cpr(pnr)) |>        # restores Excel-lost leading zeros
  add_cpr_info(pnr, alder = age(year), sex) |>  # one native pass
  dplyr::mutate(id = pseudo_cpr(pnr), pnr = NULL)
```

## Functions

| Function | Description |
|----|----|
| [`diagnose_cpr()`](https://dataniel.github.io/pnr/reference/diagnose_cpr.md) | What is wrong with a CPR column: missing, malformed, scientific notation, invalid dates, Excel damage. Counts and row numbers, never CPR numbers |
| [`clean_cpr()`](https://dataniel.github.io/pnr/reference/clean_cpr.md) | Standardise CPR numbers: strip separators, restore Excel-lost leading zeros |
| [`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md) | Add birth date, age, sex, modulus 11 and validity derived from CPR numbers |
| [`age()`](https://dataniel.github.io/pnr/reference/age.md) | Choose the reference year or date for an age column in [`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md) |
| [`cpr_birth_date()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md), [`cpr_birth_year()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md), [`cpr_sex()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md), [`cpr_valid()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md), [`cpr_mod11()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md) | One piece of information as a vector, for `mutate()` and [`filter()`](https://rdrr.io/r/stats/filter.html) |
| [`cpr_age()`](https://dataniel.github.io/pnr/reference/cpr_age.md) | Age as a vector, with the same references as [`age()`](https://dataniel.github.io/pnr/reference/age.md) |
| [`pseudo_cpr()`](https://dataniel.github.io/pnr/reference/pseudo_cpr.md) | Replace CPR numbers with serial numbers in random order; no key is kept |
