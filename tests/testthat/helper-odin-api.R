odin_api_endpoint <- function(..., validate = TRUE) {
  ## TODO: export from porcelain!
  ## TODO: should this default be true for testing?
  porcelain:::porcelain_package_endpoint("odin.api", ..., validate = validate)
}
