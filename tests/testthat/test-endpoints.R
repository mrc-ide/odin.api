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
  expect_equal(obj$request("GET", "/")$status_code, 200)
})
