context("logging")

test_that("logging produces a message", {
  expect_message(
    api_log(sprintf("%s %s", "a", "b")),
    "\\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\\] a b")
  expect_message(
    api_log("x"),
    "\\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\\] x")
})

test_that("log start includes request and path info", {
  req <- list(REQUEST_METHOD = "GET", PATH_INFO = "/my/path")
  expect_message(
    api_log_start(NULL, req, NULL),
    "\\[.+\\] GET /my/path")
})

test_that("log end includes code and response size", {
  res <- list(status = 200, body = "a string")
  value <- "something"
  expect_message(
    res <- api_log_end(NULL, NULL, res, value),
    "\\[.+\\] `--> 200 \\(8 bytes\\)")
  expect_identical(res, value)
})

test_that("log end includes code and response size for binary data", {
  res <- list(status = 200, body = as.raw(sample(256) - 1))
  value <- "something"
  expect_message(
    res <- api_log_end(NULL, NULL, res, value),
    "\\[.+\\] `--> 200 \\(256 bytes\\)")
  expect_identical(res, value)
})

test_that("log end handles errors", {
  input_res <- list(status = 400, body = '{"errors":[
                                            {"error": "RUN_FAILED",
                                            "detail": "Failed to run report",
                                            "trace": ["the", "trace"]}
                                           ]}',
              headers = list("Content-Type" = "application/json"))
  value <- "something"
  messages <- testthat::capture_messages(
    res <- api_log_end(NULL, NULL, input_res, value))
  expect_identical(res, value)
  expect_match(messages[[1]], "\\[.+\\] error: RUN_FAILED")
  expect_match(messages[[2]], "\\[.+\\] error-detail: Failed to run report")
  expect_match(messages[[3]],
               "\\[.+\\] error-trace: the\\n\\[.+\\] error-trace: trace")
  expect_match(messages[[4]], "\\[.+\\] `--> 400 \\(274 bytes\\)")
})
