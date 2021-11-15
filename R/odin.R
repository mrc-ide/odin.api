## Looks like some support here is needed in odin, though very little
## to make this work.
odin_js_model <- function(code, pretty) {
  model <- odin::odin_js_bundle(code, include_dopri = FALSE)
  if (!pretty) {
    model <- js::uglify_reformat(model)
  }
  model
}


odin_js_validate <- function(code) {
  options <- odin::odin_options(target = "js")
  result <- odin::odin_validate(code, "text", options)

  if (result$success) {
    dat <- odin::odin_ir_deserialise(result$result)
    messages <- lapply(result$messages, function(m)
      list(message = scalar(m$msg), line = m$line))

    variables <- c(names(dat$data$variable$contents),
                   names(dat$data$output$contents))

    process_user <- function(nm) {
      x <- dat$equations[[nm]]$user
      list(default = scalar(x$default %||% NA),
           min = scalar(x$min %||% NA),
           max = scalar(x$max %||% NA),
           is_integer = scalar(x$integer %||% FALSE),
           rank = scalar(dat$data$elements[[nm]]$rank))
    }
    parameters <- lapply(names(dat$user), process_user)

    list(valid = scalar(TRUE),
         metadata = list(
           variables = variables,
           parameters = parameters,
           messages = messages))
  } else {
    list(valid = scalar(FALSE),
         error = list(message = scalar(result$error$msg),
                      line = result$error$line))
  }
}