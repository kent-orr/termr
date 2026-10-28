# Shiny-shaped session layer: the registration target that observeEvent()
# consults while a server function runs, and the `input` / `output`
# accessors passed to the server.

shiny_env <- new.env(parent = emptyenv())
shiny_env$targets <- list()

# Run `expr` with `target` (a list with `app` and `add(x)`) as the current
# registration target.
with_registration_target <- function(target, expr) {
  shiny_env$targets <- c(list(target), shiny_env$targets)
  on.exit(shiny_env$targets <- shiny_env$targets[-1L], add = TRUE)
  expr
}

current_registration_target <- function() {
  if (length(shiny_env$targets)) shiny_env$targets[[1]] else NULL
}

#' Read and write widgets by id
#'
#' `shiny_input()` and `shiny_output()` wrap an [App] in the `input` and
#' `output` objects a Shiny server function receives. `input$name` reads
#' the `value` of the widget with id `name`; `output$name <- x` writes the
#' widget's natural field: `text` for labels, `value` for progress bars,
#' metrics and controls, `data` for tables, sparklines and key-value views,
#' `label` for buttons. `names()` lists the ids in the app. An id that does
#' not match a widget is an error.
#'
#' A server function passed to [app()] receives both objects; these
#' constructors are for use outside one, for example in tests.
#'
#' @param app An [App]; defaults to the running app.
#' @return An object of class `termr_input` or `termr_output`.
#' @name shiny_session
#' @seealso [observeEvent()], [textInput()], [app()].
#' @examples
#' a <- app(textInput("name", value = "Ada"), textOutput("out"))
#' input <- shiny_input(a)
#' output <- shiny_output(a)
#' input$name
#' output$out <- paste("Hello,", input$name)
#' a$query_one("#out")$text
NULL

#' @rdname shiny_session
#' @export
shiny_input <- function(app = current_app()) {
  structure(list(app = check_app(app)), class = "termr_input")
}

#' @rdname shiny_session
#' @export
shiny_output <- function(app = current_app()) {
  structure(list(app = check_app(app)), class = "termr_output")
}

shiny_widget <- function(x, name) {
  if (!is_scalar_character(name) || !nzchar(name)) stop("A widget id must be a single string.", call. = FALSE)
  app <- unclass(x)$app
  found <- tryCatch(app$query_one(paste0("#", name)), error = function(e) NULL)
  if (is.null(found)) {
    stop(sprintf("No widget has the id \"%s\".", name), call. = FALSE)
  }
  found
}

has_field <- function(widget, name) {
  exists(name, envir = widget, inherits = FALSE) &&
    (bindingIsActive(name, widget) || !is.function(widget[[name]]))
}

# The field `output$id <- x` writes for a widget type.
shiny_output_field <- function(widget) {
  for (cls in class(widget)) {
    field <- switch(
      cls,
      Label = "text",
      Button = "label",
      ProgressBar = , Metric = "value",
      DataTable = , Sparkline = , KeyValue = "data",
      NULL
    )
    if (!is.null(field)) return(field)
  }
  if (has_field(widget, "value")) return("value")
  stop(sprintf("Cannot write to %s: it has no output field.", widget$format()), call. = FALSE)
}

shiny_read <- function(x, name) {
  widget <- shiny_widget(x, name)
  if (!has_field(widget, "value")) {
    stop(sprintf("%s has no value to read; react to it with observeEvent() instead.", widget$format()),
         call. = FALSE)
  }
  widget$value
}

shiny_write <- function(x, name, value) {
  widget <- shiny_widget(x, name)
  field <- shiny_output_field(widget)
  widget[[field]] <- value
  invisible(x)
}

shiny_ids <- function(x) {
  app <- unclass(x)$app
  ids <- unlist(lapply(app$screens, function(screen) {
    vapply(screen$walk()[-1L], function(w) w$id %||% NA_character_, character(1))
  }))
  unique(ids[!is.na(ids)]) %||% character()
}

#' @export
`$.termr_input` <- function(x, name) shiny_read(x, name)

#' @export
`[[.termr_input` <- function(x, i, ...) shiny_read(x, i)

#' @export
`$<-.termr_input` <- function(x, name, value) {
  stop("`input` is read-only; write widgets through `output`.", call. = FALSE)
}

#' @export
`[[<-.termr_input` <- function(x, i, value) {
  stop("`input` is read-only; write widgets through `output`.", call. = FALSE)
}

#' @export
names.termr_input <- function(x) shiny_ids(x)

#' @export
`$.termr_output` <- function(x, name) shiny_widget(x, name)

#' @export
`[[.termr_output` <- function(x, i, ...) shiny_widget(x, i)

#' @export
`$<-.termr_output` <- function(x, name, value) shiny_write(x, name, value)

#' @export
`[[<-.termr_output` <- function(x, i, value) shiny_write(x, i, value)

#' @export
names.termr_output <- function(x) shiny_ids(x)

#' @export
print.termr_input <- function(x, ...) {
  cat("<input> ids: ", paste(shiny_ids(x), collapse = ", "), "\n", sep = "")
  invisible(x)
}

#' @export
print.termr_output <- function(x, ...) {
  cat("<output> ids: ", paste(shiny_ids(x), collapse = ", "), "\n", sep = "")
  invisible(x)
}
