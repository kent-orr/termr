#' Reactive state fields of custom widgets
#'
#' `state()` declares a state field of a custom widget (see [widget()]).
#' Reading the field returns its value; assigning a different value
#' (`self$count <- self$count + 1L`) invalidates the widget and schedules a
#' repaint. Repaints are batched: any number of assignments in one
#' event-loop tick produce a single render and a single screen diff.
#'
#' Plain values in `widget(state = list(...))` are state fields too; use
#' `state()` when the field needs a `watch` callback.
#'
#' `reactive(value, watch)` was the name of this function before termr
#' 1.0.3 and still works, with a deprecation warning (once per session).
#' `reactive()` now creates a derived reactive value, as in Shiny; see
#' [reactive()].
#'
#' @param value Initial value.
#' @param watch Optional `function(self, value, old)` called after the
#'   value changed, e.g. to post a message or update other widgets.
#' @return An object of class `termr_reactive`.
#' @export
#' @examples
#' state(0L)
#' state("", watch = function(self, value, old) message("now ", value))
state <- function(value = NULL, watch = NULL) {
  check_function(watch, "watch", allow_null = TRUE)
  structure(list(default = value, watch = watch), class = "termr_reactive")
}

#' @export
format.termr_reactive <- function(x, ...) {
  value <- paste(utils::capture.output(utils::str(x$default, give.head = FALSE)), collapse = " ")
  paste0("<state ", trimws(value), if (!is.null(x$watch)) " (watched)", ">")
}

#' @export
print.termr_reactive <- function(x, ...) {
  cat(format(x), "\n", sep = "")
  invisible(x)
}

as_reactive <- function(x) if (inherits(x, "termr_reactive")) x else state(x)

# An R6 active binding that stores `name` in the widget's reactive state.
# The name is spliced into the body because R6 replaces the environment of
# active binding functions.
state_binding <- function(name) {
  f <- function(value) NULL
  body(f) <- bquote({
    if (missing(value)) return(private$.state[[.(name)]])
    self$set_state(.(name), value)
  })
  f
}

# Warn once per session about a deprecated spelling.
deprecate_once <- function(key, ...) {
  if (isTRUE(termr_env$deprecated[[key]])) return(invisible())
  termr_env$deprecated[[key]] <- TRUE
  warning(paste0(...), call. = FALSE)
  invisible()
}
