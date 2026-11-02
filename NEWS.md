# pnrr 0.1.0

* First version. `clean_cpr()`, `add_cpr_info()` and `age()` moved here
  unchanged from daos, with their native C kernel, tests and benchmarks.
  daos no longer has them and does not forward to pnrr.

* `diagnose_cpr()` reports what is wrong with a CPR column: missing values,
  scientific notation, wrong lengths, other characters and invalid dates,
  with notes on restored leading zeros, separators, modulus 11, repeated
  values and implausible birth dates. It prints counts and row numbers,
  never CPR numbers.

* `cpr_birth_date()`, `cpr_birth_year()`, `cpr_sex()`, `cpr_valid()`,
  `cpr_mod11()` and `cpr_age()` give one piece of information as a vector,
  for `mutate()` and `filter()`. They return exactly what the matching
  `add_cpr_info()` selection does, from the same native code.

* `add_cpr_info()` gains the `byear` selection, the birth year as an
  integer. It is not among the defaults, so default output is unchanged,
  and the native pass is as fast as before.

* `add_cpr_info()`'s arguments are now `.data`, `.cpr_col` and
  `.overwrite`. An output name such as `d = bday` or `cpr = age(year)` was
  partially matched to `data` or `cpr_col` and gave a misleading error.
  The old names give an error that points to the new ones.

* `diagnose_cpr()` classifies in one native pass: about four times faster,
  one second for five million values.

* `pseudo_cpr()` replaces CPR numbers with serial numbers in random order.
  The same CPR number gets the same serial number within a call; no key is
  kept.
