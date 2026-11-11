# Getting started with pnrr

A CPR column usually goes through four steps: find out what is wrong
with it, standardise it, derive what the analysis needs, and replace it
before the data leaves a secure environment. pnrr has one function for
each.

All CPR numbers in this vignette are constructed examples.

## `diagnose_cpr()`: what is wrong with the column

Ask this first of a CPR column you did not produce yourself:

``` r
x <- c("0101004007", "010100-4007", "101004007", "1.01004E+08",
       "3102004007", "12345", "ukendt", NA, "1111111118")
diagnose_cpr(x, as_of = "2025-01-01")
#> ── CPR diagnosis ───────────────────────────────────────────────────────────────
#> ! 4 of 9 valid (2 distinct)
#> ✖ 1 missing (row 8)
#> ✖ 1 in scientific or decimal notation: digits are lost, read the source again as text (row 4)
#> ✖ 1 with the wrong number of digits (row 6)
#> ✖ 1 with characters other than digits and separators (row 7)
#> ✖ 1 with ten digits but no real birth date (row 5)
#> ℹ 1 had lost a leading zero (Excel), restored by cleaning (row 3)
#> ℹ 1 contained dashes, spaces or invisible separators (row 2)
#> ℹ 3 valid, sharing their CPR number with another row (rows 1, 2, 3)
#> Birth dates 1911-11-11 to 2000-01-01; 75.0% male.
```

Every value gets one status: valid, missing, scientific notation, wrong
length, other characters, or an invalid date. The notes below the
problems overlap and are not errors, but each tells where the data has
been: a restored leading zero means Excel, scientific notation means the
digits are gone and the source must be read again with the column as
text.

The report shows counts and row numbers, never CPR numbers, so it can go
into a log. The rows behind each check are kept in the result:

``` r
d <- diagnose_cpr(x, as_of = "2025-01-01")
d$checks[, c("check", "kind", "n")]
#>               check    kind n
#> 1             valid problem 4
#> 2           missing problem 1
#> 3        scientific problem 1
#> 4      wrong_length problem 1
#> 5         non_digit problem 1
#> 6      invalid_date problem 1
#> 7     zero_restored    note 1
#> 8        separators    note 1
#> 9       mod11_fails    note 0
#> 10         repeated    note 3
#> 11 born_after_as_of    note 0
#> 12   older_than_120    note 0
d$checks$rows[d$checks$check == "invalid_date"][[1]]
#> [1] 5
```

A modulus-11 failure is only a note: since 2007 the CPR office issues
numbers that do not satisfy it.

## `clean_cpr()`: one form for joins

Identifiers rarely arrive in one consistent shape: `111111-1118`, or a
nine-digit CPR that lost its leading zero in Excel. Before a join, both
sides need the same form, and that is all
[`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md)
does. It takes a vector and returns a vector, so the natural place for
it is inside a `mutate()`:

``` r
clean_cpr(c("111111-1118", "101004007", "1111111118"))
#> [1] "1111111118" "0101004007" "1111111118"
```

Besides dashes and spaces it removes the separators that cannot be seen:
tabs, line breaks, no-break spaces, and the en dash Word makes of a
hyphen.

It zero-pads nine-digit values, because birth days 01 to 09 mean that a
third of all CPR numbers start with a zero, which Excel drops. It does
not validate: malformed values come back cleaned but still visibly
malformed.

## `add_cpr_info()`: birth date, age, sex, and validity

[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
appends selected information while preserving the original CPR column.
Dashes, spaces, and lost leading zeroes are handled internally, with the
same native rules as
[`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md).
Each CPR is parsed once for all requested outputs, including multiple
age calculations. Use
[`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md)
explicitly when the identifier will also be used for joins or export:

``` r
df |>
  dplyr::mutate(pnr = clean_cpr(pnr)) |>
  add_cpr_info(pnr, age_at(year), sex, bday)
```

Without selections, the function adds `bday`, `age`, `sex`, `mod11`, and
`valid`. Bare `age` and
[`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md) use
today’s date; explicit references make analysis reproducible.

``` r
df <- data.frame(
  pnr = c("1111111118", "111111-1118", "111111118"),
  year = c(2024L, 2025L, 2026L)
)
add_cpr_info(df, pnr)
#>           pnr year       bday age sex mod11 valid
#> 1  1111111118 2024 1911-11-11 115   0  TRUE  TRUE
#> 2 111111-1118 2025 1911-11-11 115   0  TRUE  TRUE
#> 3   111111118 2026 1911-11-01 115   0 FALSE  TRUE
add_cpr_info(df, pnr, sex, birth_date = bday)
#>           pnr year sex birth_date
#> 1  1111111118 2024   0 1911-11-11
#> 2 111111-1118 2025   0 1911-11-11
#> 3   111111118 2026   0 1911-11-01
```

Write `output_name = calculation` to rename a result. Each age
calculation has its own reference, so several ages can be added in one
call:

``` r
df |>
  add_cpr_info(
    pnr,
    primoalder = age_at(year),
    medioalder = age_at(year, "medio"),
    ultimoalder = age_at(year, "ultimo"),
    sex,
    bday
  )
#>           pnr year primoalder medioalder ultimoalder sex       bday
#> 1  1111111118 2024        112        112         113   0 1911-11-11
#> 2 111111-1118 2025        113        113         114   0 1911-11-11
#> 3   111111118 2026        114        114         115   0 1911-11-01
```

[`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md) takes
one reference, and its type decides what it is. Whole numbers are years,
and the second argument chooses the day in the year:

| `at`                | Day                            |
|---------------------|--------------------------------|
| `"primo"` (default) | 31 December of the year before |
| `"jan1"`            | 1 January                      |
| `"medio"`           | 1 July                         |
| `"ultimo"`          | 31 December                    |

The reference can be one value, a column, or an expression on the
columns of the input data.

Primo is the day before the year begins, so `age_at(2025)` is the age on
31 December 2024. That makes opening ages equal to the previous year’s
closing ages, as in population statistics. Someone born on 1 January
2000 is then 0 in counting year 2001; `age_at(year, "jan1")` instead
includes that day’s birthday and gives 1.

A Date or an ISO date string is a date, and takes no `at`. Supply one
reference for all rows or one per row. Missing references give missing
ages. Use `.env$name` to explicitly access a caller variable when a
column has the same name.

``` r
add_cpr_info(df, pnr, alder = age_at("2025-07-01"))
#>           pnr year alder
#> 1  1111111118 2024   113
#> 2 111111-1118 2025   113
#> 3   111111118 2026   113
df$reference <- as.Date(paste0(df$year, "-01-01"))
add_cpr_info(df, pnr, alder = age_at(reference))
#>           pnr year  reference alder
#> 1  1111111118 2024 2024-01-01   112
#> 2 111111-1118 2025 2025-01-01   113
#> 3   111111118 2026 2026-01-01   114
```

Existing output names cause an error with guidance to rename the
selection or use `.overwrite = TRUE`. Duplicate output names are always
an error, and the source CPR column cannot be overwritten.

`valid` means ten digits encoding a real calendar date, not confirmation
that the CPR number was assigned. Missing and invalid CPR values give
`valid = FALSE`. `mod11` is an independent checksum and is not part of
`valid`. Choose `mod11` explicitly when selecting outputs if you need
it.

`status` says why a value is not valid, with the problems of
[`diagnose_cpr()`](https://dataniel.github.io/pnrr/reference/diagnose_cpr.md)
as levels. Where the diagnosis answers for the column, `status` answers
for each row, so the rows can be filtered or counted:

``` r
mixed <- data.frame(pnr = c("0101004007", "3102004007", "1.01004E+08", "12345", NA))
add_cpr_info(mixed, pnr, valid, status)
#>           pnr valid       status
#> 1  0101004007  TRUE        valid
#> 2  3102004007 FALSE invalid_date
#> 3 1.01004E+08 FALSE   scientific
#> 4       12345 FALSE wrong_length
#> 5        <NA> FALSE      missing
table(cpr_status(mixed$pnr))
#> 
#>        valid      missing   scientific wrong_length    non_digit invalid_date 
#>            1            1            1            1            0            1
```

`sex` is 1 for men and 0 for women, which sums and averages directly.
`koen` is the same information coded 1 for men and 2 for women, as the
variable `KOEN` in the registers of Statistics Denmark, so the two can
be compared without recoding:

``` r
add_cpr_info(df, pnr, sex, koen)
#>           pnr year  reference sex koen
#> 1  1111111118 2024 2024-01-01   0    2
#> 2 111111-1118 2025 2025-01-01   0    2
#> 3   111111118 2026 2026-01-01   0    2
```

Age counts completed calendar years, not elapsed days divided by 365.25.
For a person born on 29 February, age increases on 29 February in leap
years and on 1 March in non-leap years. For a birth date of 29 February
2000:

| Reference date | Age |
|----------------|----:|
| 2024-02-28     |  23 |
| 2024-02-29     |  24 |
| 2024-03-01     |  24 |
| 2025-02-28     |  24 |
| 2025-03-01     |  25 |

`age_at(2024)` means age on 31 December 2023 by default, giving age 23
in this example.

Add `byear` for the birth year as an integer. Like `koen` and `status`,
it is not among the defaults.

## `cpr_birth_date()`, `cpr_age()` and friends: one vector at a time

Where a data frame function does not fit, in a
[`filter()`](https://rdrr.io/r/stats/filter.html) or inside an
[`ifelse()`](https://rdrr.io/r/base/ifelse.html), each selection has a
vector version:

``` r
x <- c("0101004007", "111111-1118", "3102004007")
cpr_birth_date(x)
#> [1] "2000-01-01" "1911-11-11" NA
cpr_birth_year(x)
#> [1] 2000 1911   NA
cpr_sex(x)
#> [1]  1  0 NA
cpr_koen(x)
#> [1]  1  2 NA
cpr_valid(x)
#> [1]  TRUE  TRUE FALSE
cpr_status(x)
#> [1] valid        valid        invalid_date
#> Levels: valid missing scientific wrong_length non_digit invalid_date
cpr_age(x, 2025)
#> [1]  24 113  NA
cpr_age(x, "2025-07-01")
#> [1]  25 113  NA
```

They return exactly what the matching
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
selection does.
[`cpr_age()`](https://dataniel.github.io/pnrr/reference/cpr_age.md)
takes the same reference as
[`age_at()`](https://dataniel.github.io/pnrr/reference/age_at.md), as a
value, so inside `mutate()` a column works directly:

``` r
df |>
  dplyr::filter(cpr_valid(pnr)) |>
  dplyr::mutate(alder = cpr_age(pnr, year))
```

Each call parses the CPR numbers again. When you need several columns,
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
parses once for all of them.

## `pseudo_cpr()`: a serial number instead of the CPR number

Before data leaves a secure environment, derive what the analysis needs
and replace the CPR number with a serial number:

``` r
df <- data.frame(pnr = c("0101004007", "1111111118", "010100-4007"), year = 2025L)
df |>
  add_cpr_info(pnr, age_at(year), sex) |>
  dplyr::mutate(id = pseudo_cpr(pnr), pnr = NULL)
#>   year age sex id
#> 1 2025  24   1  1
#> 2 2025 113   0  2
#> 3 2025  24   1  1
```

The same CPR number gets the same serial number, also across formats, so
a person can still be followed across rows. The numbers are drawn in
random order: numbering in sorted order would follow the birth date, and
in order of appearance the row order of the source file.

No key is kept, so two calls give unrelated numbers. To link several
tables, pseudonymise them in one call or join first. Use `seed` to get
the same numbering again on exactly the same input:

``` r
pseudo_cpr(c("0101004007", "1111111118", "010100-4007"), seed = 1)
#> [1] 1 2 1
```

A seed is a secret. With the seed and the number of persons, anyone can
redo the shuffle and find where in the source each serial number first
appeared. Keep it, and the script that contains it, with the source
data.

A serial number makes the data pseudonymous, not anonymous: birth date,
sex and other columns can still single out a person.
