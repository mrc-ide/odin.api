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


read_string <- function(path) {
  ## We need 'warn = FALSE' here to prevent warnings about missing
  ## trailing newlines (which the bundled js files in odin lack due to
  ## webpack)
  paste(readLines(path, warn = FALSE), collapse = "\n")
}


system_file <- function(path, package) {
  system.file(path, package = package, mustWork = TRUE)
}


list_to_integer <- function(x) {
  vapply(x, identity, integer(1))
}
