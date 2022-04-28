test_that("null-or-value works", {
  expect_equal(1 %||% NULL, 1)
  expect_equal(1 %||% 2, 1)
  expect_equal(NULL %||% NULL, NULL)
  expect_equal(NULL %||% 2, 2)
})


test_that("Can uglify es6 code", {
  s <- "class a { };"
  expect_equal(uglify(s), "class a{}")
  expect_equal(prepare_code(s, TRUE), s)
  expect_equal(prepare_code(s, FALSE), "class a{}")
})
