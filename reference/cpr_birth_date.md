# Derive one piece of information from CPR numbers

Vector versions of the selections in
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md):
a vector of CPR numbers in, one vector of the same length out. They
belong inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
or [`ifelse()`](https://rdrr.io/r/base/ifelse.html), where a data frame
function does not fit.

## Usage

``` r
cpr_birth_date(x)

cpr_birth_year(x)

cpr_sex(x)

cpr_valid(x)

cpr_koen(x)

cpr_status(x)

cpr_mod11(x)
```

## Arguments

- x:

  A vector of CPR numbers. Values are read after the same cleaning as
  [`clean_cpr()`](https://dataniel.github.io/pnrr/reference/clean_cpr.md),
  so dashes, spaces and a lost leading zero do not matter. Numbers are
  read as their digits, and factors as their labels.

## Value

A vector of the same length as `x`, without names.

## Details

The values are exactly those of the matching selection in
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md),
from the same native code:

|                    |           |                                             |
|--------------------|-----------|---------------------------------------------|
| Function           | Selection | Type                                        |
| `cpr_birth_date()` | `bday`    | Date                                        |
| `cpr_birth_year()` | `byear`   | integer                                     |
| `cpr_sex()`        | `sex`     | integer, 1 male (odd final digit), 0 female |
| `cpr_koen()`       | `koen`    | integer, 1 male, 2 female                   |
| `cpr_valid()`      | `valid`   | logical, never `NA`                         |
| `cpr_status()`     | `status`  | factor, never `NA`                          |
| `cpr_mod11()`      | `mod11`   | logical, `NA` when not ten digits           |

Birth date, birth year and sex are `NA` where `cpr_valid()` is `FALSE`.
`cpr_valid()` checks ten digits and a real encoded date, not whether the
number was assigned to a person; modulus 11 is not part of it, because
the CPR office has issued numbers that fail it since 2007.

`cpr_status()` says why. Its levels are `valid`, `missing`,
`scientific`, `wrong_length`, `non_digit` and `invalid_date`: the
problems of
[`diagnose_cpr()`](https://dataniel.github.io/pnrr/reference/diagnose_cpr.md),
where each is explained, and always in agreement with it.
`cpr_status(x) == "valid"` is `cpr_valid(x)`. It is a factor so that
`table(cpr_status(x))` also shows the problems that did not occur.

`cpr_sex()` and `cpr_koen()` hold the same information in two codings.
`cpr_sex()` is 0/1, which sums and averages directly. `cpr_koen()` is
1/2 as `KOEN` in the registers of Statistics Denmark, so the two can be
compared without recoding.

Birth year is its own function rather than an option of
`cpr_birth_date()`, so each function always returns one type.

Each call parses the CPR numbers again. That costs little, a few
hundredths of a second per million values, but when you need several
columns,
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
parses once for all of them.

For age, see
[`cpr_age()`](https://dataniel.github.io/pnrr/reference/cpr_age.md).

## See also

[`cpr_age()`](https://dataniel.github.io/pnrr/reference/cpr_age.md),
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md),
[`diagnose_cpr()`](https://dataniel.github.io/pnrr/reference/diagnose_cpr.md)

## Examples

``` r
x <- c("0101004007", "111111-1118", "101004007", "3102004007", NA)
cpr_birth_date(x)
#> [1] "2000-01-01" "1911-11-11" "2000-01-01" NA           NA          
cpr_birth_year(x)
#> [1] 2000 1911 2000   NA   NA
cpr_sex(x)
#> [1]  1  0  1 NA NA
cpr_koen(x)
#> [1]  1  2  1 NA NA
cpr_valid(x)
#> [1]  TRUE  TRUE  TRUE FALSE FALSE
cpr_status(x)
#> [1] valid        valid        valid        invalid_date missing     
#> Levels: valid missing scientific wrong_length non_digit invalid_date
table(cpr_status(x))
#> 
#>        valid      missing   scientific wrong_length    non_digit invalid_date 
#>            3            1            0            0            0            1 
cpr_mod11(x)
#> [1]  TRUE  TRUE  TRUE FALSE    NA

# Typical use
# df |>
#   dplyr::filter(cpr_valid(pnr)) |>
#   dplyr::mutate(koen = ifelse(cpr_sex(pnr) == 1L, "Mand", "Kvinde"))
```
