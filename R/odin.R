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
    err <- result$error
    if (inherits(err, "odin_error")) {
      err <- result$error
    } else {
      ## Most likely this is a parse error, and I don't see anything
      ## that makes this easy to get from R, unfortunately. Have a
      ## look at R's src/main/source.c for the code here for the
      ## options. It's important to strip off the context otherwise
      ## things get a bit weird.
      err <- parse_parse_error(result$error$message)
    }
    return(list(valid = scalar(FALSE),
                error = odin_error_detail(err$msg, err$line)))
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


odin_error_detail <- function(msg, line) {
  list(message = scalar(msg),
       line = line)
}



## The patterns that things might confirm to are
##
## (file):(line):(column): (message)
##
## or that, followed by one or two lines of context:
##
## (line): (code)
##
## followed by a pointer to the error using "^"
##
## for example:
##
## <text>:4:0: unexpected end of input
## 2: z <- 2
## 3: x <
##   ^
##
## We assume the filename '<text>' here because that is what R uses
## when asked to parse a string.
##
## Naturally, this relies on lots of undocumented behaviour!
parse_parse_error <- function(msg) {
  re <- "^<text>:([0-9]+):[0-9]+: (.*?)(\n[0-9]+:.*)*$"
  line <- integer(0)

  if (grepl(re, msg)) {
    line <- as.integer(sub(re, "\\1", msg))
    msg <- sub(re, "\\2", msg)
  }

  list(msg = msg, line = line)
}
