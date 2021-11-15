test_that("can run server", {
  bg <- porcelain::porcelain_background$new(api)
  bg$start()
  r <- bg$request("GET", "/")
  expect_equal(httr::status_code(r), 200)
  expect_mapequal(
    httr::content(r),
    list(status = "success",
         errors = NULL,
         data = list(odin = package_version_string("odin"),
                     odin.api = package_version_string("odin.api"))))
})
