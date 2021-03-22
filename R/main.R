main <- function(args = commandArgs(TRUE)) {
  args <- main_args(args)
  do.call("server", args)
}


main_args <- function(args) {
  doc <- "Usage:
  odin.api [options]

Options:
  --port=PORT   Port to run on [default: 8321]
  --host=HOST   IP address owned by this server [default: 0.0.0.0]"
  res <- docopt::docopt(doc, args)

  list(port = as.integer(res[["port"]]),
       host = res[["host"]])
}


write_script <- function(path, versioned = FALSE) {
  dir.create(path, FALSE, TRUE)
  rscript <- "/usr/bin/env Rscript"
  code <- c(sprintf("#!%s", rscript), "odin.api:::main()")
  path_bin <- file.path(path, "odin.api")
  writeLines(code, path_bin)
  Sys.chmod(path_bin, "755")
  invisible(path_bin)
}
