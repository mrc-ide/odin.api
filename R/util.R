`%||%` <- function(x, y) { # nolint
  if (is.null(x)) y else x
}


scalar <- function(x) {
  jsonlite::unbox(x)
}


package_version_string <- function(name) {
  as.character(utils::packageVersion(name))
}
