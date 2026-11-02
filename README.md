# pnrr

[![R-CMD-check](https://github.com/dataniel/pnrr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dataniel/pnrr/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Danish CPR numbers (personnumre) in register data: diagnose the column,
standardise it, derive birth date, age and sex, and replace it with a
serial number before the data leaves a secure environment.

`clean_cpr()`, `add_cpr_info()` and `age()` moved here unchanged from
[daos](https://github.com/dataniel/daos). pnrr depends only on cli and
rlang; the CPR parsing is native C.

## Installation

```r
pak::pak("dataniel/pnrr")
```

## What it looks like

```r
library(pnrr)

diagnose_cpr(persons$pnr, as_of = "2025-12-31")

persons |>
  dplyr::mutate(pnr = clean_cpr(pnr)) |>        # restores Excel-lost leading zeros
  add_cpr_info(pnr, alder = age(year), sex) |>  # one native pass
  dplyr::mutate(id = pseudo_cpr(pnr), pnr = NULL)
```

## Functions

| Function | Description |
|----------|-------------|
| `diagnose_cpr()` | What is wrong with a CPR column: missing, malformed, scientific notation, invalid dates, Excel damage. Counts and row numbers, never CPR numbers |
| `clean_cpr()` | Standardise CPR numbers: strip separators, restore Excel-lost leading zeros |
| `add_cpr_info()` | Add birth date, age, sex, modulus 11 and validity derived from CPR numbers |
| `age()` | Choose the reference year or date for an age column in `add_cpr_info()` |
| `cpr_birth_date()`, `cpr_birth_year()`, `cpr_sex()`, `cpr_valid()`, `cpr_mod11()` | One piece of information as a vector, for `mutate()` and `filter()` |
| `cpr_age()` | Age as a vector, with the same references as `age()` |
| `pseudo_cpr()` | Replace CPR numbers with serial numbers in random order; no key is kept |
