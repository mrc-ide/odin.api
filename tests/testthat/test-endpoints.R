test_that("root data returns sensible, validated, data", {
  ## Just hello world for the package really
  endpoint <- odin_api_endpoint("GET", "/")
  res <- endpoint$run()
  expect_true(res$validated)
  expect_true(all(c("odin", "odin.api", "odinjs", "dopri", "dfoptim") %in%
                  names(res$data)))
  expect_match(unlist(res$data), "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})


test_that("Can construct the api", {
  obj <- api()
  result <- evaluate_promise(value <- obj$request("GET", "/")$status)
  expect_equal(value, 200)
  logs <- lapply(strsplit(result$output, "\n")[[1]], jsonlite::parse_json)
  expect_length(logs, 2)
  expect_equal(logs[[1]]$logger, "odin.api")
})


test_that("Validate model", {
  data <- list(model = "initial(x) <- 1\nderiv(x) <- 1")
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_validate(json)
  expect_setequal(names(res), c("valid", "metadata"))
  expect_true(res$valid)
  expect_setequal(names(res$metadata), c("variables", "parameters", "messages"))
  expect_equal(res$metadata$variables, "x")
  expect_equal(res$metadata$parameters, list())
  expect_equal(res$metadata$messages, list())

  endpoint <- odin_api_endpoint("POST", "/validate")
  res_endpoint <- endpoint$run(json)
  expect_true(res_endpoint$validated)

  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Validate reports unused variables", {
  data <- list(model = "initial(x) <- 1\nderiv(x) <- 1\na <- 1")
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_validate(json)
  expect_true(res$valid)

  expect_equal(res$metadata$variables, "x")
  expect_length(res$metadata$messages, 1)
  expect_equal(res$metadata$messages[[1]]$message,
               scalar("Unused equation: a"))
  expect_equal(res$metadata$messages[[1]]$line, 3)

  endpoint <- odin_api_endpoint("POST", "/validate")
  res_endpoint <- endpoint$run(json)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Validate rejects invalid model", {
  data <- list(model = "initial(x) <- 1\nderiv(y) <- 1")
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_validate(json)
  expect_setequal(names(res), c("valid", "error"))
  expect_false(res$valid)
  expect_setequal(names(res$error), c("message", "line"))
  expect_match(res$error$message, "must contain same set of equations")
  expect_equal(res$error$line, c(1, 2))

  ## NOTE: not a failure
  endpoint <- odin_api_endpoint("POST", "/validate")
  res_endpoint <- endpoint$run(json)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Validate rejects discrete time model", {
  data <- list(model = "initial(x) <- 1\nupdate(x) <- 1",
               requirements = list(timeType = "continuous"))
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_validate(json)
  expect_setequal(names(res), c("valid", "error"))
  expect_false(res$valid)
  expect_setequal(names(res$error), c("message", "line"))
  expect_match(
    res$error$message,
    "Expected a continuous time model (using deriv, not update)",
    fixed = TRUE)
  expect_equal(res$error$line, 2)
})


test_that("Validate won't accept model where requirements disagree", {
  data <- list(model = "initial(x) <- 1\nupdate(x) <- 1",
               requirements = list(timeType = "continuous"))
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_validate(json)
  expect_setequal(names(res), c("valid", "error"))
  expect_false(res$valid)
  expect_setequal(names(res$error), c("message", "line"))
  expect_match(
    res$error$message,
     "Expected a continuous time model (using deriv, not update)",
    fixed = TRUE)
  expect_equal(res$error$line, 2)
})


test_that("Validate sensibly reports on syntax error", {
  data <- list(model = "initial(x) <- 1\nderiv(y)) <- 1")
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_validate(json)
  expect_setequal(names(res), c("valid", "error"))
  expect_false(res$valid)
  expect_setequal(names(res$error), c("message", "line"))

  expect_match(res$error$message, "unexpected")
  expect_equal(res$error$line, 2)

  ## NOTE: not a failure
  endpoint <- odin_api_endpoint("POST", "/validate")
  res_endpoint <- endpoint$run(json)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Return information about user parameters", {
  data <- list(model = "initial(x) <- 1\nderiv(x) <- a\na <- user(1.2)")
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_validate(json)

  expect_type(res$metadata$parameters, "list")
  expect_length(res$metadata$parameters, 1)
  p <- res$metadata$parameters[[1]]
  expect_equal(p$name, scalar("a"))
  expect_equal(p$default, scalar(1.2))
  expect_equal(p$min, scalar(NA))
  expect_equal(p$max, scalar(NA))
  expect_equal(p$is_integer, scalar(FALSE))
  expect_equal(p$rank, scalar(0L))

  endpoint <- odin_api_endpoint("POST", "/validate")
  res_endpoint <- endpoint$run(json)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Compile a simple model", {
  data <- list(model = "initial(x) <- 1\nderiv(x) <- 1")
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_compile(json)
  cmp <- model_validate(json)
  expect_setequal(names(res), c(names(cmp), "model"))
  expect_identical(res[names(res) != "model"], cmp)
  expect_s3_class(res$model, "scalar")

  endpoint <- odin_api_endpoint("POST", "/compile")
  res_endpoint <- endpoint$run(json)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Failure to compile returns diagnostics", {
  data <- list(model = "initial(x) <- 1\nderiv(a) <- 1")
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_compile(json)
  cmp <- model_validate(json)
  expect_mapequal(res, cmp)

  endpoint <- odin_api_endpoint("POST", "/compile")
  res_endpoint <- endpoint$run(json)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Accept a character array", {
  data <- list(model = c("initial(x) <- 1", "deriv(x) <- 1"))
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_compile(json)

  endpoint <- odin_api_endpoint("POST", "/compile")
  res_endpoint <- endpoint$run(json)

  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Compile a stochastic model", {
  data <- list(model = "initial(x) <- 1\nupdate(x) <- x + norm_rand()",
               requirements = list(timeType = "discrete"))
  json <- jsonlite::toJSON(data, auto_unbox = TRUE)

  res <- model_compile(json)
  cmp <- model_validate(json)
  expect_setequal(names(res), c(names(cmp), "model"))
  expect_identical(res[names(res) != "model"], cmp)
  expect_s3_class(res$model, "scalar")

  endpoint <- odin_api_endpoint("POST", "/compile")
  res_endpoint <- endpoint$run(json)
  expect_true(res_endpoint$validated)
  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$data, res)
})


test_that("Can generate support code", {
  res <- support_runner_ode()
  expect_true(js::js_validate_script(res))

  endpoint <- odin_api_endpoint("GET", "/support/runner-ode")
  res_endpoint <- endpoint$run()

  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$content_type, "application/json")
  expect_equal(res_endpoint$data, res)
})


test_that("Can generate support code", {
  res <- support_runner_discrete()
  expect_true(js::js_validate_script(res))

  endpoint <- odin_api_endpoint("GET", "/support/runner-discrete")
  res_endpoint <- endpoint$run()

  expect_equal(res_endpoint$status_code, 200)
  expect_equal(res_endpoint$content_type, "application/json")
  expect_equal(res_endpoint$data, res)
})
