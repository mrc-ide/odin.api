build_api <- function(validate = NULL) {
  api <- porcelain::porcelain$new(validate = validate)
  api$handle(endpoint_root())
  api
}


schema_root <- function() {
  system.file("schema", package = "odin.api", mustWork = TRUE)
}


returning_json <- function(schema) {
  porcelain::porcelain_returning_json(schema, schema_root())
}


endpoint_root <- function() {
  porcelain::porcelain_endpoint$new(
    "GET", "/", target_root,
    returning = returning_json("Root.schema"))
}


target_root <- function() {
  pkgs <- c("odin", "odin.js", "odin.api")
  version <- lapply(pkgs, function(p)
    scalar(as.character(utils::packageVersion(p))))
  names(version) <- pkgs
  list(
    name = scalar("odin.api"),
    version = version)
}
