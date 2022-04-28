`%||%` <- function(x, y) { # nolint
  if (is.null(x)) y else x
}


scalar <- function(x) {
  jsonlite::unbox(x)
}


package_version_string <- function(name) {
  as.character(utils::packageVersion(name))
}


uglify <- function(code) {
  ## This works for now but is slow; hopefully we can come up with
  ## some v8-hosted solution soon.
  ## > system2("uglifyjs", "--v8", stdout = TRUE, input = code)
  code
}


prepare_code <- function(code, pretty) {
  code <- paste(code, collapse = "\n")
  if (!pretty) {
    code <- uglify(code)
  }
  code
}
