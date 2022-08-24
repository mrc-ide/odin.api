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
  versions <- c(list(odin = utils::packageVersion("odin"),
                     odin.api = utils::packageVersion("odin.api")),
                odin::odin_js_versions())
  lapply(versions, function(v) scalar(as.character(v)))
}


##' @porcelain POST /validate => json(validate_response)
##'   body data :: json(validate_request)
model_validate <- function(data) {
  data <- jsonlite::fromJSON(data, simplifyDataFrame = FALSE)
  odin_js_validate(data$model, data$requirements)
}


##' @porcelain POST /compile => json(compile_response)
##'   query pretty :: logical
##'   body data :: json(compile_request)
model_compile <- function(data, pretty = FALSE) {
  data <- jsonlite::fromJSON(data, simplifyDataFrame = FALSE)
  result <- odin_js_validate(data$model, data$requirements)
  if (result$valid) {
    code <- odin_js_model(data$model)
    result$model <- scalar(prepare_code(code, pretty))
  }
  result
}


##' @porcelain GET /support/runner-ode => json
support_runner_ode <- function() {
  code <- odin::odin_js_bundle(NULL, include_support = TRUE)$support
  ## We add "odinjs;" after the code here so that a JS `eval()` around
  ## it returns the object.
  scalar(paste0(code, "odinjs;"))
}
