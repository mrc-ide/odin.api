##' Create an odin.api server, a porcelain object
##'
##' @title Create odin.api
##'
##' @param validate Logical, indicating if validation should be done
##'   on responses.  This should be `FALSE` in production
##'   environments.  See [porcelain::porcelain] for details
##'
##' @param log_level Logging level to use. Sensible options are "off",
##'   "info" and "all".
##'
##' @return A [porcelain::porcelain] object. Notably this does *not*
##'   start the server
##'
##' @export
api <- function(validate = NULL, log_level = "info") {
  logger <- make_logger(log_level)
  api <- porcelain::porcelain$new(validate = validate, logger = logger)
  api$include_package_endpoints()
  api
}


##' @porcelain GET / => json(root)
root <- function() {
  list(odin = scalar(package_version_string("odin")),
       odin.api = scalar(package_version_string("odin.api")))
}


##' @porcelain POST /validate => json(validate_response)
##'   body data :: json(validate_request)
model_validate <- function(data) {
  data <- jsonlite::fromJSON(data, simplifyDataFrame = FALSE)
  odin_js_validate(data$model)
}


##' @porcelain POST /compile => json(compile_response)
##'   query pretty :: logical
##'   body data :: json(compile_request)
model_compile <- function(data, pretty = FALSE) {
  data <- jsonlite::fromJSON(data, simplifyDataFrame = FALSE)
  result <- odin_js_validate(data$model)
  if (result$valid) {
    code <- odin_js_model(data$model)
    result$model <- scalar(prepare_code(code, pretty))
  }
  result
}


##' @porcelain GET /support/dopri => json
##'   query pretty :: logical
support_dopri <- function(pretty = FALSE) {
  code <- odin::odin_js_bundle(NULL,
                               include_support = FALSE,
                               include_dopri = TRUE)$dopri
  scalar(prepare_code(code, pretty))
}

##' @porcelain GET /support/runner-ode => json
##'   query pretty :: logical
support_runner_ode <- function(pretty = FALSE) {
  code <- odin::odin_js_bundle(NULL,
                               include_support = TRUE,
                               include_dopri = FALSE)$support
  code <- c(code, "wodinRunner;")
  scalar(prepare_code(code, pretty))
}
