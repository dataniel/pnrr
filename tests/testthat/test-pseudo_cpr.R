test_that("each distinct cleaned CPR gets one serial number", {
  x <- c("0101004007", "1111111118", "010100-4007", NA, "101004007", "", "notacpr")
  id <- pseudo_cpr(x)
  expect_type(id, "integer")
  expect_length(id, length(x))
  expect_identical(id[1], id[3])
  expect_identical(id[1], id[5])
  expect_true(all(is.na(id[c(4, 6)])))
  expect_setequal(id[!is.na(id)], 1:3)
})

test_that("the order is random, not sorted or by appearance", {
  x <- sprintf("%02d01004007", 1:28)
  orders <- vapply(1:20, function(s) identical(pseudo_cpr(x, seed = s), 1:28), logical(1))
  expect_false(any(orders))
  expect_false(identical(pseudo_cpr(x, seed = 1), pseudo_cpr(x, seed = 2)))
})

test_that("a seed reproduces the numbering and leaves the random stream alone", {
  x <- sprintf("%02d01004007", 1:28)
  set.seed(42)
  before <- runif(1)
  set.seed(42)
  a <- pseudo_cpr(x, seed = 7)
  expect_identical(runif(1), before)
  expect_identical(pseudo_cpr(x, seed = 7), a)
})

test_that("edge cases and argument checks", {
  expect_identical(pseudo_cpr(character()), integer())
  expect_identical(pseudo_cpr(c(NA, NA)), c(NA_integer_, NA_integer_))
  expect_identical(pseudo_cpr(c(a = "0101004007")), 1L)
  expect_identical(pseudo_cpr(c(101004007, 101004007)), c(1L, 1L))
  expect_error(pseudo_cpr("0101004007", seed = 1.5), "whole number")
  expect_error(pseudo_cpr("0101004007", seed = "a"), "whole number")
  expect_error(pseudo_cpr(list("0101004007")), "vector of CPR numbers")
})
