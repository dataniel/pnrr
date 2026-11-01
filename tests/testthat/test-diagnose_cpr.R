rows_of <- function(d, check) d$checks$rows[[match(check, d$checks$check)]]
n_of <- function(d, check) d$checks$n[match(check, d$checks$check)]

test_that("every value gets exactly one problem status", {
  x <- c("0101004007", "010100-4007", "101004007", "1.01004E+08",
         "3102004007", "12345", "ukendt", NA, "1111111118", "", " - ",
         "1111111118.0", "12345678901")
  d <- diagnose_cpr(x, as_of = "2025-01-01")
  expect_s3_class(d, "pnr_diagnosis")
  problems <- d$checks[d$checks$kind == "problem", ]
  expect_identical(sum(problems$n), length(x))
  expect_identical(sort(unlist(problems$rows)), seq_along(x))
  expect_identical(rows_of(d, "valid"), c(1L, 2L, 3L, 9L))
  expect_identical(rows_of(d, "missing"), c(8L, 10L, 11L))
  expect_identical(rows_of(d, "scientific"), c(4L, 12L))
  expect_identical(rows_of(d, "wrong_length"), c(6L, 13L))
  expect_identical(rows_of(d, "non_digit"), 7L)
  expect_identical(rows_of(d, "invalid_date"), 5L)
})

test_that("validity agrees with add_cpr_info()", {
  set.seed(31)
  x <- replicate(500, paste0(sample(c(0:9, "-", " ", "x"), sample(8:12, 1), replace = TRUE),
                             collapse = ""))
  x <- c(x, "0101004007", "2902004007", "2902014007")
  d <- diagnose_cpr(x, as_of = "2025-01-01")
  expect_identical(rows_of(d, "valid"),
                   which(add_cpr_info(data.frame(pnr = x), pnr, valid)$valid))
})

test_that("notes report Excel damage, separators, checksum and repeats", {
  x <- c("0101004007", "010100-4007", "101004007", "0101004000", "1111111118")
  d <- diagnose_cpr(x, as_of = "2025-01-01")
  expect_identical(rows_of(d, "zero_restored"), 3L)
  expect_identical(rows_of(d, "separators"), 2L)
  expect_identical(rows_of(d, "mod11_fails"), 4L)
  expect_identical(rows_of(d, "repeated"), 1:3)
  expect_identical(d$distinct, 3L)
  expect_identical(d$birth_range, as.Date(c("1911-11-11", "2000-01-01")))
  expect_equal(d$male_share, 3 / 5)
})

test_that("implausible birth dates are judged against as_of", {
  x <- c("0101004007", "0101994007", "0101805001", "0101054007")
  d <- diagnose_cpr(x, as_of = as.Date("2003-01-01"))
  expect_identical(rows_of(d, "born_after_as_of"), 4L)
  expect_identical(rows_of(d, "older_than_120"), 3L)
  d <- diagnose_cpr(x, as_of = "2030-01-01")
  expect_identical(n_of(d, "born_after_as_of"), 0L)
})

test_that("numeric input is diagnosed as its character form", {
  d <- diagnose_cpr(c(101004007, 1111111118, NA), as_of = "2025-01-01")
  expect_identical(rows_of(d, "valid"), 1:2)
  expect_identical(rows_of(d, "zero_restored"), 1L)
  expect_identical(rows_of(diagnose_cpr(factor("101004007"), "2025-01-01"), "valid"), 1L)
})

test_that("the report shows counts and rows, never CPR numbers", {
  x <- c("0101004007", "1.01004E+08", "3102004007", rep("1111111118", 7), NA)
  out <- cli::cli_fmt(print(diagnose_cpr(x, as_of = "2025-01-01")))
  out <- paste(out, collapse = "\n")
  expect_match(out, "8 of 11 valid (2 distinct)", fixed = TRUE)
  expect_match(out, "scientific", fixed = TRUE)
  expect_match(out, "row 2)", fixed = TRUE)
  expect_match(out, "rows 4, 5, 6, 7, 8, ... and 2 more", fixed = TRUE)
  expect_no_match(out, "0101004007|1111111118|3102004007")
  clean <- cli::cli_fmt(print(diagnose_cpr("0101004007", as_of = "2025-01-01")))
  expect_match(paste(clean, collapse = "\n"), "1 of 1 valid")
})

test_that("empty input and bad arguments", {
  d <- diagnose_cpr(character(), as_of = "2025-01-01")
  expect_identical(d$n, 0L)
  expect_true(all(d$checks$n == 0L))
  expect_true(is.na(d$male_share))
  expect_no_error(cli::cli_fmt(print(d)))
  expect_error(diagnose_cpr(data.frame(pnr = "0101004007")), "vector of CPR numbers")
  expect_error(diagnose_cpr("0101004007", as_of = "2025-02-30"), "as_of")
  expect_error(diagnose_cpr("0101004007", as_of = 2025), "as_of")
  expect_error(diagnose_cpr("0101004007", as_of = c("2025-01-01", "2026-01-01")), "as_of")
})
