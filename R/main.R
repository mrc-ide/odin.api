parse_main <- function(args = commandArgs(TRUE)) {
  usage <- "Usage:
odin.api [options]

Options:
  --log-level=LEVEL  Log-level (off, info, all) [default: info]
  --validate         Enable json schema validation
  --port=PORT        Port to run api on [default: 8001]"
  dat <- docopt::docopt(usage, args)
  list(log_level = dat$log_level,
       validate = dat$validate,
       port = as.integer(dat$port))
}


main <- function(args = commandArgs(TRUE)) {
  dat <- parse_main(args)
  api(dat$validate, dat$log_level)$run("0.0.0.0", port = dat$port)
}
