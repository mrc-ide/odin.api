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
  ## TODO: Possibly we should do the policing of allowable features
  ## here, as that would allow us to map it down to the first line
  ## that it was used on.
  options <- odin::odin_options(target = "js")
  result <- odin::odin_validate(data$model, "text", options)

  if (result$success) {
    ## We might want an even faster version of this that just
    ## literally does "are we ok"?  It'll be ok so long as the server
    ## throttles correctly though.
    dat <- odin::odin_ir_deserialise(result$result)
    messages <- lapply(result$messages, function(m)
      list(message = scalar(m$msg), line = m$line))
    list(valid = scalar(TRUE),
         variables = names(dat$data$variable$contents),
         messages = messages)
  } else {
    list(valid = scalar(FALSE),
         error = list(message = scalar(result$error$msg),
                      line = result$error$line))
  }
}
