# Viewer driver --------------------------------------------------------------

# Runs an app in a web page -- the RStudio or Positron Viewer pane, or a
# browser -- when R has no terminal. The page runs xterm.js, so the renderer's
# ANSI output is sent unchanged and the page's key, mouse and paste input is
# parsed by the same KeyParser as the POSIX driver.
#
# Websocket text messages start with a one-letter type:
#   page -> R:  "i<data>"         terminal input
#               "r<cols>,<rows>"  the terminal's size
#   R -> page:  "o<text>"         output to write
#               "x"               the app has exited
#
# The transport (httpuv by default) is injected so the driver can be tested
# with a fake page.
ViewerDriver <- R6::R6Class(
  "ViewerDriver",
  inherit = TerminalDriver,
  public = list(
    # Seconds start() waits for the page to connect and report its size.
    connect_timeout = 30,
    # Seconds the app keeps running after the page closes, so a reload (or
    # the Viewer pane being moved) can reconnect.
    disconnect_timeout = 10,
    url = NULL,

    initialize = function(transport = NULL, open = viewer_open, color_mode = "truecolor") {
      self$color_mode <- color_mode
      self$capabilities <- viewer_capabilities(color_mode)
      private$transport <- transport %||% HttpuvTransport$new()
      private$open <- open
      private$parser <- KeyParser$new()
    },

    start = function() {
      if (self$started) return(invisible(self))
      self$url <- private$transport$start(
        on_open = function() private$on_open(),
        on_message = function(message) private$on_message(message),
        on_close = function() private$on_close()
      )
      self$started <- TRUE
      private$open(self$url)
      deadline <- now_seconds() + self$connect_timeout
      while (is.null(private$page_size)) {
        if (now_seconds() >= deadline) {
          self$stop()
          stop("The termr viewer page did not connect. Open ", self$url, " in a browser to run the app there.",
               call. = FALSE)
        }
        private$transport$service(0.05)
      }
      private$ready <- TRUE
      invisible(self)
    },

    stop = function() {
      if (!self$started) return(invisible(self))
      self$started <- FALSE
      private$ready <- FALSE
      try({
        self$write(self$teardown_sequence())
        private$transport$send("x")
        # Give the transport a moment to deliver the last messages.
        private$transport$service(0.05)
      }, silent = TRUE)
      try(private$transport$stop(), silent = TRUE)
      invisible(self)
    },

    write = function(text) {
      private$transport$send(paste0("o", enc2utf8(text)))
      invisible(self)
    },

    size = function() private$page_size %||% c(width = 80L, height = 24L),

    read_events = function(timeout = 0) {
      # Input that arrived while connecting is handled before more is read.
      if (!length(private$queue)) private$transport$service(min(timeout, 0.5))
      if (is.null(private$closed_at) || now_seconds() - private$closed_at < self$disconnect_timeout) {
        events <- private$queue
        private$queue <- list()
        return(events)
      }
      stop(structure(
        class = c("termr_page_closed", "error", "condition"),
        list(message = "The termr viewer page was closed.", call = NULL)
      ))
    }
  ),
  private = list(
    transport = NULL,
    open = NULL,
    parser = NULL,
    queue = list(),
    page_size = NULL,
    ready = FALSE,
    closed_at = NULL,

    push = function(events) {
      private$queue <- c(private$queue, events)
    },

    on_open = function() {
      private$closed_at <- NULL
      self$write(self$setup_sequence())
    },

    on_close = function() {
      private$closed_at <- now_seconds()
    },

    on_message = function(message) {
      message <- enc2utf8(message)
      type <- substr(message, 1L, 1L)
      body <- substring(message, 2L)
      if (identical(type, "i")) {
        events <- private$parser$feed(body)
        # xterm.js sends each key sequence whole, so anything left over is
        # a lone Escape rather than the start of a longer sequence.
        if (private$parser$has_pending()) events <- c(events, private$parser$flush())
        private$push(events)
      } else if (identical(type, "r")) {
        dims <- suppressWarnings(as.integer(strsplit(body, ",", fixed = TRUE)[[1]]))
        if (length(dims) != 2L || anyNA(dims) || any(dims < 1L)) return(invisible())
        private$page_size <- c(width = dims[[1]], height = dims[[2]])
        # Sent on every (re)connect as well: a reloaded page is blank, and a
        # ResizeEvent makes the app repaint everything.
        if (private$ready) private$push(list(ResizeEvent$new(dims[[1]], dims[[2]])))
      }
      invisible()
    }
  )
)

viewer_capabilities <- function(color_mode = "truecolor") {
  terminal_capabilities(
    env = c(TERM = "xterm-256color"), windows = FALSE,
    overrides = list(colors = color_mode, truecolor = identical(color_mode, "truecolor"), unicode = TRUE,
                     synchronized_output = FALSE, hyperlinks = FALSE, osc52 = FALSE)
  )
}

# Can apps fall back to the viewer when there is no terminal?
viewer_available <- function() {
  if (isFALSE(getOption("termr.viewer"))) return(FALSE)
  interactive() && requireNamespace("httpuv", quietly = TRUE)
}

# The IDE's Viewer pane when there is one (RStudio and Positron set the
# `viewer` option), else the default browser.
viewer_open <- function(url) {
  viewer <- getOption("viewer")
  if (is.function(viewer)) viewer(url) else utils::browseURL(url)
  invisible(url)
}

viewer_assets <- c(
  "index.html" = "text/html; charset=utf-8",
  "termr-viewer.js" = "application/javascript",
  "xterm.js" = "application/javascript",
  "addon-fit.js" = "application/javascript",
  "xterm.css" = "text/css"
)

# An httpuv response for a request path. Only the page's own files are
# served; they are matched by file name so the page also works behind the
# path prefix RStudio Server and Workbench add.
viewer_serve <- function(path) {
  name <- if (grepl("/$", path) || !nzchar(path)) "index.html" else basename(path)
  if (grepl("/\\.\\.(/|$)", path) || !name %in% names(viewer_assets)) {
    return(list(status = 404L, headers = list("Content-Type" = "text/plain"), body = "Not found"))
  }
  file <- system.file("www", "viewer", name, package = "termr")
  list(
    status = 200L,
    headers = list("Content-Type" = viewer_assets[[name]], "Cache-Control" = "no-store"),
    body = readBin(file, "raw", file.size(file))
  )
}

# Serves the viewer page and its websocket with httpuv. One page is connected
# at a time; a new connection (a reload) replaces the previous one.
HttpuvTransport <- R6::R6Class(
  "HttpuvTransport",
  public = list(
    host = "127.0.0.1",
    port = NULL,

    start = function(on_open, on_message, on_close) {
      if (!requireNamespace("httpuv", quietly = TRUE)) {
        stop("Running a termr app in the viewer needs the httpuv package.", call. = FALSE)
      }
      self$port <- httpuv::randomPort(host = self$host)
      private$server <- httpuv::startServer(self$host, self$port, list(
        call = function(req) viewer_serve(req$PATH_INFO),
        onWSOpen = function(ws) {
          if (!is.null(private$ws)) try(private$ws$close(), silent = TRUE)
          private$ws <- ws
          current <- function() identical(private$ws, ws)
          ws$onMessage(function(binary, message) {
            if (current()) on_message(if (binary) rawToChar(message) else message)
          })
          ws$onClose(function() {
            if (current()) {
              private$ws <- NULL
              on_close()
            }
          })
          on_open()
        }
      ))
      sprintf("http://%s:%d/", self$host, self$port)
    },

    send = function(message) {
      if (!is.null(private$ws)) private$ws$send(message)
      invisible(self)
    },

    service = function(timeout) {
      viewer_poll(timeout)
      invisible(self)
    },

    stop = function() {
      if (!is.null(private$ws)) try(private$ws$close(), silent = TRUE)
      private$ws <- NULL
      if (!is.null(private$server)) private$server$stop()
      private$server <- NULL
      invisible(self)
    }
  ),
  private = list(server = NULL, ws = NULL)
)

# Runs httpuv's due callbacks, waiting up to `timeout` seconds for one.
# Not httpuv::service(): with a timeout of 0 it serves until interrupted.
viewer_poll <- function(timeout) {
  later::run_now(max(0, timeout), all = TRUE)
}
