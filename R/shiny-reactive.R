# Shiny-named reactive functions over the signal graph, plus the render
# functions that keep an output widget in sync with an expression.

# Does the unevaluated `expr` look like a reactive expression (a braced
# block or a function) rather than a plain initial value?
is_reactive_expression <- function(expr, env) {
  if (is.call(expr) && is.symbol(expr[[1]])) {
    head <- as.character(expr[[1]])
    if (head %in% c("{", "function")) return(TRUE)
    if (head %in% c("::", ":::")) return(is.function(tryCatch(eval(expr, env), error = function(e) NULL)))
  }
  if (is.symbol(expr)) return(is.function(tryCatch(eval(expr, env), error = function(e) NULL)))
  FALSE
}

#' Shiny-style reactive building blocks
#'
#' Aliases over termr's signal graph that read like Shiny:
#'
#' | Shiny | termr |
#' |---|---|
#' | `reactiveVal(x)` | [signal()] |
#' | `reactive({ })` | [computed()] |
#' | `observe({ })` | [watch()] |
#' | `isolate({ })` | [untracked()] |
#' | `invalidateLater(ms)` | an app timer that re-runs the enclosing reactive |
#'
#' `reactive()`, `observe()` and the render functions take a braced
#' expression, evaluated in the caller's environment with `app`, `input`
#' and `output` bound when an app is running, or a function. Widget fields
#' read inside them (`input$name`, `some_input$value`) are dependencies,
#' so the expression re-runs when the user changes the widget.
#'
#' `invalidateLater(millis)` schedules the reactive that is currently
#' running to run again after `millis` milliseconds, using the app's
#' timers. It needs a running app and is cancelled when the reactive is
#' disposed. Each call replaces a pending one for the same reactive.
#'
#' Until termr 1.0.3 `reactive(value, watch)` declared a state field of a
#' custom widget. That use is now spelled [state()]; the old spelling still
#' works for plain values and warns once per session.
#'
#' @param x Initial value of a `reactiveVal()`, or the expression of a
#'   `reactive()`.
#' @param expr A braced expression or a function.
#' @param watch Only for the deprecated `reactive(value, watch)` form.
#' @param name Optional graph label used in diagnostics.
#' @param millis Milliseconds until the enclosing reactive re-runs.
#' @param session The [App] whose timers are used; the running app by
#'   default.
#' @return `reactiveVal()` returns a signal, `reactive()` a computed value
#'   (call it to read), `observe()` a `termr_watch` (stop it with
#'   [dispose()]), `isolate()` the value of `expr`.
#' @name shiny_reactive
#' @seealso [signals], [observeEvent()], [renderText()].
#' @examples
#' items <- reactiveVal(c(1, 2))
#' total <- reactive({ sum(items()) })
#' seen <- c()
#' w <- observe({ seen <<- c(seen, total()) })
#' items(c(1, 2, 3))
#' seen
#' isolate(total())
#' dispose(w)
#'
#' # A clock that re-renders itself every second.
#' ui <- textOutput("clock")
#' server <- function(input, output, session) {
#'   output$clock <- renderText({
#'     invalidateLater(1000)
#'     format(Sys.time(), "%H:%M:%S")
#'   })
#' }
#' pilot <- test_app(app(ui, server = server), 20, 1)
#' pilot$advance(1)
#' pilot$stop()
NULL

#' @rdname shiny_reactive
#' @export
reactiveVal <- function(x = NULL, name = NULL) signal(x, name = name)

#' @rdname shiny_reactive
#' @export
reactive <- function(x = NULL, watch = NULL, name = NULL) {
  env <- parent.frame()
  expr <- substitute(x)
  if (is.null(watch) && is_reactive_expression(expr, env)) {
    handler <- capture_handler(expr, env)
    return(computed(function() run_handler(handler, current_app()), name = name))
  }
  deprecate_once(
    "reactive_state",
    "reactive(value, watch) for widget state fields is deprecated; use state(value, watch). ",
    "reactive({ expr }) now creates a derived reactive value, as in Shiny."
  )
  state(x, watch = watch)
}

#' @rdname shiny_reactive
#' @export
observe <- function(expr, name = NULL) {
  handler <- capture_handler(substitute(expr), parent.frame())
  w <- watch(function() run_handler(handler, current_app()), name = name)
  registrar <- current_registration_target()
  if (is.null(registrar)) return(w)
  registrar$add(w)
  invisible(w)
}

#' @rdname shiny_reactive
#' @export
isolate <- function(expr) untracked(expr)

#' @rdname shiny_reactive
#' @export
invalidateLater <- function(millis, session = current_app()) {
  node <- rx$observer %||% rx$isolated
  if (is.null(node)) {
    stop("invalidateLater() must be called inside reactive(), observe() or a render function.", call. = FALSE)
  }
  if (!is_scalar_number(millis) || millis < 0) stop("`millis` must be a non-negative number.", call. = FALSE)
  app <- check_app(session)
  if (!is.null(node$timer)) node$timer$cancel()
  node$timer <- app$set_timeout(millis / 1000, function(app) {
    node$timer <- NULL
    if (node$disposed) return(invisible())
    if (node$kind == "computed") {
      if (!node$dirty) {
        node$dirty <- TRUE
        invalidate_subs(node)
      }
    } else {
      node$force <- TRUE
      rx$pending[[as.character(node$id)]] <- node
    }
    flush_effects()
  })
  invisible()
}

# Render functions -----------------------------------------------------------

#' Render functions for output widgets
#'
#' Assigned to `output$id` inside a server function (see [app()]), a render
#' function keeps the widget with that id in sync with an expression: the
#' expression runs now and again whenever a widget field or signal it read
#' changes.
#'
#' | Shiny | Output widget | What is written |
#' |---|---|---|
#' | `renderText({ })` | [textOutput()], [verbatimTextOutput()] | the value, formatted as `cat()` would print it |
#' | `renderPrint({ })` | [verbatimTextOutput()] | the lines `print()` would show |
#' | `renderTable({ })` | [tableOutput()] | a data frame |
#'
#' Outside a server, the same objects can be assigned through
#' [shiny_output()]. Assigning a plain value instead of a render function is
#' a one-shot write.
#'
#' @param expr A braced expression or a function. Evaluated with `app`,
#'   `input` and `output` bound when the app is running.
#' @return An object of class `termr_render`, to assign to an output.
#' @name shiny_render
#' @seealso [shiny_reactive], [observeEvent()].
#' @examples
#' ui <- vertical(textInput("name", "Name"), textOutput("greeting"))
#' server <- function(input, output, session) {
#'   output$greeting <- renderText({ paste("Hello,", input$name) })
#' }
#' pilot <- test_app(app(ui, server = server), 30, 5)
#' pilot$focus("#name")
#' pilot$type("Ada")
#' pilot$query_one("#greeting")$text
#' pilot$stop()
NULL

new_render <- function(expr, env, transform) {
  structure(list(handler = capture_handler(expr, env), transform = transform), class = "termr_render")
}

#' @rdname shiny_render
#' @export
renderText <- function(expr) {
  new_render(substitute(expr), parent.frame(), function(value) {
    if (is.null(value)) return("")
    if (inherits(value, "termr_text")) return(value)
    paste(utils::capture.output(cat(value)), collapse = "\n")
  })
}

#' @rdname shiny_render
#' @export
renderPrint <- function(expr) {
  new_render(substitute(expr), parent.frame(), function(value) {
    lines <- utils::capture.output(print(value))
    if (!length(lines)) "" else lines
  })
}

#' @rdname shiny_render
#' @export
renderTable <- function(expr) {
  new_render(substitute(expr), parent.frame(), function(value) {
    if (is.null(value)) return(data.frame())
    if (is.matrix(value)) value <- as.data.frame(value)
    if (!is.data.frame(value)) stop("renderTable() must return a data frame.", call. = FALSE)
    value
  })
}

#' @export
print.termr_render <- function(x, ...) {
  cat("<render>\n")
  invisible(x)
}

# Keep `widget[[field]]` in sync with a render object. Inside a server the
# binding is registered so that it is removed when the app stops.
bind_render <- function(widget, field, render) {
  widget$bind_reactive(field, function() {
    app <- widget$app %||% current_app()
    render$transform(run_handler(render$handler, app))
  })
  handle <- widget_private(widget)$.reactive_bindings[[field]]
  registrar <- current_registration_target()
  if (!is.null(registrar)) registrar$add(handle)
  invisible(widget)
}
