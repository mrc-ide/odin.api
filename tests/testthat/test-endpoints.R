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


## NOTE: for reasons that are not totally clear, the first compiled
## model seems to cost about 0.5s here, then after that they're cheap
## (0.05s).  It looks like the cost of loading a package, but no
## additional namespaces are loaded.
test_that("Compile a simple model", {
  data <- list(model = "initial(x) <- 1\nderiv(x) <- 1")
  res <- model_compile(data)
  cmp <- model_validate(data)
  expect_setequal(names(res), c(names(cmp), "model"))
  expect_identical(res[names(res) != "model"], cmp)
  expect_s3_class(res$model, "scalar")

  endpoint <- odin_api_endpoint("POST", "/compile")
  res_endpoint <- endpoint$run(data)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Failure to compile returns diagnostics", {
  data <- list(model = "initial(x) <- 1\nderiv(a) <- 1")
  res <- model_compile(data)
  cmp <- model_validate(data)
  expect_mapequal(res, cmp)

  endpoint <- odin_api_endpoint("POST", "/compile")
  res_endpoint <- endpoint$run(data)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})
