##' Run odin.api server
##'
##' @title Run odin.api server
##' @param port Port to serve on
##'
##' @param host Optional host (either `0.0.0.0` or `127.0.0.1`)
##'
##' @return Never returns
##' @export
server <- function(port, host = "0.0.0.0") {
  message("Starting odin.api server on port ", port)
  build_api()$run(host, port)
}


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
