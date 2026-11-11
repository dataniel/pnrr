# Changelog

## pnrr 0.1.0

- First version.
  [`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md),
  [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
  and `age()` moved here from daos, with their native C kernel, tests
  and benchmarks. daos no longer has them and does not forward to pnrr.

- `age()` is now `age_at(ref, at)`. The reference is one argument, and
  its type decides what it is: whole numbers are years, a Date or an ISO
  date string is a date. `age(date = x)` is `age_at(x)`. The `primo`
  argument is gone: `age(year, primo = "jan1")` is
  `age_at(year, "jan1")`, and `"primo"` is always 31 December of the
  year before, as it was by default. `cpr_age(x, ref, at)` has the same
  form. `age(...)` in
  [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
  gives an error that shows the new form; bare `age` still means today’s
  age. The name says what the argument is: `age()` looked like it
  calculated an age.

- [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
  gains the `status` selection, and
  [`cpr_status()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)
  is its vector version: a factor that says for each row why a value is
  or is not valid, with the problems of
  [`diagnose_cpr()`](https://dataniel.github.io/pnrr/reference/diagnose_cpr.md)
  as levels. The two share one classification and cannot disagree.

- [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
  gains the `koen` selection, and
  [`cpr_koen()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)
  is its vector version: sex coded 1 for men and 2 for women, as `KOEN`
  in the registers of Statistics Denmark. `sex` is still 1 and 0.

- [`diagnose_cpr()`](https://dataniel.github.io/pnrr/reference/diagnose_cpr.md)
  reports what is wrong with a CPR column: missing values, scientific
  notation, wrong lengths, other characters and invalid dates, with
  notes on restored leading zeros, separators, modulus 11, repeated
  values and implausible birth dates. It prints counts and row numbers,
  never CPR numbers.

- [`cpr_birth_date()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md),
  [`cpr_birth_year()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md),
  [`cpr_sex()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md),
  [`cpr_valid()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md),
  [`cpr_mod11()`](https://dataniel.github.io/pnrr/reference/cpr_birth_date.md)
  and
  [`cpr_age()`](https://dataniel.github.io/pnrr/reference/cpr_age.md)
  give one piece of information as a vector, for `mutate()` and
  [`filter()`](https://rdrr.io/r/stats/filter.html). They return exactly
  what the matching
  [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
  selection does, from the same native code.

- [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
  gains the `byear` selection, the birth year as an integer. It is not
  among the defaults, so default output is unchanged, and the native
  pass is as fast as before.

- [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)’s
  arguments are now `.data`, `.cpr_col` and `.overwrite`. An output name
  such as `d = bday` or `cpr = age_at(year)` was partially matched to
  `data` or `cpr_col` and gave a misleading error. The old names give an
  error that points to the new ones.

- [`diagnose_cpr()`](https://dataniel.github.io/pnrr/reference/diagnose_cpr.md)
  classifies in one native pass: about four times faster, one second for
  five million values.

- [`pseudo_cpr()`](https://dataniel.github.io/pnrr/reference/pseudo_cpr.md)
  replaces CPR numbers with serial numbers in random order. The same CPR
  number gets the same serial number within a call; no key is kept. The
  documentation now says that a `seed` is a secret: with it, the serial
  numbers can be traced back to the order of the source.

- Cleaning also removes the separators that cannot be seen: tabs, line
  breaks, no-break spaces and typographic dashes, such as the en dash
  Word makes of a hyphen. They were reported as `non_digit` and made a
  valid number invalid. This applies everywhere CPR numbers are read.

- [`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md)
  gives an error for a data frame or a list, as the other vector
  functions do, instead of returning a deparsed string.

- [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
  and the `cpr_*()` functions read CPR numbers stored as numbers
  directly, without converting each to text first: about 25 times faster
  on a numeric column, 0.3 seconds for ten million values. A year
  reference is validated in the native code: `age_at(year)` on a column
  is about a third faster, and three ages in one call more than twice as
  fast.

- Whole numbers that R writes in scientific notation, such as
  `1010000000` (`"1.01e+09"`), keep their digits everywhere. They were
  read as malformed, and
  [`diagnose_cpr()`](https://dataniel.github.io/pnrr/reference/diagnose_cpr.md)
  reported them as lost digits.

- [`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
  returns a data.table that can be modified with `:=` without the
  shallow-copy warning.
