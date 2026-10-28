# Shiny-style constructors ----------------------------------------------------

test_that("textInput creates an Input with the id on the control and a label above", {
  w <- textInput("name", "Your name", value = "Ada", placeholder = "type")
  expect_true(inherits(w, "Vertical"))
  ctrl <- w$query_one("#name")
  expect_true(inherits(ctrl, "Input"))
  expect_identical(ctrl$value, "Ada")
  expect_identical(ctrl$placeholder, "type")
  lines <- strip_ansi(render_lines(w, 20, 4))
  expect_match(lines[[1]], "Your name")
})

test_that("textInput without a label returns the bare control", {
  w <- textInput("name")
  expect_true(inherits(w, "Input"))
  expect_identical(w$id, "name")
})

test_that("passwordInput hides characters", {
  w <- passwordInput("pw", value = "secret")
  expect_true(inherits(w, "Input"))
  expect_true(w$password)
})

test_that("textAreaInput creates a TextArea with optional rows", {
  w <- textAreaInput("notes", "Notes", value = "a\nb", rows = 5)
  ctrl <- w$query_one("#notes")
  expect_true(inherits(ctrl, "TextArea"))
  expect_identical(ctrl$computed_style()$height$value, 5L)
})

test_that("numericInput validates numbers within range", {
  w <- numericInput("n", value = 5, min = 1, max = 10)
  expect_true(inherits(w, "Input"))
  expect_identical(w$value, "5")
  expect_true(w$valid)
  w$value <- "abc"
  expect_false(w$valid)
  w$value <- "11"
  expect_false(w$valid)
  w$value <- "7"
  expect_true(w$valid)
})

test_that("checkboxInput and actionButton map ids and labels", {
  cb <- checkboxInput("logs", "Enable logs", value = TRUE)
  expect_true(inherits(cb, "Checkbox"))
  expect_identical(cb$id, "logs")
  expect_true(cb$value)
  b <- actionButton("go", "Go!")
  expect_true(inherits(b, "Button"))
  expect_identical(b$id, "go")
  expect_identical(b$label, "Go!")
})

test_that("selectInput uses names as labels and selects the first choice by default", {
  w <- selectInput("fmt", "Format", c("Comma separated" = "csv", "JSON" = "json"))
  ctrl <- w$query_one("#fmt")
  expect_true(inherits(ctrl, "Select"))
  expect_identical(ctrl$value, "csv")
  w2 <- selectInput("fmt", NULL, c("a", "b"), selected = "b")
  expect_identical(w2$value, "b")
})

test_that("radioButtons builds a radio set from a (named) vector", {
  w <- radioButtons("fmt", "Format", c("Comma separated" = "csv", "JSON" = "json"), selected = "json")
  ctrl <- w$query_one("#fmt")
  expect_true(inherits(ctrl, "RadioSet"))
  expect_identical(ctrl$value, "json")
  expect_identical(vapply(ctrl$children, function(k) k$label, ""), c("Comma separated", "JSON"))
  w2 <- radioButtons("x", NULL, c("a", "b"))
  expect_identical(w2$value, "a")
})

# observeEvent ----------------------------------------------------------------

test_that("observeEvent on a selector fires on the widget's primary event", {
  seen <- list()
  a <- app(
    actionButton("go", "Go"),
    textInput("name"),
    observeEvent("#go", function(event, app) seen$go <<- c(seen$go, event$type)),
    observeEvent("#name", function(event, app) seen$name <<- c(seen$name, event$data$value))
  )
  pilot <- test_app(a, 30, 6)
  pilot$press("enter")
  pilot$focus("#name")
  pilot$type("ab")
  pilot$press("enter")
  expect_identical(seen$go, "button.pressed")
  expect_identical(seen$name, c("a", "ab"))
  pilot$stop()
})

test_that("observeEvent accepts a braced expression with event and app available", {
  got <- NULL
  a <- app(
    actionButton("go", "Go"),
    observeEvent("#go", {
      got <<- list(label = event$data$label, is_app = inherits(app, "App"))
    })
  )
  pilot <- test_app(a, 30, 3)
  pilot$press("enter")
  expect_identical(got, list(label = "Go", is_app = TRUE))
  pilot$stop()
})

test_that("observeEvent can target a widget object and override the event type", {
  go <- actionButton("go", "Go")
  name <- textInput("name")
  submitted <- character()
  pressed <- 0L
  a <- app(
    go, name,
    observeEvent(go, pressed <<- pressed + 1L),
    observeEvent(name, submitted <<- c(submitted, event$data$value), event = "input.submitted")
  )
  pilot <- test_app(a, 30, 6)
  pilot$press("enter")
  pilot$focus("#name")
  pilot$type("ab")
  expect_identical(submitted, character())
  pilot$press("enter")
  expect_identical(submitted, "ab")
  expect_identical(pressed, 1L)
  pilot$stop()
})

test_that("observeEvent(once = TRUE) runs the handler a single time", {
  n <- 0L
  a <- app(actionButton("go", "Go"), observeEvent("#go", n <<- n + 1L, once = TRUE))
  pilot <- test_app(a, 30, 3)
  pilot$press("enter", "enter", "enter")
  expect_identical(n, 1L)
  pilot$stop()
})

test_that("observeEvent on a signal skips the initial value and passes the new value", {
  count <- signal(0L)
  seen <- integer()
  h <- observeEvent(count, seen <<- c(seen, value))
  expect_identical(seen, integer())
  count(1L)
  count(2L)
  expect_identical(seen, c(1L, 2L))
  dispose(h)
  count(3L)
  expect_identical(seen, c(1L, 2L))
})

test_that("observeEvent on a signal honours ignoreInit, ignoreNULL and once", {
  x <- signal("a")
  seen <- character()
  observeEvent(x, seen <<- c(seen, value), ignoreInit = FALSE)
  expect_identical(seen, "a")
  x(NULL)
  expect_identical(seen, "a")
  x("b")
  expect_identical(seen, c("a", "b"))

  y <- signal(NULL)
  n <- 0L
  observeEvent(y, n <<- n + 1L, ignoreNULL = FALSE)
  y(NULL)
  expect_identical(n, 0L)
  y(1)
  y(NULL)
  expect_identical(n, 2L)

  z <- signal(0)
  m <- 0L
  observeEvent(z, m <<- m + 1L, once = TRUE)
  z(1); z(2)
  expect_identical(m, 1L)
})

test_that("observeEvent on a signal can be listed in app() and sees the running app", {
  count <- signal(0L)
  app_seen <- NULL
  a <- app(
    label(function() paste("Count:", count())),
    actionButton("go", "Go"),
    observeEvent("#go", count(count() + 1L)),
    observeEvent(count, app_seen <<- app)
  )
  pilot <- test_app(a, 30, 4)
  pilot$press("enter")
  expect_identical(app_seen, a)
  expect_match(pilot$screen_text()[[1]], "Count: 1")
  pilot$stop()
})

test_that("observeEvent on a widget without a primary event fires on any of its messages", {
  Pinger <- widget("Pinger", render = function(self) "ping", focusable = TRUE,
                   bindings = list(bind("p", "ping")),
                   actions = list(ping = function(self) self$post_message("pinger.pinged", list())))
  types <- character()
  a <- app(Pinger(id = "p"), observeEvent("#p", types <<- c(types, event$type)))
  pilot <- test_app(a, 20, 3)
  pilot$press("p")
  expect_identical(types, "pinger.pinged")
  pilot$stop()
})

test_that("observeEvent rejects unsupported targets and non-handlers", {
  expect_error(observeEvent(42, NULL), "selector")
  expect_error(observeEvent("#x"), "handler")
})

# ui / server split -----------------------------------------------------------

test_that("app(ui, server) runs the server after mounting and before the first frame", {
  order <- character()
  ui <- vertical(
    textInput("name", "Name", value = "Ada"),
    actionButton("go", "Greet"),
    textOutput("out")
  )
  server <- function(input, output, session) {
    order <<- c(order, "server")
    expect_s3_class(input, "termr_input")
    expect_s3_class(output, "termr_output")
    expect_true(inherits(session, "App"))
    expect_true(session$query_one("#name")$app$running)
    output$out <- paste("Hello,", input$name)
    observeEvent(input$go, {
      output$out <- paste("Pressed by", input$name)
    })
  }
  a <- app(ui, server = server)
  expect_identical(order, character())
  pilot <- test_app(a, 40, 10)
  expect_identical(order, "server")
  expect_match(paste(pilot$screen_text(), collapse = "\n"), "Hello, Ada")
  pilot$focus("#go")
  pilot$press("enter")
  expect_identical(pilot$query_one("#out")$text, "Pressed by Ada")
  pilot$stop()
})

test_that("the server is called positionally, so session can be named app and arguments dropped", {
  seen <- NULL
  a <- app(textInput("x"), server = function(input, output, app) seen <<- app)
  pilot <- test_app(a, 20, 3)
  expect_identical(seen, a)
  pilot$stop()
  b <- app(textInput("x"), server = function(input) seen <<- input$x)
  pilot <- test_app(b, 20, 3)
  expect_identical(seen, "")
  pilot$stop()
  expect_error(app(textInput("x"), server = 42), "function")
})

test_that("server handlers are removed on shutdown so a rerun does not double-register", {
  n <- 0L
  a <- app(actionButton("go", "Go"), server = function(input, output, session) {
    observeEvent(input$go, n <<- n + 1L)
  })
  for (i in 1:2) {
    pilot <- test_app(a, 20, 3)
    pilot$press("enter")
    pilot$stop()
  }
  expect_identical(n, 2L)
})

test_that("observeEvent(once = TRUE) and signal watchers work inside a server", {
  count <- signal(0L)
  pressed <- 0L
  seen <- integer()
  a <- app(actionButton("go", "Go"), textOutput("out"), server = function(input, output, session) {
    observeEvent(input$go, pressed <<- pressed + 1L, once = TRUE)
    observeEvent(input$go, count(count() + 1L))
    observeEvent(count, {
      seen <<- c(seen, value)
      output$out <- paste("Count:", value)
    })
  })
  pilot <- test_app(a, 20, 3)
  pilot$press("enter", "enter")
  expect_identical(pressed, 1L)
  expect_identical(seen, c(1L, 2L))
  expect_identical(pilot$query_one("#out")$text, "Count: 2")
  pilot$stop()
  # The signal watcher registered by the server is disposed with the app.
  count(3L)
  expect_identical(seen, c(1L, 2L))
})

test_that("input reads values by id and output writes the natural field", {
  a <- app(
    textInput("name", value = "Ada"),
    checkboxInput("logs", "Logs", value = TRUE),
    selectInput("fmt", NULL, c("csv", "json")),
    textOutput("out"),
    progress_bar(0, id = "bar"),
    metric("Rows", 1, id = "rows"),
    actionButton("go", "Go")
  )
  input <- shiny_input(a)
  output <- shiny_output(a)
  expect_identical(input$name, "Ada")
  expect_identical(input[["logs"]], TRUE)
  expect_identical(input$fmt, "csv")
  expect_setequal(names(input), c("name", "logs", "fmt", "out", "bar", "rows", "go"))
  expect_error(input$nope, "nope")
  expect_error(input$go, "observeEvent")
  expect_error(input$name <- "x", "read-only")

  output$out <- "Done"
  expect_identical(a$query_one("#out")$text, "Done")
  output[["bar"]] <- 0.5
  expect_identical(a$query_one("#bar")$value, 0.5)
  output$rows <- 42
  expect_identical(a$query_one("#rows")$value, 42)
  output$go <- "Run"
  expect_identical(a$query_one("#go")$label, "Run")
  output$name <- "Bob"
  expect_identical(input$name, "Bob")
  expect_error(output$nope <- "x", "nope")
  expect_output(print(input), "name")
  expect_output(print(output), "out")
  expect_error(shiny_input(NULL), "No app")
})

test_that("observeEvent(input$id) works with input[[\"id\"]] and with a selector outside a server", {
  n <- 0L
  a <- app(actionButton("go", "Go"), server = function(input, output, session) {
    observeEvent(input[["go"]], n <<- n + 1L)
    observeEvent("Button", n <<- n + 10L)
  })
  pilot <- test_app(a, 20, 3)
  pilot$press("enter")
  expect_identical(n, 11L)
  pilot$stop()
})

test_that("observeEvent accepts named functions and rejects extra arguments", {
  calls <- list()
  record <- function(event, app) calls[[length(calls) + 1L]] <<- event$type
  a <- app(actionButton("go", "Go"), observeEvent("#go", record))
  pilot <- test_app(a, 20, 3)
  pilot$press("enter")
  expect_identical(calls, list("button.pressed"))
  pilot$stop()
  expect_error(observeEvent("#go", NULL, bogus = 1), "bogus")
  expect_error(observeEvent("#go", NULL, event = 1), "event")
})

# update*Input ----------------------------------------------------------------

test_that("update*Input functions change controls and their labels", {
  a <- app(
    textInput("name", "Name"),
    textAreaInput("notes", "Notes"),
    numericInput("n", "N", value = 1),
    checkboxInput("logs", "Logs"),
    selectInput("fmt", "Format", c("csv", "json")),
    radioButtons("mode", "Mode", c("a", "b")),
    actionButton("go", "Go")
  )
  updateTextInput(a, "name", label = "Your name", value = "Ada", placeholder = "type")
  name <- a$query_one("#name")
  expect_identical(name$value, "Ada")
  expect_identical(name$placeholder, "type")
  expect_identical(name$parent$children[[1]]$text, "Your name")
  updateTextAreaInput(a, "notes", value = "x\ny")
  expect_identical(a$query_one("#notes")$value, "x\ny")
  updateNumericInput(a, "n", value = 7)
  expect_identical(a$query_one("#n")$value, "7")
  updateCheckboxInput(a, "logs", value = TRUE, label = "Verbose")
  expect_true(a$query_one("#logs")$value)
  expect_identical(a$query_one("#logs")$label, "Verbose")
  updateSelectInput(a, "fmt", selected = "json")
  expect_identical(a$query_one("#fmt")$value, "json")
  updateRadioButtons(a, "mode", selected = "b")
  expect_identical(a$query_one("#mode")$value, "b")
  updateActionButton(a, "go", label = "Run")
  expect_identical(a$query_one("#go")$label, "Run")
  expect_error(updateTextInput(a, "nope", value = "x"), "nope")
  expect_error(updateTextInput(a, "go", value = "x"), "Button")
  expect_error(updateTextInput(a, inputId = "go2"), "go2")
})

test_that("update*Input can be called from the server without session", {
  a <- app(textInput("name", "Name"), actionButton("go", "Go"), server = function(input, output, session) {
    observeEvent(input$go, updateTextInput("name", value = "pressed"))
  })
  pilot <- test_app(a, 30, 4)
  pilot$focus("#go")
  pilot$press("enter")
  expect_identical(pilot$query_one("#name")$value, "pressed")
  pilot$stop()
  # Without a running app this is "No app"; another test's leftover app gives "no widget".
  expect_error(updateTextInput("name", value = "x"), "No app|\"name\"")
})

# constructor details ---------------------------------------------------------

test_that("constructors accept list choices, inline radios, NULL numeric values and labels", {
  w <- selectInput("fmt", NULL, list("Comma" = "csv", "JSON" = "json"), selected = "json")
  expect_identical(w$value, "json")
  r <- radioButtons("mode", NULL, list("a", "b"), inline = TRUE)
  expect_identical(r$computed_style()$layout, "horizontal")
  expect_identical(r$value, "a")
  n <- numericInput("n", "N")
  ctrl <- n$query_one("#n")
  expect_identical(ctrl$value, "")
  expect_true(ctrl$valid)
  expect_error(numericInput("n", value = "x"), "number")
  expect_error(selectInput("fmt", NULL, character()), "choices")
  p <- passwordInput("pw", "Password")
  expect_true(p$query_one("#pw")$password)
  expect_true(inherits(textOutput("out"), "Label"))
  expect_identical(textOutput("out")$id, "out")
  expect_error(textInput(1), "inputId")
})
