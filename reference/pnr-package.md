# pnr: Danish CPR numbers in register data

The CPR number (personnummer) is the key of almost every Danish
register, and it arrives in every shape: with and without a dash, with
the leading zero lost in Excel, as a number in scientific notation. pnr
holds the functions that work on it. See
[`vignette("pnr")`](https://dataniel.github.io/pnr/articles/pnr.md).

## Details

### Where to start

- [`diagnose_cpr()`](https://dataniel.github.io/pnr/reference/diagnose_cpr.md):
  what is wrong with a CPR column, in counts and row numbers, never in
  CPR numbers.

- [`clean_cpr()`](https://dataniel.github.io/pnr/reference/clean_cpr.md):
  the canonical ten-digit form, for joins and export.

- [`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md)
  with [`age()`](https://dataniel.github.io/pnr/reference/age.md): birth
  date, age, sex, modulus 11 and validity, in one native pass.

- [`cpr_birth_date()`](https://dataniel.github.io/pnr/reference/cpr_birth_date.md),
  [`cpr_age()`](https://dataniel.github.io/pnr/reference/cpr_age.md) and
  friends: the same information one vector at a time, for `mutate()` and
  [`filter()`](https://rdrr.io/r/stats/filter.html).

- [`pseudo_cpr()`](https://dataniel.github.io/pnr/reference/pseudo_cpr.md):
  random serial numbers in place of the CPR number.

### Why a package of its own

[`clean_cpr()`](https://dataniel.github.io/pnr/reference/clean_cpr.md),
[`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md)
and [`age()`](https://dataniel.github.io/pnr/reference/age.md) started
in the daos package. They moved here, unchanged, when the CPR work grew
beyond deriving columns: diagnosing a column and replacing the
identifier belong with them and not with the general utilities in daos.
pnr depends only on cli and rlang, and daos does not depend on it, or it
on daos.

## See also

Useful links:

- <https://dataniel.github.io/pnr>

- <https://github.com/dataniel/pnr>

- Report bugs at <https://github.com/dataniel/pnr/issues>

## Author

**Maintainer**: Daniel Madsen <danielmadsen@live.dk>

Authors:

- Daniel Madsen <danielmadsen@live.dk>
