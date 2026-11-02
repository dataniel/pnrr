# Package index

## Diagnose and standardise

- [`diagnose_cpr()`](https://dataniel.github.io/pnr/reference/diagnose_cpr.md)
  : Diagnose a column of CPR numbers
- [`clean_cpr()`](https://dataniel.github.io/pnr/reference/clean_cpr.md)
  : Standardise CPR numbers

## Derive

[`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md)
adds several columns in one pass; the `cpr_*()` functions give one
vector each, for `mutate()` and
[`filter()`](https://rdrr.io/r/stats/filter.html).

- [`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md)
  : Add information derived from Danish CPR numbers
- [`age()`](https://dataniel.github.io/pnr/reference/age.md) : Specify
  an age calculation for CPR information
- [`cpr_birth_date()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md)
  [`cpr_birth_year()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md)
  [`cpr_sex()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md)
  [`cpr_valid()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md)
  [`cpr_mod11()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md)
  : Derive one piece of information from CPR numbers
- [`cpr_age()`](https://dataniel.github.io/pnr/reference/cpr_age.md) :
  Age from CPR numbers

## Pseudonymise

- [`pseudo_cpr()`](https://dataniel.github.io/pnr/reference/pseudo_cpr.md)
  : Replace CPR numbers with random serial numbers

## Package

- [`pnr`](https://dataniel.github.io/pnr/reference/pnr-package.md)
  [`pnr-package`](https://dataniel.github.io/pnr/reference/pnr-package.md)
  : pnr: Danish CPR numbers in register data
