test_that("root data returns sensible, validated, data", {
  ## Just hello world for the package really
  endpoint <- odin_api_endpoint("GET", "/")
  res <- endpoint$run()
  expect_true(res$validated)
  expect_setequal(names(res$data), c("odin", "odin.api"))
  expect_match(unlist(res$data), "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})


test_that("Can construct the api", {
  obj <- api()
  expect_equal(obj$request("GET", "/")$status, 200)
})


test_that("Validate model", {
  data <- list(model = "initial(x) <- 1\nderiv(x) <- 1")
  res <- model_validate(data)
  expect_setequal(names(res), c("valid", "variables", "messages"))
  expect_true(res$valid)
  expect_equal(res$variables, "x")
  expect_equal(res$messages, list())

  endpoint <- odin_api_endpoint("POST", "/validate")
  res_endpoint <- endpoint$run(data)
  expect_true(res_endpoint$validated)

  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Validate reports unused variables", {
  data <- list(model = "initial(x) <- 1\nderiv(x) <- 1\na <- 1")
  res <- model_validate(data)
  expect_setequal(names(res), c("valid", "variables", "messages"))
  expect_true(res$valid)
  expect_equal(res$variables, "x")
  expect_length(res$messages, 1)
  expect_equal(res$messages[[1]]$message,
               scalar("Unused equation: a"))
  expect_equal(res$messages[[1]]$line, 3)

  endpoint <- odin_api_endpoint("POST", "/validate")
  res_endpoint <- endpoint$run(data)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Validate rejects invalid model", {
  data <- list(model = "initial(x) <- 1\nderiv(y) <- 1")
  res <- model_validate(data)
  expect_setequal(names(res), c("valid", "error"))
  expect_false(res$valid)
  expect_setequal(names(res$error), c("message", "line"))
  expect_match(res$error$message, "must contain same set of equations")
  expect_equal(res$error$line, c(1, 2))

  ## NOTE: not a failure
  endpoint <- odin_api_endpoint("POST", "/validate")
  res_endpoint <- endpoint$run(data)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})
