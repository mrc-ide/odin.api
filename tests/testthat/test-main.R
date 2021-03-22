context("main")

test_that("defaults", {
  expect_mapequal(
    main_args(character(0)),
    list(port = 8321, host = "0.0.0.0"))
})


test_that("set port", {
  expect_mapequal(
    main_args(c("--port", "8888")),
    list(port = 8888, host = "0.0.0.0"))
})


test_that("set host", {
  expect_mapequal(
    main_args(c("--host", "127.0.0.1")),
    list(port = 8321, host = "127.0.0.1"))
})


test_that("write script", {
  p <- tempfile()
  res <- write_script(p)
  expect_equal(basename(res), "odin.api")
  expect_true(file.exists(res))
})
