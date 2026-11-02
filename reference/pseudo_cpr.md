# Replace CPR numbers with random serial numbers

Gives every distinct CPR number a serial number, `1` to the number of
distinct values, in random order. The same CPR number gets the same
serial number throughout the vector, so persons can still be followed
across rows, but the number itself carries nothing about the person.

## Usage

``` r
pseudo_cpr(x, seed = NULL)
```

## Arguments

- x:

  A vector of CPR numbers. Values are matched after the same cleaning as
  [`clean_cpr()`](https://dataniel.github.io/pnr/reference/clean_cpr.md),
  so `"010100-4007"` and `"101004007"` get the same serial number as
  `"0101004007"`.

- seed:

  Optional single whole number. With a seed, the same input gives the
  same serial numbers on every run; the global random number stream is
  left as it was. Without one, every call draws anew.

## Value

An integer vector of the same length as `x`.

## Details

**Why random order.** Numbering in sorted order would make the serial
number follow the birth date, the first six digits of the CPR number.
Numbering in order of appearance would tie it to the row order of the
source file. A random order avoids both.

**No key is kept.** The mapping exists only for the duration of the call
and is not returned. Two calls therefore give unrelated serial numbers,
also on overlapping data. To link several tables, pseudonymise them in
one call, for example on the bound key columns, or join first and
pseudonymise the result. A fixed `seed` reproduces the numbering only
for exactly the same input; it is not a key that links different data
sets.

**Pseudonymous, not anonymous.** Replacing the identifier does not make
the data anonymous in the sense of the GDPR. Birth date, sex,
municipality and other columns can still single out a person. Derive
what you need with
[`add_cpr_info()`](https://dataniel.github.io/pnr/reference/add_cpr_info.md)
before the CPR column is replaced, and remove the original column
afterwards.

Missing values, and values that are empty after cleaning, stay `NA`.
Malformed values that are not empty get a serial number like any other
value; check them first with
[`diagnose_cpr()`](https://dataniel.github.io/pnr/reference/diagnose_cpr.md).

## See also

[`diagnose_cpr()`](https://dataniel.github.io/pnr/reference/diagnose_cpr.md),
[`clean_cpr()`](https://dataniel.github.io/pnr/reference/clean_cpr.md)

## Examples

``` r
x <- c("0101004007", "1111111118", "010100-4007", NA, "101004007")
pseudo_cpr(x)
#> [1]  1  2  1 NA  1
pseudo_cpr(x, seed = 1)
#> [1]  1  2  1 NA  1

# Typical use: derive what is needed, then replace the identifier
# df |>
#   add_cpr_info(pnr, bday, sex) |>
#   dplyr::mutate(id = pseudo_cpr(pnr), pnr = NULL)
```
