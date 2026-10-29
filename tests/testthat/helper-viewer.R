# A stand-in for the web page the viewer driver serves. Page-side actions
# (connect, type, resize, close) are queued and happen during the driver's
# next service() call, the way websocket messages arrive in the real loop.
FakeViewerTransport <- R6::R6Class(
  "FakeViewerTransport",
  public = list(
    sent = character(),
    opened = NULL,
    stopped = FALSE,
    # service() calls that found nothing to do; guards tests against hangs.
    idle_calls = 0L,
    max_idle_calls = 200L,

    start = function(on_open, on_message, on_close) {
      private$handlers <- list(open = on_open, message = on_message, close = on_close)
      "http://127.0.0.1:4321/"
    },
    send = function(message) {
      if (private$connected) self$sent <- c(self$sent, message)
      invisible(self)
    },
    service = function(timeout) {
      actions <- private$inbox
      private$inbox <- list()
      if (!length(actions)) {
        self$idle_calls <- self$idle_calls + 1L
        if (self$idle_calls > self$max_idle_calls) stop("FakeViewerTransport: no page activity left.", call. = FALSE)
      }
      for (action in actions) action()
      invisible(self)
    },
    stop = function() {
      self$stopped <- TRUE
      invisible(self)
    },

    # Page side.
    connect = function(cols = 80L, rows = 24L) {
      private$queue(function() {
        private$connected <- TRUE
        private$handlers$open()
      })
      self$resize(cols, rows)
    },
    resize = function(cols, rows) private$queue(function() private$handlers$message(sprintf("r%d,%d", cols, rows))),
    type = function(data) private$queue(function() private$handlers$message(paste0("i", data))),
    close = function() {
      private$queue(function() {
        private$connected <- FALSE
        private$handlers$close()
      })
    },
    output = function() paste(substring(grep("^o", self$sent, value = TRUE), 2L), collapse = "")
  ),
  private = list(
    handlers = NULL,
    inbox = list(),
    connected = FALSE,
    queue = function(action) {
      private$inbox[[length(private$inbox) + 1L]] <- action
      invisible(self)
    }
  )
)

viewer_with <- function(cols = 80L, rows = 24L, connect = TRUE) {
  transport <- FakeViewerTransport$new()
  opened <- character()
  driver <- ViewerDriver$new(transport = transport, open = function(url) opened <<- c(opened, url))
  if (connect) transport$connect(cols, rows)
  list(driver = driver, transport = transport, opened = function() opened)
}
