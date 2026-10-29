keys_of <- function(evs) vapply(evs, function(e) if (inherits(e, "KeyEvent")) e$key else e$type, "")

test_that("a terminal problem is reported for IDE consoles and piped output", {
  expect_null(terminal_problem(gui = "X11", positron = "", stdout_tty = TRUE))
  expect_match(terminal_problem(gui = "RStudio", positron = "", stdout_tty = TRUE), "RStudio")
  expect_match(terminal_problem(gui = "X11", positron = "1", stdout_tty = TRUE), "Positron")
  expect_match(terminal_problem(gui = "X11", positron = "", stdout_tty = FALSE), "not a terminal")
})

test_that("without a terminal the app runs in the viewer when it can", {
  expect_s3_class(default_driver(problem = "no terminal", viewer = TRUE), "ViewerDriver")
  err <- tryCatch(default_driver(problem = "no terminal", viewer = FALSE), error = identity)
  expect_s3_class(err, "error")
  expect_match(conditionMessage(err), "no terminal")
  expect_match(conditionMessage(err), "httpuv")
  skip_on_os("windows")
  expect_s3_class(default_driver(problem = NULL, viewer = TRUE), "PosixDriver")
})

test_that("options(termr.viewer) forces or disables the viewer", {
  withr::local_options(termr.viewer = TRUE)
  expect_s3_class(default_driver(problem = NULL, viewer = TRUE), "ViewerDriver")
  withr::local_options(termr.viewer = FALSE)
  expect_false(viewer_available())
})

test_that("start() opens the page and waits for it to report its size", {
  x <- viewer_with(cols = 120L, rows = 40L)
  x$driver$start()
  on.exit(x$driver$stop())
  expect_identical(x$opened(), "http://127.0.0.1:4321/")
  expect_identical(x$driver$size(), c(width = 120L, height = 40L))
  expect_true(startsWith(x$transport$output(), x$driver$setup_sequence()))
})

test_that("start() fails when the page never connects", {
  x <- viewer_with(connect = FALSE)
  x$driver$connect_timeout <- 0
  expect_error(x$driver$start(), "did not connect")
  expect_true(x$transport$stopped)
})

test_that("page input becomes key, paste and mouse events", {
  x <- viewer_with()
  x$driver$start()
  on.exit(x$driver$stop())
  x$transport$type("ab")
  x$transport$type("\033[A")
  x$transport$type("\033")
  expect_identical(keys_of(x$driver$read_events(0)), c("a", "b", "up", "escape"))
  x$transport$type("\033[200~hello\033[201~")
  x$transport$type("\033[<0;3;4M")
  evs <- x$driver$read_events(0)
  expect_s3_class(evs[[1]], "PasteEvent")
  expect_identical(evs[[1]]$text, "hello")
  expect_identical(keys_of(evs[2]), "mouse.down")
  x$transport$type("é")
  expect_identical(keys_of(x$driver$read_events(0)), "é")
})

test_that("a page resize becomes a ResizeEvent", {
  x <- viewer_with()
  x$driver$start()
  on.exit(x$driver$stop())
  x$transport$resize(100L, 30L)
  evs <- x$driver$read_events(0)
  expect_length(evs, 1L)
  expect_s3_class(evs[[1]], "ResizeEvent")
  expect_identical(c(evs[[1]]$width, evs[[1]]$height), c(100L, 30L))
  expect_identical(x$driver$size(), c(width = 100L, height = 30L))
})

test_that("a reloaded page gets the setup sequence and a full repaint", {
  x <- viewer_with()
  x$driver$start()
  on.exit(x$driver$stop())
  x$transport$close()
  x$transport$connect(80L, 24L)
  x$transport$sent <- character()
  evs <- x$driver$read_events(0)
  expect_true(startsWith(x$transport$output(), x$driver$setup_sequence()))
  expect_s3_class(evs[[1]], "ResizeEvent")
})

test_that("stop() restores the page, tells it the app exited and stops serving", {
  x <- viewer_with()
  x$driver$start()
  x$driver$stop()
  expect_true(endsWith(x$transport$output(), x$driver$teardown_sequence()))
  expect_identical(utils::tail(x$transport$sent, 1L), "x")
  expect_true(x$transport$stopped)
})

test_that("an app runs end to end in the viewer", {
  x <- viewer_with(cols = 40L, rows = 5L)
  x$transport$type("q")
  hello <- app(label("Hello from the viewer"), bind("q", "quit"), mouse = FALSE)
  run(hello, driver = x$driver)
  expect_match(x$transport$output(), "Hello from the viewer", fixed = TRUE)
  expect_true(x$transport$stopped)
})

test_that("an app stops quietly when its page stays closed", {
  x <- viewer_with()
  x$driver$disconnect_timeout <- 0
  x$transport$close()
  expect_no_error(run(label("bye"), driver = x$driver))
  expect_true(x$transport$stopped)
})

test_that("the page and its assets are served, nothing else", {
  index <- viewer_serve("/")
  expect_identical(index$status, 200L)
  expect_match(index$headers[["Content-Type"]], "text/html")
  expect_match(rawToChar(index$body), "termr-viewer.js", fixed = TRUE)
  expect_identical(viewer_serve("/xterm.js")$headers[["Content-Type"]], "application/javascript")
  # Behind a proxy (RStudio Server, Workbench) the page lives under a prefix.
  expect_identical(viewer_serve("/p/58fab3e4/xterm.css")$status, 200L)
  expect_identical(viewer_serve("/../DESCRIPTION")$status, 404L)
  expect_identical(viewer_serve("/nope.js")$status, 404L)
})

test_that("the real httpuv transport carries a websocket session", {
  skip_on_cran()
  skip_if_not_installed("httpuv")
  skip_if_not_installed("websocket")
  client <- NULL
  open <- function(url) {
    client <<- websocket::WebSocket$new(paste0(sub("^http", "ws", url), "ws"), autoConnect = FALSE)
    client$onOpen(function(event) client$send("r90,20"))
    client$connect()
  }
  driver <- ViewerDriver$new(open = open)
  driver$connect_timeout <- 10
  driver$start()
  on.exit(driver$stop())
  expect_identical(driver$size(), c(width = 90L, height = 20L))
  client$send("iq")
  evs <- list()
  deadline <- Sys.time() + 5
  while (!length(evs) && Sys.time() < deadline) evs <- driver$read_events(0.05)
  expect_identical(keys_of(evs), "q")
})

test_that("polling httpuv without waiting returns at once", {
  skip_on_cran()
  skip_if_not_installed("httpuv")
  # httpuv::service(0) serves until interrupted, and nothing inside R can
  # time that out, so the poll runs in a child R process with a deadline.
  code <- c(
    paste("poll <-", paste(deparse(viewer_poll), collapse = "\n")),
    "server <- httpuv::startServer('127.0.0.1', httpuv::randomPort(), list(call = function(req) NULL))",
    "poll(0); poll(0.01)",
    "server$stop()",
    "cat('returned')"
  )
  rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
  result <- processx::run(rscript, c("-e", paste(code, collapse = "\n")), timeout = 20, error_on_status = FALSE)
  expect_false(result$timeout)
  expect_identical(result$stdout, "returned")
})

test_that("a Shiny-style app runs in the viewer", {
  x <- viewer_with(cols = 40L, rows = 6L)
  x$transport$type("Ann")
  x$transport$wait()
  x$transport$type("\003")
  ui <- fluidPage(
    textInput("name", "Name"),
    textOutput("greeting")
  )
  server <- function(input, output, session) {
    output$greeting <- renderText({ paste0("Hello, ", input$name, "!") })
  }
  run(app(ui, server = server), driver = x$driver)
  expect_match(viewer_screen(x, 40L, 6L), "Hello, Ann!", fixed = TRUE)
  expect_true(x$transport$stopped)
})
