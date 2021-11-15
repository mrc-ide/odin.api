api <- function(validate = FALSE) {
  api <- porcelain::porcelain$new(validate = validate)
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
  odin_js_validate(data$model)
}


##' @porcelain POST /compile => json(compile_response)
##'   query pretty :: logical
##'   body data :: json(compile_request)
model_compile <- function(data, pretty = FALSE) {
  result <- odin_js_validate(data$model)
  if (result$valid) {
    result$model <- scalar(odin_js_model(data$model, pretty))
  }
  result
}
