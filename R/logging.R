## We will migrate this to porcelain soon, with kibana-friendly output
api_log_start <- function(data, req, res) {
  api_log(sprintf("%s %s", req$REQUEST_METHOD, req$PATH_INFO))
}


api_log_end <- function(data, req, res, value) {
  if (is.raw(res$body)) {
    size <- length(res$body)
  } else {
    size <- nchar(res$body)
  }
  if (res$status >= 400 &&
      identical(res$headers[["Content-Type"]], "application/json")) {
    dat <- jsonlite::parse_json(res$body)
    for (e in dat$errors) {
      if (!is.null(e$error)) {
        api_log(sprintf("error: %s", e$error))
        api_log(sprintf("error-detail: %s", e$detail))
        if (!is.null(e$trace)) {
          trace <- sub("\n", " ", vcapply(e$trace, identity))
          api_log(sprintf("error-trace: %s", trace))
        }
      }
    }
  }
  api_log(sprintf("`--> %d (%d bytes)", res$status, size))
  value
}


api_log <- function(msg) {
  message(paste(sprintf("[%s] %s", Sys.time(), msg), collapse = "\n"))
}
