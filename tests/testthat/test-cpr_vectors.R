x <- c("0101004007", "111111-1118", "101004007", "3102004007", "notacpr", NA,
       "0101004000", "2902004007", "0101585001")

test_that("vector functions agree with add_cpr_info() selections", {
  info <- add_cpr_info(data.frame(pnr = x), pnr, bday, byear, sex, valid, mod11,
                       age_a = age(2025), age_b = age(2025, "medio"),
                       age_c = age(date = "2024-02-28"))
  expect_identical(cpr_birth_date(x), info$bday)
  expect_identical(cpr_birth_year(x), info$byear)
  expect_identical(cpr_sex(x), info$sex)
  expect_identical(cpr_valid(x), info$valid)
  expect_identical(cpr_mod11(x), info$mod11)
  expect_identical(cpr_age(x, 2025), info$age_a)
  expect_identical(cpr_age(x, 2025, "medio"), info$age_b)
  expect_identical(cpr_age(x, date = "2024-02-28"), info$age_c)
  expect_identical(cpr_age(x, date = as.Date("2024-02-28")), info$age_c)
})

test_that("types and values", {
  expect_s3_class(cpr_birth_date(x), "Date")
  expect_identical(cpr_birth_year(x),
    c(2000L, 1911L, 2000L, NA, NA, NA, 2000L, 2000L, 1858L))
  expect_identical(cpr_birth_year(x), as.integer(format(cpr_birth_date(x), "%Y")))
  expect_type(cpr_sex(x), "integer")
  expect_false(anyNA(cpr_valid(x)))
  expect_identical(cpr_mod11(c("0101004007", "0101004000", "bad")), c(TRUE, FALSE, NA))
  expect_identical(cpr_birth_year(character()), integer())
  expect_identical(cpr_valid(c(a = "0101004007")), TRUE)
  expect_identical(cpr_birth_year(101004007), 2000L)
})

test_that("cpr_age() takes per-row references and the age() conventions", {
  y <- c("0101004007", "0101004007", "0101004007")
  expect_identical(cpr_age(y, 2024:2026), 23:25)
  expect_identical(cpr_age(y, 2001, primo = "jan1"), rep(1L, 3))
  expect_identical(cpr_age(y, 2001), rep(0L, 3))
  expect_identical(cpr_age(y, c(2025, NA, 2025)), c(24L, NA, 24L))
  expect_identical(cpr_age(y), add_cpr_info(data.frame(pnr = y), pnr, age)$age)
  year <- 2030
  df <- data.frame(pnr = y, year = 2024:2026)
  expect_identical(with(df, cpr_age(pnr, year)), 23:25)
})

test_that("errors name the function the user called", {
  expect_error(cpr_age("0101004007", 2025, date = "2025-01-01"), "only one of year and date in cpr_age()", fixed = TRUE)
  expect_error(cpr_age("0101004007", at = "ultimo"), "cpr_age()", fixed = TRUE)
  expect_error(cpr_age("0101004007", 2025, "ultimo", primo = "jan1"), "cpr_age()", fixed = TRUE)
  expect_error(cpr_age("0101004007", 2025.5), "whole years")
  expect_error(cpr_age(c("0101004007", "0101004007"), 2024:2026), "length 1")
  expect_error(cpr_age("0101004007", date = "2025-02-30"), "ISO dates")
  expect_error(cpr_age("0101004007", date = 2025), "Date vector")
  expect_error(cpr_sex(list("0101004007")), "cpr_sex()", fixed = TRUE)
  expect_error(age(2025, date = "2025-01-01"), "in age()", fixed = TRUE)
})
