`%||%` <- function(a, b) { # nolint
  if (is.null(a)) b else a
}


scalar <- function(x) {
  jsonlite::unbox(x)
}


vcapply <- function(X, FUN, ...) { # nolint
  vapply(X, FUN, character(1), ...)
}
