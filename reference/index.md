# Package index

## Diagnose and standardise

- [`diagnose_cpr()`](https://dataniel.github.io/pnrr/reference/diagnose_cpr.md)
  : Diagnose a column of CPR numbers
- [`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md)
  : Standardise CPR numbers

## Derive

[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
adds several columns in one pass; the `cpr_*()` functions give one
vector each, for `mutate()` and
[`filter()`](https://rdrr.io/r/stats/filter.html).

- [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
  : Add information derived from Danish CPR numbers
- [`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md) :
  The reference for an age from CPR numbers
- [`cpr_birth_date()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)
  [`cpr_birth_year()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)
  [`cpr_sex()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)
  [`cpr_valid()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)
  [`cpr_koen()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)
  [`cpr_status()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)
  [`cpr_mod11()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)
  : Derive one piece of information from CPR numbers
- [`cpr_age()`](https://dataniel.github.io/pnrr/reference/cpr_age.md) :
  Age from CPR numbers

## Pseudonymise

- [`pseudo_cpr()`](https://dataniel.github.io/pnrr/reference/pseudo_cpr.md)
  : Replace CPR numbers with random serial numbers

## Package

- [`pnrr`](https://dataniel.github.io/pnrr/reference/pnrr-package.md)
  [`pnrr-package`](https://dataniel.github.io/pnrr/reference/pnrr-package.md)
  : pnrr: Danish CPR numbers in register data
