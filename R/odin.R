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

  dt <- NULL
  if (dat$features$discrete) {
    eq <- dat$equations$dt
    if (is.null(eq)) {
      dt <- scalar(1)
    } else {
      ## TODO: later we can relax this to allow simple expressions, or
      ## even dependencies only on things available at compile time,
      ## or from user variables, but we don't need that at the moment
      ## so just going with the easiest form:
      if (eq$type != "expression_scalar" || !is.numeric(eq$rhs$value)) {
        msg <- "'dt' must be a simple numeric expression, if present"
        return(list(valid = scalar(FALSE),
                    error = odin_error_detail(msg,
                                              list_to_integer(eq$source))))
      }
      dt <- scalar(eval(eq$rhs$value, baseenv()))
    }
  }

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
         dt = dt,
         messages = messages))
}


check_requirements <- function(result, requirements) {
  requirements <- validate_requirements(requirements)

  dat <- result$result
  is_discrete <- dat$features$discrete
  model_time_type <- if (is_discrete) "discrete" else "continuous"
  if (model_time_type != requirements$timeType) {
    using <- list(continuous = "deriv", discrete = "update")
    msg <- sprintf("Expected a %s time model (using %s, not %s)",
                   requirements$timeType,
                   using[[requirements$timeType]],
                   using[[model_time_type]])
    vars <- names(dat$data$variable$contents)
    line <- lapply(dat$equations, function(el) {
      if (el$lhs %in% vars && el$name %in% dat$components$rhs)
        el$source else NULL
    })
    return(odin_validate_error_value(msg, line))
  }

  if (is_discrete && dat$features$has_output) {
    msg <- "output() is not supported in discrete time models"
    output <- names(dat$data$output$contents)
    line <- lapply(dat$equations, function(el) {
      if (el$lhs %in% output) el$source else NULL
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
       line = line %||% integer(0))
}


## The patterns that things might conform to are
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


## this bit validates the request, not the model
validate_requirements <- function(requirements) {
  if (is.null(requirements)) {
    requirements <- list()
  }
  ## Default to continuous time:
  requirements$timeType <- requirements$timeType %||% "continuous"

  time_type_valid <- c("continuous", "discrete")
  if (!(requirements$timeType %in% time_type_valid)) {
    porcelain::porcelain_stop(
      sprintf("Unexpected value '%s' for timeType", requirements$timeType),
      status_code = 400)
  }

  requirements
}
