# The reference for an age from CPR numbers

Use inside
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md)
to say when the age is measured: `alder = age_at(year)`. It describes
the reference; the age is calculated by
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md).
For a vector of ages, see
[`cpr_age()`](https://dataniel.github.io/pnrr/reference/cpr_age.md).

## Usage

``` r
age_at(ref, at = "primo")
```

## Arguments

- ref:

  The reference, as a value, a column of the data or an expression on
  its columns. Its type decides what it is:

  - whole numbers are **years**, and `at` chooses the day in the year;

  - a Date vector or ISO date strings (`"YYYY-MM-DD"`) are **dates**.

  One value for all rows, or one per row. Left out, the reference is
  today, [`Sys.Date()`](https://rdrr.io/r/base/Sys.time.html).

- at:

  The day in the year, when `ref` is a year:

  - `"primo"` (default): 31 December of the year **before**, the opening
    of the year. `age_at(2025)` is the age on 31 December 2024.

  - `"jan1"`: 1 January.

  - `"medio"`: 1 July.

  - `"ultimo"`: 31 December.

  Not allowed when `ref` is a date.

## Value

An age specification for
[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md).

## Details

**Why primo is the day before.** In population statistics the opening
population of a year is the closing population of the year before, and
the ages must agree: `age_at(year)` equals `age_at(year - 1, "ultimo")`.
A person born on 1 January 2000 is therefore 0 in `age_at(2001)`. Use
`"jan1"` to count that birthday, which gives 1. The choice moves the age
reference only, not who is in the population.

Missing references give missing ages. A data column takes precedence
over a variable of the same name where the function is called;
`.env$name` and `.data$name` make the source explicit. A number is
always a year: for a date held as a number, convert it with
[`as.Date()`](https://rdrr.io/r/base/as.Date.html) first.

The name says what the argument is, the time the age is measured at. In
daos the helper was `age(year, at, date, primo)`. `date` is now the same
argument as the year, and `primo = "jan1"` is the `at` value `"jan1"`.

## See also

[`add_cpr_info()`](https://dataniel.github.io/pnrr/reference/add_cpr_info.md),
[`cpr_age()`](https://dataniel.github.io/pnrr/reference/cpr_age.md)

## Examples

``` r
df <- data.frame(pnr = "0101004007", year = 2025L,
                 seen = as.Date("2025-07-01"))
add_cpr_info(df, pnr, age_at(year), sex)
#>          pnr year       seen age sex
#> 1 0101004007 2025 2025-07-01  24   1
add_cpr_info(df, pnr,
  primo = age_at(year),
  jan1 = age_at(year, "jan1"),
  ultimo = age_at(year, "ultimo"))
#>          pnr year       seen primo jan1 ultimo
#> 1 0101004007 2025 2025-07-01    24   25     25
add_cpr_info(df, pnr, alder = age_at("2025-07-01"))
#>          pnr year       seen alder
#> 1 0101004007 2025 2025-07-01    25
add_cpr_info(df, pnr, alder = age_at(seen))
#>          pnr year       seen alder
#> 1 0101004007 2025 2025-07-01    25
```
