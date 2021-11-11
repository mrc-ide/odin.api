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


##' @porcelain POST /compile => json()
##'   query pretty :: logical
##'   body data :: json()
model_compile <- function(data, pretty = FALSE) {
  result <- odin_js_validate(data$model)
  if (result$valid) {
    ## This generally needs a bit more tidyup here as we don't really
    ## want to parse the model twice, which we must currently do. Once
    ## we start applying restrictions too, the same rules should
    ## apply. So we need a version of odin_js_model that accepts ir.
    result$model <- scalar(odin_js_model(data$model, pretty))
  }
  result
}
