# observeEvent(): react to a widget's primary message or to a signal.

# The message a widget type sends when the user "does the obvious thing"
# with it; NULL for widgets without one (then every message counts).
primary_event <- function(widget) {
  for (cls in class(widget)) {
    type <- switch(
      cls,
      Button = "button.pressed",
      Input = "input.changed",
      Checkbox = "checkbox.changed",
      Select = "dropdown.changed",
      RadioSet = "radio_set.changed",
      OptionList = "option_list.selected",
      TextArea = "textarea.changed",
      Tabs = "tabs.changed",
      DataTable = "datatable.row_selected",
      TreeView = "tree.node_selected",
      SplitPane = "splitpane.resized",
      ScrollView = "scroll.changed",
      NULL
    )
    if (!is.null(type)) return(type)
  }
  NULL
}

# Capture a handler the way Shiny's exprToFunction() does: a function (a
# function literal, a name or `pkg::fn`) is used as is; anything else is an
# expression evaluated later with `event`, `app`, `input`, `output` and
# `value` bound in a child of the caller's environment.
capture_handler <- function(expr, env) {
  is_fn_expr <- is.symbol(expr) ||
    (is.call(expr) && is.symbol(expr[[1]]) && as.character(expr[[1]]) %in% c("function", "::", ":::"))
  if (is_fn_expr) {
    fn <- tryCatch(eval(expr, env), error = function(e) NULL)
    if (is.function(fn)) return(list(fn = fn))
  }
  list(expr = expr, env = env)
}

# Run a captured handler. `...` are extra named bindings (`event = ` for
# widget handlers, `value = ` for signal handlers); a function handler gets
# them positionally, then `app`.
run_handler <- function(handler, app, ...) {
  extra <- list(...)
  if (!is.null(handler$fn)) {
    return(do.call(call_flex, c(list(handler$fn), unname(extra), list(app))))
  }
  e <- new.env(parent = handler$env)
  for (n in names(extra)) assign(n, extra[[n]], envir = e)
  e$app <- app
  if (!is.null(app)) {
    e$input <- shiny_input(app)
    e$output <- shiny_output(app)
  }
  eval(handler$expr, e)
}

# What observeEvent() should listen to, from the unevaluated eventExpr.
resolve_event_target <- function(expr, env) {
  if (is.call(expr) && is.symbol(expr[[1]]) && as.character(expr[[1]]) %in% c("$", "[[") && length(expr) == 3L) {
    object <- tryCatch(eval(expr[[2]], env), error = function(e) NULL)
    if (inherits(object, c("termr_input", "termr_output"))) {
      name <- if (is.symbol(expr[[3]])) as.character(expr[[3]]) else eval(expr[[3]], env)
      check_scalar_character(name, "id")
      return(list(kind = "selector", selector = paste0("#", name)))
    }
  }
  value <- eval(expr, env)
  if (is_scalar_character(value)) {
    parse_selector(value)
    return(list(kind = "selector", selector = value))
  }
  if (is_widget(value)) return(list(kind = "widget", widget = value))
  if (inherits(value, c("termr_signal", "termr_computed"))) return(list(kind = "signal", signal = value))
  stop(sprintf(
    "`eventExpr` must be `input$id`, a selector string such as \"#id\", a widget or a signal(), not %s.",
    class(value)[[1]]
  ), call. = FALSE)
}

#' React to user input or to a signal
#'
#' The Shiny way to say "when this happens, do that". `observeEvent()` pairs
#' something to watch with a handler, and registers the pair on the app.
#'
#' `eventExpr` can be:
#' * `input$id` - the widget with that id, on its primary message;
#' * a selector string such as `"#id"` or `"Button"` - the same, for every
#'   widget matching the selector;
#' * a widget object - that exact widget;
#' * a [signal()] or [computed()] - a [watch()] that skips the initial value.
#'
#' The primary message of a widget type is the one its user action sends:
#' `"button.pressed"`, `"input.changed"`, `"checkbox.changed"`,
#' `"dropdown.changed"`, `"radio_set.changed"`, `"option_list.selected"`,
#' `"textarea.changed"`, `"tabs.changed"`, `"datatable.row_selected"`,
#' `"tree.node_selected"`, `"splitpane.resized"` and `"scroll.changed"`.
#' `event =` overrides it (for example `"input.submitted"`). A widget type
#' with no primary message fires on every message it posts.
#'
#' `handlerExpr` is either a function or, as in Shiny, a (braced) expression.
#' An expression is evaluated in the caller's environment with `event` (the
#' [Event]) and `app` (the [App]) bound, plus `input` and `output` (see
#' [shiny_input()]) when the app is known. For a signal, `value` holds the
#' new value instead of `event`. A function is called as
#' `function(event, app)` or `function(value, app)`; fewer arguments are
#' fine.
#'
#' Inside a server function (see [app()]) the handler is registered on the
#' running app immediately and removed when the app stops. Outside one the
#' result is a handler to list in `app(...)`, like [on()].
#'
#' @param eventExpr What to react to, see above.
#' @param handlerExpr What to do: a function or an expression.
#' @param ... Reserved; must be empty.
#' @param event For widget targets, the message type to react to instead of
#'   the widget's primary message.
#' @param ignoreNULL For signal targets, skip `NULL` values?
#' @param ignoreInit For signal targets, skip the value the signal holds
#'   when `observeEvent()` is called?
#' @param once Remove the handler after it ran once?
#' @return A `termr_handler` for widget targets or a `termr_watch` for
#'   signal targets (invisibly inside a server). Both can be passed to
#'   [app()]; a watch can be stopped with [dispose()].
#' @export
#' @examples
#' ui <- vertical(
#'   textInput("name", "Name", placeholder = "Your name"),
#'   actionButton("go", "Greet"),
#'   textOutput("out")
#' )
#' server <- function(input, output, session) {
#'   observeEvent(input$go, {
#'     output$out <- paste("Hello,", input$name)
#'   })
#' }
#' pilot <- test_app(app(ui, server = server), 40, 6)
#' pilot$focus("#name")
#' pilot$type("Ada")
#' pilot$focus("#go")
#' pilot$press("enter")
#' pilot$query_one("#out")$text
#' pilot$stop()
#'
#' # Without a server: list the handler in app(), as with on().
#' count <- signal(0L)
#' a <- app(
#'   label(function() paste("Count:", count())),
#'   actionButton("go", "Add"),
#'   observeEvent("#go", count(count() + 1L)),
#'   observeEvent(count, message("count is ", value))
#' )
observeEvent <- function(eventExpr, handlerExpr, ..., event = NULL, ignoreNULL = TRUE,
                         ignoreInit = TRUE, once = FALSE) {
  if (...length()) stop("Unused arguments in observeEvent(): ", paste(...names(), collapse = ", "), call. = FALSE)
  if (missing(handlerExpr)) {
    stop("`handlerExpr` is missing: give observeEvent() a handler expression or function.", call. = FALSE)
  }
  env <- parent.frame()
  check_scalar_character(event, "event", allow_null = TRUE)
  check_flag(ignoreNULL)
  check_flag(ignoreInit)
  check_flag(once)
  target <- resolve_event_target(substitute(eventExpr), env)
  handler <- capture_handler(substitute(handlerExpr), env)
  result <- if (target$kind == "signal") {
    observe_signal(target$signal, handler, ignoreNULL = ignoreNULL, ignoreInit = ignoreInit, once = once)
  } else {
    observe_widget(target, handler, event = event, once = once)
  }
  registrar <- current_registration_target()
  if (is.null(registrar)) return(result)
  registrar$add(result)
  invisible(result)
}

observe_widget <- function(target, handler, event, once) {
  filter <- if (is.null(event)) {
    function(ev, widget) {
      primary <- primary_event(widget)
      if (is.null(primary)) inherits(ev, "MessageEvent") else identical(ev$type, primary)
    }
  }
  h <- NULL
  fn <- function(event, app) {
    if (once && !is.null(app)) app$off(h)
    run_handler(handler, app, event = event)
  }
  h <- structure(
    list(
      type = event %||% "*",
      selector = if (target$kind == "selector") target$selector,
      sender = if (target$kind == "widget") target$widget,
      filter = filter,
      handler = fn
    ),
    class = "termr_handler"
  )
  h
}

observe_signal <- function(sig, handler, ignoreNULL, ignoreInit, once) {
  ctx <- new.env(parent = emptyenv())
  ctx$app <- NULL
  ctx$handle <- NULL
  ctx$first <- TRUE
  ctx$done <- FALSE
  w <- watch(function() {
    v <- sig()
    if (ctx$first) {
      ctx$first <- FALSE
      if (ignoreInit) return(invisible())
    }
    if (ignoreNULL && is.null(v)) return(invisible())
    if (once) {
      ctx$done <- TRUE
      if (!is.null(ctx$handle)) ctx$handle$dispose()
    }
    untracked(run_handler(handler, ctx$app %||% current_app(), value = v))
    invisible()
  })
  ctx$handle <- w
  if (ctx$done) w$dispose()
  w$bind_app <- function(app) ctx$app <- app
  w
}
