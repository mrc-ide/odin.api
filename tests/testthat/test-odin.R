test_that("can validate simple model", {
  code <- c("initial(x) <- 1",
            "deriv(x) <- 1")
  res <- odin_js_validate(code, NULL)
  expect_mapequal(
    res,
    list(valid = scalar(TRUE),
         metadata = list(variables = "x",
                         parameters = list(),
                         messages = list())))
})


test_that("can check requirements make sense", {
  code <- c("initial(x) <- 1",
            "deriv(x) <- 1")
  res <- odin_js_validate(code, list(timeType = "discrete"))
  expect_mapequal(
    res,
    list(valid = scalar(FALSE),
         error = list(
           message = scalar("Only continuous time models currently supported"),
           line = integer(0))))
})


test_that("can ensure models have the expected time type", {
  code <- c("initial(x) <- 1",
            "update(x) <- 1")
  res <- odin_js_validate(code, list(timeType = "continuous"))
  msg <- "Expected a continuous time model (using deriv, not update)"
  expect_mapequal(
    res,
    list(valid = scalar(FALSE),
         error = list(
           message = scalar(msg), line = 2)))
})


test_that("disable use of arrays", {
  code <- c("initial(x[]) <- 1",
            "deriv(x[]) <- 1",
            "dim(x) <- 5")
  res <- odin_js_validate(code, list(timeType = "continuous"))
  msg <- "Models that use arrays are not supported"
  expect_mapequal(
    res,
    list(valid = scalar(FALSE),
         error = list(
           message = scalar(msg), line = c(1, 2))))
})


test_that("can return nice errors on parse failure", {
  res <- odin_js_validate("y <- 1\nz <- 2\nx b\na <- 1", NULL)
  expect_equal(res$valid, scalar(FALSE))
  expect_equal(res$error$message, scalar("unexpected symbol"))
  expect_equal(res$error$line, 3)
})


test_that("can tidy up parse errors", {
  f <- function(code) {
    parse_parse_error(
      tryCatch(parse(text = code, keep.source = TRUE),
               error = identity)$message)
  }
  expect_equal(f("x y"),
               list(msg = "unexpected symbol",
                    line = 1))
  expect_equal(f("a <- 1\nx y"),
               list(msg = "unexpected symbol",
                    line = 2))
  expect_equal(f("R_0 <- user(1.5) a"),
               list(msg = "unexpected symbol",
                    line = 1))
})