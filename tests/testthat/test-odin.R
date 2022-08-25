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
