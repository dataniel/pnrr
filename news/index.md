# Changelog

## pnr 0.1.0

- First version.
  [`clean_cpr()`](https://dataniel.github.io/pnr/reference/clean_cpr.md),
  [`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md)
  and [`age()`](https://dataniel.github.io/pnr/reference/age.md) moved
  here unchanged from daos, with their native C kernel, tests and
  benchmarks. daos no longer has them and does not forward to pnr.

- [`diagnose_cpr()`](https://dataniel.github.io/pnr/reference/diagnose_cpr.md)
  reports what is wrong with a CPR column: missing values, scientific
  notation, wrong lengths, other characters and invalid dates, with
  notes on restored leading zeros, separators, modulus 11, repeated
  values and implausible birth dates. It prints counts and row numbers,
  never CPR numbers.

- [`cpr_birth_date()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md),
  [`cpr_birth_year()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md),
  [`cpr_sex()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md),
  [`cpr_valid()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md),
  [`cpr_mod11()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md)
  and [`cpr_age()`](https://dataniel.github.io/pnr/reference/cpr_age.md)
  give one piece of information as a vector, for `mutate()` and
  [`filter()`](https://rdrr.io/r/stats/filter.html). They return exactly
  what the matching
  [`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md)
  selection does, from the same native code.

- [`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md)
  gains the `byear` selection, the birth year as an integer. It is not
  among the defaults, so default output is unchanged, and the native
  pass is as fast as before.

- [`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md)’s
  arguments are now `.data`, `.cpr_col` and `.overwrite`. An output name
  such as `d = bday` or `cpr = age(year)` was partially matched to
  `data` or `cpr_col` and gave a misleading error. The old names give an
  error that points to the new ones.

- [`diagnose_cpr()`](https://dataniel.github.io/pnr/reference/diagnose_cpr.md)
  classifies in one native pass: about four times faster, one second for
  five million values.

- [`pseudo_cpr()`](https://dataniel.github.io/pnr/reference/pseudo_cpr.md)
  replaces CPR numbers with serial numbers in random order. The same CPR
  number gets the same serial number within a call; no key is kept.
