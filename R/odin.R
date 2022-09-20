odin_js_model <- function(code) {
  model <- odin::odin_js_bundle(code, include_support = FALSE)$model
  c('"use strict";',
    model$code,
    sprintf("%s;", model$name))
}


odin_js_validate <- function(code, requirements) {
  options <- odin::odin_options(target = "js")
  result <- odin::odin_validate(code, "text", options)
  if (result$success) {
    result$result <- odin::odin_ir_deserialise(result$result)
    result <- check_requirements(result, requirements)
  }

  if (!result$success) {
    if (inherits(result$error, "odin_error")) {
      msg <- result$error$msg
      line <- result$error$line
    } else {
      ## Can't easily get line information at this point,
      ## unfortunately, though this is almost certainly a parse error.
      msg <- result$error$message
      line <- integer(0)
    }
    return(list(valid = scalar(FALSE),
                error = list(message = scalar(msg), line = line)))
  }

  dat <- result$result
  messages <- lapply(result$messages, function(m)
    list(message = scalar(m$msg), line = m$line))

  variables <- c(names(dat$data$variable$contents),
                 names(dat$data$output$contents))

  process_user <- function(nm) {
    x <- dat$equations[[nm]]$user
    list(name = scalar(nm),
         default = scalar(x$default %||% NA),
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
}


check_requirements <- function(result, requirements) {
  if (is.null(requirements)) {
    requirements <- list(timeType = "continuous")
  }

  ## This is the error we'd get if the server has asked that we check
  ## we provide a discrete time model, regardless of what the
  ## user-provided code is. We can't do this yet. This error should
  ## never be surfaced in the app unless we've deployed incompatible
  ## versions.
  if (requirements$timeType != "continuous") {
    msg <- "Only continuous time models currently supported"
    return(odin_validate_error_value(msg, integer(0)))
  }

  dat <- result$result

  if (dat$features$discrete) {
    ## Once discrete time models are supported at all, we will also need
    ## to check that stochastic models do not use output (or
    ## interpolation?) as this is not supported in dust, even though it
    ## still is in odin itself.
    msg <- "Expected a continuous time model (using deriv, not update)"
    vars <- names(dat$data$variable$contents)
    line <- lapply(dat$equations, function(el) {
      if (el$lhs %in% vars && el$name %in% dat$components$rhs)
        el$source else NULL
    })
    return(odin_validate_error_value(msg, line))
  }
  if (dat$features$has_array) {
    ## Later, we'll check here to find out where arrays are being used
    ## as there are two separate problems:
    ##
    ## * array variables and output (difficult to plot)
    ## * array parameters (difficult to enter)
    ##
    ## We'll likely support these separately later but for now it's ok
    ## to rule both out. Once we split these we'll get better line
    ## numbers I suspect, but this should work for now.
    msg <- "Models that use arrays are not supported"
    line <- lapply(dat$equations, function(el) {
      if (el$type %in% "expression_array") el$source else NULL
    })
    return(odin_validate_error_value(msg, line))
  }

  result
}


odin_validate_error_value <- function(msg, line = integer(0)) {
  line <- sort(unlist(line, TRUE, FALSE))
  list(success = FALSE,
       result = NULL,
       error = structure(list(msg = msg, line = line), class = "odin_error"))
}


## Convert a vector of integers into a maximally grouped set of
## start/end pairs
tidy_lines <- function(lines) {
  ## The easy case:
  if (length(lines) == 1) {
    return(list(c(lines, lines)))
  }
  lines <- sort(lines)
  group <- cumsum(c(1, diff(lines)) != 1)
  unname(lapply(split(lines, group), function(x) c(x[1], x[length(x)])))
}
