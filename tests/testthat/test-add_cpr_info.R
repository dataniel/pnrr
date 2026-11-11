test_that("selections preserve input, order, and output types", {
  df <- data.frame(pnr = c("0101004007", "111111-1118", "101004007"), year = 2025L)
  original <- df
  out <- add_cpr_info(df, pnr, sex, birth_date = bday, age_at(year))
  expect_identical(df, original)
  expect_identical(out$pnr, df$pnr)
  expect_named(out, c("pnr", "year", "sex", "birth_date", "age"))
  expect_identical(out$sex, c(1L, 0L, 1L))
  expect_identical(out$birth_date, as.Date(c("2000-01-01", "1911-11-11", "2000-01-01")))
  expect_identical(out$age, c(24L, 113L, 24L))
  expect_identical(add_cpr_info(df, "pnr", sex), add_cpr_info(df, pnr, sex))
  defaults <- add_cpr_info(df, pnr)
  expect_named(defaults, c(names(df), "bday", "age", "sex", "mod11", "valid"))
  expect_identical(defaults$age, add_cpr_info(df, pnr, age_at(Sys.Date()))$age)
  expect_identical(add_cpr_info(df, pnr, age)$age, defaults$age)
})

test_that("multiple reference years and positions work in one call", {
  df <- data.frame(pnr = c("0101004007", "3006004007", "0107004007",
                          "0207004007", "3112004007", "2902004007"), year = 2025L)
  out <- add_cpr_info(df, pnr, primo = age_at(year), medio = age_at(year, "medio"),
                     ultimo = age_at(year, "ultimo"))
  expect_identical(out$primo, rep(24L, 6))
  expect_identical(out$medio, c(25L, 25L, 25L, 24L, 24L, 25L))
  expect_identical(out$ultimo, rep(25L, 6))
  expect_identical(add_cpr_info(df, pnr, age_at(2025))$age, out$primo)
  expect_identical(add_cpr_info(df, pnr, age_at(year + 1L))$age, out$primo + 1L)
})

test_that("January first births follow the selected primo convention", {
  df <- data.frame(pnr = "0101004007", year = 1999:2002)
  out <- add_cpr_info(df, pnr, bday, primoalder = age_at(year),
                      explicit_primo = age_at(year, "primo"),
                      january = age_at(year, "jan1"),
                      date_age = age_at(as.Date(paste0(year, "-01-01"))))
  expect_identical(out$bday, rep(as.Date("2000-01-01"), 4))
  expect_identical(out$primoalder, -2:1)
  expect_identical(out$explicit_primo, -2:1)
  expect_identical(out$date_age, -1:2)
  expect_identical(out$january, out$date_age)
})

test_that("previous year end can be used directly as the age reference", {
  df <- data.frame(pnr = c("0101004007", "0201004007", "3112004007",
                          "2902004007", "0101004007"),
                   year = c(rep(2001L, 4), NA_integer_))
  out <- add_cpr_info(df, pnr,
    primoalder = age_at(year - 1L, "ultimo"),
    january = age_at(year, "jan1"),
    date_age = age_at(as.Date(paste0(year, "-01-01")) - 1L))
  expect_identical(out$primoalder, c(rep(0L, 4), NA_integer_))
  expect_identical(out$january, c(1L, rep(0L, 3), NA_integer_))
  expect_identical(out$date_age, out$primoalder)
  expect_identical(add_cpr_info(df, pnr, age_at(2001L - 1L, "ultimo"))$age,
                   rep(0L, 5))
})

test_that("primo can use previous ultimo for population statistics", {
  df <- data.frame(pnr = c("0101004007", "0201004007", "3112004007", "2902004007",
                          "0101004007", "0101004007"),
                   year = c(rep(2001L, 4), NA_integer_, 2000L))
  out <- add_cpr_info(df, pnr,
    opening = age_at(year, "primo"),
    previous = age_at(year - 1L, "ultimo"),
    january = age_at(year, "jan1"),
    default = age_at(year))
  expect_identical(out$opening, c(rep(0L, 4), NA_integer_, -1L))
  expect_identical(out$opening, out$previous)
  expect_identical(out$opening, out$default)
  expect_identical(out$january, c(1L, rep(0L, 3), NA_integer_, 0L))
  expect_identical(add_cpr_info(df, pnr, age_at(2001, "primo"))$age,
                   rep(0L, 6))
  empty <- df[FALSE, ]
  expect_identical(add_cpr_info(empty, pnr, age_at(year, "primo"))$age, integer())
  expect_error(age_at(at = "primo"), "needs a year")
  expect_error(age_at(2025, "unknown"), "at")
  expect_error(age_at(2025, primo = "jan1"), "unused argument")
  expect_error(add_cpr_info(df, pnr, age_at(1, "primo")), "at least 2")
  expect_error(add_cpr_info(df, pnr, age_at(1)), "31 December of the year before")
  expect_identical(add_cpr_info(df[1, ], pnr, age_at(1, "jan1"))$age, -1999L)
})

test_that("references use caller environments and explicit data pronouns", {
  df <- data.frame(pnr = c("0101004007", "0101004007"), year = 2024:2025,
                   date = c("2024-07-01", "2025-07-01"), ref = 1:2)
  year <- 2030L
  expect_identical(add_cpr_info(df, pnr, age_at(year))$age, 23:24)
  expect_identical(add_cpr_info(df, pnr, age_at(.env$year))$age, c(29L, 29L))
  expect_identical(add_cpr_info(df, pnr, age_at(.data$year))$age, 23:24)
  expect_identical(add_cpr_info(df, pnr, age_at(date))$age, 24:25)
  wrapper <- function(data, col, reference) {
    add_cpr_info(data, {{ col }}, alder = age_at({{ reference }}))
  }
  expect_identical(wrapper(df, pnr, year)$alder, 23:24)
  # Selection names are syntax, independent of columns/caller variables.
  sex <- "not a selector"
  df$sex <- 99L
  expect_identical(add_cpr_info(df, pnr, koen = sex)$koen, c(1L, 1L))
  expect_identical(add_cpr_info(df, pnr, age = age_at(year))$age, 23:24)
})

test_that("leap birthdays and missing references retain calendar semantics", {
  dates <- c("2024-02-28", "2024-02-29", "2024-03-01", "2025-02-28",
             "2025-03-01", "2100-02-28", "2100-03-01", NA_character_)
  df <- data.frame(pnr = rep("2902004007", length(dates)))
  expected <- c(23L, 24L, 24L, 24L, 25L, 99L, 100L, NA_integer_)
  expect_identical(add_cpr_info(df, pnr, age_at(dates))$age, expected)
  expect_identical(add_cpr_info(df, pnr, age_at(as.Date(dates)))$age, expected)
  df <- data.frame(pnr = rep("0101004007", 3), year = c(2024L, NA_integer_, 2026L))
  expect_identical(add_cpr_info(df, pnr, age_at(year))$age, c(23L, NA_integer_, 25L))
  expect_identical(add_cpr_info(df, pnr, age_at("1999-12-31"))$age, rep(-1L, 3))
})

test_that("format, calendar validity, and checksum remain separate", {
  df <- data.frame(pnr = c("0101004007", "3102004007", "notacpr", NA, "0101004000"))
  out <- add_cpr_info(df, pnr, bday, sex, valid, mod11, age_at(2025))
  expect_identical(out$valid, c(TRUE, FALSE, FALSE, FALSE, TRUE))
  expect_true(all(is.na(out$bday[2:4])))
  expect_true(all(is.na(out$sex[2:4])))
  expect_true(all(is.na(out$age[2:4])))
  expect_true(out$mod11[1])
  expect_false(out$mod11[5])
  expect_true(all(is.na(out$mod11[3:4])))
  expect_identical(out$age[c(1, 5)], c(24L, 24L))
})

test_that("century boundaries remain correct", {
  df <- data.frame(pnr = c("0101364001", "0101374001", "0101575001",
                          "0101585001", "0101000001", "0101009001"))
  expect_identical(add_cpr_info(df, pnr, bday)$bday,
    as.Date(c("2036-01-01", "1937-01-01", "2057-01-01", "1858-01-01", "1900-01-01", "2000-01-01")))
})

test_that("collisions require explicit consent and never rename input columns", {
  df <- data.frame(pnr = "0101004007", age = 99L, year = 2025L)
  expect_error(add_cpr_info(df, pnr, age_at(year)), "overwrite = TRUE")
  expect_identical(add_cpr_info(df, pnr, age_at(year), .overwrite = TRUE)$age, 24L)
  expect_identical(df$age, 99L)
  expect_error(add_cpr_info(df, pnr, age_at(year), age_at(2026)), "Duplicate output")
  expect_error(add_cpr_info(df, pnr, x = sex, x = bday), "Duplicate output")
  expect_error(add_cpr_info(df, pnr, pnr = sex, .overwrite = TRUE), "source column")
  # All calculations see original columns, including columns being overwritten.
  out <- add_cpr_info(df, pnr, year = age_at(year), second = age_at(year), .overwrite = TRUE)
  expect_identical(out$year, 24L)
  expect_identical(out$second, 24L)
  expect_error(add_cpr_info(df, pnr, sex, .overwrite = NA), "TRUE or FALSE")
})

test_that("invalid selections and old API calls have actionable errors", {
  df <- data.frame(pnr = "0101004007")
  expect_error(add_cpr_info(df, absent, sex), "not found")
  expect_error(add_cpr_info(df, pnr, birthday), "Unknown CPR selection")
  expect_error(add_cpr_info(df, pnr, age = list(2025, "primo")), "Unknown CPR selection")
  expect_error(add_cpr_info(df, pnr, add = "age", ref_date = 2025), "API has changed")
  expect_error(add_cpr_info(df, pnr, sex()), "Unknown CPR selection")
  expect_error(add_cpr_info(df, pnr, ), "Empty CPR selection")
  expect_error(add_cpr_info(NULL, pnr), "data frame")
  expect_error(add_cpr_info(df, paste0("p", "nr")), "column name")
  bad <- df; names(bad) <- ""
  expect_error(add_cpr_info(bad, pnr), "column names")
})

test_that("reference arguments are validated with useful errors", {
  df <- data.frame(pnr = rep("0101004007", 3))
  expect_error(add_cpr_info(df, pnr, age_at(2025, date = "2025-01-01")), "unused argument")
  expect_error(add_cpr_info(df, pnr, age_at("2025-01-01", at = "primo")), "only used with a year")
  expect_error(add_cpr_info(df, pnr, age_at(as.Date("2025-01-01"), "ultimo")), "is a date")
  expect_error(add_cpr_info(df, pnr, age_at(at = "ultimo")), "needs a year")
  expect_error(add_cpr_info(df, pnr, age_at(2025, "bad")), "at")
  expect_error(add_cpr_info(df, pnr, age_at(missing_year)), "age reference")
  for (x in list(2025.5, Inf, 0, 10000, -2025)) {
    expect_error(add_cpr_info(df, pnr, age_at(x)), "whole numbers between 1 and 9999")
  }
  for (x in list(TRUE, factor(2025), Sys.time(), list(2025), as.Date(Inf))) {
    expect_error(add_cpr_info(df, pnr, age_at(x)), "whole years, a Date vector or ISO date strings")
  }
  expect_error(add_cpr_info(df, pnr, age_at(Sys.time())), "as.Date")
  for (x in list(2024:2025, integer(), 2024:2027)) {
    expect_error(add_cpr_info(df, pnr, age_at(x)), "length 1")
  }
  for (x in c("bad", "2025", "2025-02-29", "2025-01-01junk", "2025-1-1")) {
    expect_error(add_cpr_info(df, pnr, age_at(x)), "ISO dates")
  }
})

test_that("the type of the reference decides whether it is a year or a date", {
  df <- data.frame(pnr = rep("0101004007", 3), year = 2024:2026,
                   day = as.Date(c("2024-06-30", "2025-01-01", NA)),
                   iso = c("2024-06-30", "2025-01-01", NA), empty = NA)
  out <- add_cpr_info(df, pnr, y = age_at(year), d = age_at(day), i = age_at(iso),
                      e = age_at(empty), today = age_at(), bare = age)
  expect_identical(out$y, 23:25)
  expect_identical(out$d, c(24L, 25L, NA))
  expect_identical(out$i, out$d)
  expect_identical(out$e, rep(NA_integer_, 3))
  expect_identical(out$today, out$bare)
  expect_identical(out$today, add_cpr_info(df, pnr, age_at(Sys.Date()))$age)
})

test_that("the old age() helper points to age_at()", {
  df <- data.frame(pnr = "0101004007", year = 2025L)
  expect_error(add_cpr_info(df, pnr, age(year)), "is now")
  expect_error(add_cpr_info(df, pnr, alder = age(date = "2025-01-01")), "age_at")
  expect_error(add_cpr_info(df, pnr, age(year, primo = "jan1")), "jan1")
  expect_identical(add_cpr_info(df, pnr, age)$age, add_cpr_info(df, pnr, age_at())$age)
})

test_that("koen is sex in the register coding", {
  df <- data.frame(pnr = c("0101004007", "1111111118", "3102004007", NA, "101004008"))
  out <- add_cpr_info(df, pnr, sex, koen)
  expect_identical(out$koen, c(1L, 2L, NA, NA, 2L))
  expect_identical(out$koen, 2L - out$sex)
  expect_identical(cpr_koen(df$pnr), out$koen)
  expect_identical(cpr_koen(c(101004007, 1111111118)), 1:2)
  expect_false("koen" %in% names(add_cpr_info(df, pnr)))
})

test_that("status gives every row the problem diagnose_cpr() counts", {
  x <- c("0101004007", "010100-4007", "101004007", "1.01004E+08", "3102004007",
         "12345", "ukendt", NA, "", " - ", "1111111118", "0101004007\t", "010100.4007")
  levels <- c("valid", "missing", "scientific", "wrong_length", "non_digit", "invalid_date")
  status <- cpr_status(x)
  expect_s3_class(status, "factor")
  expect_identical(levels(status), levels)
  expect_false(anyNA(status))
  expect_identical(as.character(status), c("valid", "valid", "valid", "scientific",
    "invalid_date", "wrong_length", "non_digit", "missing", "missing", "missing",
    "valid", "valid", "scientific"))
  expect_identical(status == "valid", cpr_valid(x))
  d <- diagnose_cpr(x)
  counts <- stats::setNames(d$checks$n[d$checks$kind == "problem"], levels)
  expect_identical(c(table(status)), counts)
  for (level in levels) {
    expect_identical(which(status == level), d$checks$rows[[match(level, d$checks$check)]])
  }
  out <- add_cpr_info(data.frame(pnr = x), pnr, status, valid, why = status)
  expect_identical(out$status, status)
  expect_identical(out$why, status)
  expect_identical(cpr_status(character()), factor(character(), levels = levels))
})

test_that("status reads numbers and factors as their written form", {
  num <- c(101004007, 1010000000, 12345, 101004007.5, NA, 1e15, 3102004007)
  expect_identical(as.character(cpr_status(num)),
    c("valid", "valid", "wrong_length", "scientific", "missing", "scientific", "invalid_date"))
  out <- add_cpr_info(data.frame(pnr = num), pnr, status, bday)
  expect_identical(out$status, cpr_status(num))
  expect_identical(out$bday, cpr_birth_date(num))
  expect_identical(out$pnr, num)
  expect_identical(cpr_status(factor(c("010100-4007", "x"))), cpr_status(c("010100-4007", "x")))
})

test_that("empty frames, tibble grouping, and data tables retain structure", {
  empty <- data.frame(pnr = character(), year = integer())
  expect_identical(add_cpr_info(empty, pnr, age_at(year))$age, integer())
  expect_identical(add_cpr_info(empty, pnr)$bday, as.Date(character()))
  df <- tibble::tibble(pnr = c("0101004007", "1111111118"), g = 1:2)
  grouped <- dplyr::group_by(df, g)
  result <- add_cpr_info(grouped, pnr, sex)
  expect_s3_class(result, "grouped_df")
  expect_identical(dplyr::group_vars(result), "g")
  expect_identical(result$pnr, df$pnr)
  dt <- data.table::as.data.table(df)
  copy <- data.table::copy(dt)
  result <- add_cpr_info(dt, pnr, sex)
  expect_s3_class(result, "data.table")
  expect_identical(dt, copy)
  expect_identical(result$sex, c(1L, 0L))
})


test_that("qualified age helper and tidy injection work", {
  df <- data.frame(pnr = "0101004007", year = 2025L)
  expect_identical(add_cpr_info(df, pnr, pnrr::age_at(year))$age, 24L)
  selections <- rlang::quos(alder = age_at(year), sex)
  expect_named(add_cpr_info(df, pnr, !!!selections), c("pnr", "year", "alder", "sex"))
})


test_that("native date arithmetic agrees with calendar dates over centuries", {
  set.seed(718)
  birth <- as.Date("1800-01-01") + sample.int(90000L, 3000L, replace = TRUE)
  y <- as.integer(format(birth, "%Y"))
  # Only representable years for century digit 5 (1858-1899, 2000-2057).
  keep <- (y >= 1858 & y <= 1899) | (y >= 2000 & y <= 2046)
  birth <- birth[keep]
  pnr <- paste0(format(birth, "%d%m%y"), "5001")
  reference <- as.Date("1700-01-01") + sample.int(180000L, length(birth), replace = TRUE)
  expected <- as.integer(as.integer(format(reference, "%Y")) - as.integer(format(birth, "%Y")) -
    (format(reference, "%m%d") < format(birth, "%m%d")))
  df <- data.frame(pnr = pnr, reference = reference)
  result <- add_cpr_info(df, pnr, bday, age_at(reference))
  expect_identical(result$bday, birth)
  expect_identical(result$age, expected)
  expect_identical(add_cpr_info(df, pnr, age_at(as.character(reference)))$age, expected)
  fractional <- as.Date(-0.5, origin = "1970-01-01")
  expect_identical(add_cpr_info(df, pnr, age_at(fractional))$age,
                   add_cpr_info(df, pnr, age_at("1969-12-31"))$age)
  bad <- data.frame(pnr = "invalid")
  expect_error(add_cpr_info(bad, pnr, age_at("2025-02-29")), "ISO dates")
  empty <- data.frame(pnr = character())
  expect_error(add_cpr_info(empty, pnr, age_at("2025-02-29")), "ISO dates")
})

test_that("output names are never taken as arguments", {
  df <- data.frame(pnr = "0101004007", year = 2025L)
  out <- add_cpr_info(df, pnr, d = bday, c = sex, cpr = age_at(year), da = byear, o = valid)
  expect_named(out, c("pnr", "year", "d", "c", "cpr", "da", "o"))
  expect_identical(out$cpr, 24L)
  expect_identical(out$da, 2000L)
  expect_identical(add_cpr_info(.data = df, .cpr_col = pnr, sex)$sex, 1L)
})

test_that("the old argument names give a pointer to the new ones", {
  df <- data.frame(pnr = "0101004007")
  expect_error(add_cpr_info(df, pnr, sex, overwrite = TRUE), ".overwrite", fixed = TRUE)
  expect_error(add_cpr_info(df, cpr_col = pnr), ".cpr_col", fixed = TRUE)
})

test_that("a returned data.table accepts := without a warning", {
  dt <- data.table::data.table(pnr = c("0101004007", "1111111118"), sex = 9L)
  result <- add_cpr_info(dt, pnr, bday, sex, .overwrite = TRUE)
  expect_identical(result$sex, c(1L, 0L))
  expect_identical(dt$sex, c(9L, 9L))
  # := warns about a shallow copy when the over-allocation is gone.
  expect_gt(data.table::truelength(result), length(result))
  expect_no_warning(data.table::set(result, j = "z", value = 1L))
  expect_named(result, c("pnr", "sex", "bday", "z"))
  expect_named(dt, c("pnr", "sex"))
})

test_that("invisible separators do not make a CPR invalid", {
  df <- data.frame(pnr = c("010100–4007", "0101004007\t"))
  expect_identical(add_cpr_info(df, pnr, valid)$valid, c(TRUE, TRUE))
  expect_identical(cpr_valid(df$pnr), c(TRUE, TRUE))
  expect_identical(pseudo_cpr(c(df$pnr, "0101004007")), rep(1L, 3))
})

test_that("year references agree for integer and double columns and are validated", {
  df <- data.frame(pnr = c("0101004007", "1111111118", "0101004007"))
  yi <- c(2025L, NA, 2001L)
  yd <- as.double(yi)
  for (at in c("primo", "medio", "ultimo")) {
    expect_identical(add_cpr_info(df, pnr, age_at(yi, at))$age, add_cpr_info(df, pnr, age_at(yd, at))$age)
  }
  expect_identical(add_cpr_info(df, pnr, age_at(yi))$age, c(24L, NA, 0L))
  expect_identical(add_cpr_info(df, pnr, age_at(yi, "jan1"))$age, c(25L, NA, 1L))
  expect_identical(add_cpr_info(df, pnr, age_at(c(2025, NaN, 2001)))$age, c(24L, NA, 0L))
  bad <- "whole numbers between 1 and 9999"
  expect_error(add_cpr_info(df, pnr, age_at(c(2025, 2025.5, 2025))), bad)
  expect_error(add_cpr_info(df, pnr, age_at(c(2025, Inf, 2025))), bad)
  expect_error(add_cpr_info(df, pnr, age_at(c(2025L, 0L, 2025L))), bad)
  expect_error(add_cpr_info(df, pnr, age_at(10000L)), bad)
  expect_error(add_cpr_info(df, pnr, age_at(c(2025L, 1L, NA))), "at least 2")
  expect_error(add_cpr_info(df, pnr, age_at(c(1, 0, 2025))), bad)
  expect_identical(add_cpr_info(df, pnr, age_at(1L, "ultimo"))$age, c(-1999L, -1910L, -1999L))
  expect_error(add_cpr_info(df, pnr, age_at(as.Date(c("2025-01-01", NA, Inf)))), "Date vector")
  expect_identical(add_cpr_info(df, pnr, age_at(yi, "jan1"))$age, add_cpr_info(df, pnr, age_at(yd, "jan1"))$age)
  expect_identical(add_cpr_info(df, pnr, age_at(as.Date(c("2025-01-01", NA, "2001-01-01"))))$age, c(25L, NA, 1L))
})
