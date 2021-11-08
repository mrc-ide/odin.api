api <- function(validate = FALSE) {
  api <- porcelain::porcelain$new(validate = validate)
  api$include_package_endpoints()
  api
}


##' @porcelain GET / => json(root)
root <- function() {
  list(odin = scalar(as.character(packageVersion("odin"))),
       odin.api = scalar(as.character(packageVersion("odin.api"))))
}
