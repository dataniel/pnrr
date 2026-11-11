x <- c("0101004007", "111111-1118", "101004007", "3102004007", "notacpr", NA,
       "0101004000", "2902004007", "0101585001")

test_that("vector functions agree with add_cpr_info() selections", {
  info <- add_cpr_info(data.frame(pnr = x), pnr, bday, byear, sex, valid, mod11,
                       age_a = age_at(2025), age_b = age_at(2025, "medio"),
                       age_c = age_at("2024-02-28"))
  expect_identical(cpr_birth_date(x), info$bday)
  expect_identical(cpr_birth_year(x), info$byear)
  expect_identical(cpr_sex(x), info$sex)
  expect_identical(cpr_valid(x), info$valid)
  expect_identical(cpr_mod11(x), info$mod11)
  expect_identical(cpr_age(x, 2025), info$age_a)
  expect_identical(cpr_age(x, 2025, "medio"), info$age_b)
  expect_identical(cpr_age(x, "2024-02-28"), info$age_c)
  expect_identical(cpr_age(x, as.Date("2024-02-28")), info$age_c)
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

test_that("cpr_age() takes per-row references and the age_at() conventions", {
  y <- c("0101004007", "0101004007", "0101004007")
  expect_identical(cpr_age(y, 2024:2026), 23:25)
  expect_identical(cpr_age(y, 2001, "jan1"), rep(1L, 3))
  expect_identical(cpr_age(y, 2001), rep(0L, 3))
  expect_identical(cpr_age(y, c(2025, NA, 2025)), c(24L, NA, 24L))
  expect_identical(cpr_age(y), add_cpr_info(data.frame(pnr = y), pnr, age)$age)
  year <- 2030
  df <- data.frame(pnr = y, year = 2024:2026)
  expect_identical(with(df, cpr_age(pnr, year)), 23:25)
})

test_that("errors name the function the user called", {
  expect_error(cpr_age("0101004007", 2025, date = "2025-01-01"), "unused argument")
  expect_error(cpr_age("0101004007", at = "ultimo"), "cpr_age()", fixed = TRUE)
  expect_error(cpr_age("0101004007", "2025-01-01", "ultimo"), "only used with a year")
  expect_error(cpr_age("0101004007", 2025.5), "whole numbers")
  expect_error(cpr_age(c("0101004007", "0101004007"), 2024:2026), "length 1")
  expect_error(cpr_age("0101004007", "2025-02-30"), "ISO dates")
  expect_error(cpr_age("0101004007", TRUE), "Date vector")
  expect_identical(cpr_age("0101004007", as.Date("2025-07-01")), 25L)
  expect_error(cpr_sex(list("0101004007")), "cpr_sex()", fixed = TRUE)
  expect_error(age_at(at = "ultimo"), "age_at()", fixed = TRUE)
})

test_that("numeric CPR columns give what their text form gives", {
  num <- c(101004007, 1111111118, 3102004007, 12345, 101004007.5, -101004007,
           0, 1e15, NA, NaN, Inf, 2902001234, 12345678901)
  txt <- as.character(num)
  for (f in list(cpr_birth_date, cpr_birth_year, cpr_sex, cpr_valid, cpr_mod11)) {
    expect_identical(f(num), f(txt))
  }
  expect_identical(cpr_age(num, 2025), cpr_age(txt, 2025))
  int <- c(101004007L, 1111111118L, NA, 12345L, -101004007L)
  expect_identical(cpr_valid(int), cpr_valid(as.character(int)))
  expect_identical(cpr_birth_date(int), cpr_birth_date(as.character(int)))
  df <- data.frame(pnr = num, year = 2025L)
  expect_identical(
    add_cpr_info(df, pnr, age_at(year))[-1],
    add_cpr_info(data.frame(pnr = txt, year = 2025L), pnr, age_at(year))[-1]
  )
  expect_identical(add_cpr_info(df, pnr, sex)$pnr, num)
})

test_that("whole numbers that R writes in scientific notation keep their digits", {
  # as.character(1010000000) is "1.01e+09", but no digit is lost in the number.
  x <- c(1010000000, 3010000000)
  expect_identical(as.character(x), c("1.01e+09", "3.01e+09"))
  expect_identical(cpr_valid(x), cpr_valid(c("1010000000", "3010000000")))
  expect_identical(cpr_birth_date(x), cpr_birth_date(c("1010000000", "3010000000")))
  expect_identical(clean_cpr(x), c("1010000000", "3010000000"))
  expect_identical(clean_cpr(c(1e15, 101004007.5, 1e300)), as.character(c(1e15, 101004007.5, 1e300)))
  d <- diagnose_cpr(x)
  expect_identical(d$checks$n[d$checks$check == "scientific"], 0L)
  expect_identical(pseudo_cpr(c(1010000000, 1010000000)), c(1L, 1L))
})
