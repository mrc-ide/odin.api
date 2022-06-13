## See reside-266, might move this into porcelain
make_logger <- function(log_level) {
  ## porcelain::porcelain_logger(log_level)
  logger <- lgr::get_logger("odin.api", reset = TRUE)
  logger$set_propagate(FALSE)
  logger$set_threshold(log_level)
  appender <- lgr::AppenderConsole$new(layout = lgr::LayoutJson$new())
  logger$add_appender(appender, name = "json")
  logger
}
