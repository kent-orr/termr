# Shiny-named constructors for termr controls. Each one builds the matching
# termr widget; with a label it returns a vertical() with the label above
# the control and the id on the control itself, so "#inputId" finds it.

with_shiny_label <- function(label, control) {
  if (is.null(label)) return(control)
  vertical(label(label), control, style = style(height = "auto"))
}

shiny_choices <- function(choices) {
  if (is.list(choices)) {
    nms <- names(choices)
    choices <- unlist(choices, use.names = FALSE)
    if (!is.null(nms)) names(choices) <- nms
  }
  as_choices(choices)
}

#' Shiny-style input controls
#'
#' Constructors named and ordered the way Shiny's are, building termr
#' widgets: `inputId` first, `label` second. With a label they return a
#' [vertical()] holding a [label()] above the control; the id is on the
#' control, so `"#inputId"`, `observeEvent(input$inputId, ...)` and
#' `input$inputId` all reach the control itself. Without a label the control
#' is returned as is.
#'
#' | Shiny | termr |
#' |---|---|
#' | `textInput()` | [input()] |
#' | `passwordInput()` | `input(password = TRUE)` |
#' | `textAreaInput()` | [text_area()] |
#' | `numericInput()` | `input(validate = )`; `$value` is text |
#' | `checkboxInput()` | [checkbox()] |
#' | `radioButtons()` | [radio_set()] |
#' | `selectInput()` | [dropdown()] |
#' | `actionButton()` | [button()] |
#' | `textOutput()` | `label(id = )` |
#'
#' @param inputId,outputId The widget id.
#' @param label Label shown above the control (`NULL` for none). For
#'   `checkboxInput()` and `actionButton()` the label is part of the
#'   control.
#' @param value Initial value.
#' @param placeholder Placeholder text shown while empty.
#' @param rows Height of the text area in lines (`NULL`: fill the space).
#' @param min,max Bounds for `numericInput()`; `NA` for none.
#' @param choices Values to choose from; names, if present, are the labels
#'   shown. A list is flattened.
#' @param selected Initially selected value; the first choice by default.
#' @param inline Lay radio buttons out side by side?
#' @param ... Passed on to the termr constructor (`classes`, `style`,
#'   `disabled`, ...).
#' @return A widget: the control, or a `Vertical` containing the label and
#'   the control.
#' @name shiny_inputs
#' @seealso [observeEvent()], [updateTextInput()], [app()].
#' @examples
#' ui <- vertical(
#'   textInput("name", "Name", placeholder = "Your name"),
#'   numericInput("age", "Age", value = 30, min = 0, max = 120),
#'   selectInput("fmt", "Format", c("Comma separated" = "csv", JSON = "json")),
#'   radioButtons("mode", "Mode", c("Fast" = "fast", "Careful" = "careful")),
#'   checkboxInput("logs", "Enable logs", value = TRUE),
#'   actionButton("go", "Run"),
#'   textOutput("status")
#' )
#' render_widget(ui, 40, 20)
NULL

#' @rdname shiny_inputs
#' @export
textInput <- function(inputId, label = NULL, value = "", placeholder = "", ...) {
  check_scalar_character(inputId, "inputId")
  with_shiny_label(label, input(value = value %||% "", placeholder = placeholder, id = inputId, ...))
}

#' @rdname shiny_inputs
#' @export
passwordInput <- function(inputId, label = NULL, value = "", placeholder = "", ...) {
  check_scalar_character(inputId, "inputId")
  with_shiny_label(label, input(value = value %||% "", placeholder = placeholder, id = inputId,
                                password = TRUE, ...))
}

#' @rdname shiny_inputs
#' @export
textAreaInput <- function(inputId, label = NULL, value = "", placeholder = "", rows = NULL, ...) {
  check_scalar_character(inputId, "inputId")
  args <- list(value = value %||% "", placeholder = placeholder, id = inputId, ...)
  if (!is.null(rows)) {
    rows <- check_count(rows, "rows")
    args$style <- merge_styles(as_style(args$style), style(height = rows))
  }
  with_shiny_label(label, do.call(text_area, args))
}

#' @rdname shiny_inputs
#' @export
numericInput <- function(inputId, label = NULL, value = NULL, min = NA, max = NA, ...) {
  check_scalar_character(inputId, "inputId")
  if (!is.null(value) && !(is.numeric(value) && length(value) == 1L)) {
    stop("`value` must be a single number or NULL.", call. = FALSE)
  }
  text <- if (is.null(value) || is.na(value)) "" else format(value)
  validate <- function(x) {
    if (!nzchar(trimws(x))) return(NULL)
    n <- suppressWarnings(as.numeric(x))
    if (is.na(n)) return("Enter a number")
    if (!is.na(min) && n < min) return(paste("Must be at least", format(min)))
    if (!is.na(max) && n > max) return(paste("Must be at most", format(max)))
    NULL
  }
  with_shiny_label(label, input(value = text, id = inputId, validate = validate, ...))
}

#' @rdname shiny_inputs
#' @export
checkboxInput <- function(inputId, label = "", value = FALSE, ...) {
  check_scalar_character(inputId, "inputId")
  checkbox(label %||% "", value = value, id = inputId, ...)
}

#' @rdname shiny_inputs
#' @export
radioButtons <- function(inputId, label = NULL, choices, selected = NULL, inline = FALSE, ...) {
  check_scalar_character(inputId, "inputId")
  check_flag(inline)
  ch <- shiny_choices(choices)
  if (!length(ch$values)) stop("`choices` must have at least one value.", call. = FALSE)
  buttons <- Map(function(lbl, val) radio_button(lbl, val), ch$labels, ch$values)
  args <- c(unname(buttons), list(selected = selected %||% ch$values[[1]], id = inputId), list(...))
  if (inline) args$style <- merge_styles(as_style(args$style), style(layout = "horizontal"))
  with_shiny_label(label, do.call(radio_set, args))
}

#' @rdname shiny_inputs
#' @export
selectInput <- function(inputId, label = NULL, choices, selected = NULL, ...) {
  check_scalar_character(inputId, "inputId")
  ch <- shiny_choices(choices)
  if (!length(ch$values)) stop("`choices` must have at least one value.", call. = FALSE)
  with_shiny_label(label, dropdown(structure(ch$values, names = ch$labels),
                                   value = selected %||% ch$values[[1]], id = inputId, ...))
}

#' @rdname shiny_inputs
#' @export
actionButton <- function(inputId, label = "Button", ...) {
  check_scalar_character(inputId, "inputId")
  button(label, id = inputId, ...)
}

#' @rdname shiny_inputs
#' @export
textOutput <- function(outputId, ...) {
  check_scalar_character(outputId, "outputId")
  label("", id = outputId, ...)
}

# update*Input() -------------------------------------------------------------

# Shiny passes `session` first; allow it to be left out, so that
# updateTextInput("name", value = "x") also works.
shiny_update_target <- function(session, inputId, class) {
  if (missing(inputId) && is.character(session)) {
    inputId <- session
    session <- current_app()
  }
  if (!is_scalar_character(inputId)) stop("`inputId` must be a single string.", call. = FALSE)
  app <- check_app(session)
  widget <- tryCatch(app$query_one(paste0("#", inputId)), error = function(e) NULL)
  if (is.null(widget)) stop(sprintf("No widget has the id \"%s\".", inputId), call. = FALSE)
  if (!inherits(widget, class)) {
    stop(sprintf("%s is a %s, not a %s.", widget$format(), class(widget)[[1]], class), call. = FALSE)
  }
  widget
}

# The label() that a shiny_inputs constructor placed above a control.
shiny_label_of <- function(widget) {
  parent <- widget$parent
  if (inherits(parent, "Vertical") && length(parent$children) == 2L &&
      inherits(parent$children[[1]], "Label") && identical(parent$children[[2]], widget)) {
    return(parent$children[[1]])
  }
  NULL
}

update_shiny_label <- function(widget, label) {
  if (is.null(label)) return(invisible())
  lbl <- shiny_label_of(widget)
  if (is.null(lbl)) stop(sprintf("%s has no label above it to update.", widget$format()), call. = FALSE)
  lbl$text <- label
  invisible()
}

#' Change a Shiny-style input from the server
#'
#' Counterparts of Shiny's `update*Input()` functions for the controls made
#' by [textInput()] and friends. Each one finds the widget by id and
#' assigns the given fields; arguments left `NULL` are not changed. `label`
#' changes the label placed above the control by the constructor.
#'
#' @param session The [App] (Shiny's `session`); defaults to the running app
#'   when the first argument is the id instead.
#' @param inputId The widget id.
#' @param label New label text.
#' @param value New value.
#' @param placeholder New placeholder text.
#' @param selected New selected value.
#' @return The widget, invisibly.
#' @name shiny_update
#' @seealso [shiny_inputs], [observeEvent()].
#' @examples
#' a <- app(textInput("name", "Name"), selectInput("fmt", "Format", c("csv", "json")))
#' updateTextInput(a, "name", value = "Ada", label = "Your name")
#' updateSelectInput(a, "fmt", selected = "json")
#' a$query_one("#name")$value
#' a$query_one("#fmt")$value
NULL

#' @rdname shiny_update
#' @export
updateTextInput <- function(session, inputId, label = NULL, value = NULL, placeholder = NULL) {
  w <- shiny_update_target(session, inputId, "Input")
  update_shiny_label(w, label)
  if (!is.null(placeholder)) {
    check_scalar_character(placeholder, "placeholder")
    w$placeholder <- placeholder
    w$invalidate()
  }
  if (!is.null(value)) w$value <- value
  invisible(w)
}

#' @rdname shiny_update
#' @export
updateTextAreaInput <- function(session, inputId, label = NULL, value = NULL, placeholder = NULL) {
  w <- shiny_update_target(session, inputId, "TextArea")
  update_shiny_label(w, label)
  if (!is.null(placeholder)) {
    check_scalar_character(placeholder, "placeholder")
    w$placeholder <- placeholder
    w$invalidate()
  }
  if (!is.null(value)) w$value <- value
  invisible(w)
}

#' @rdname shiny_update
#' @export
updateNumericInput <- function(session, inputId, label = NULL, value = NULL) {
  w <- shiny_update_target(session, inputId, "Input")
  update_shiny_label(w, label)
  if (!is.null(value)) w$value <- if (is.na(value)) "" else format(value)
  invisible(w)
}

#' @rdname shiny_update
#' @export
updateCheckboxInput <- function(session, inputId, label = NULL, value = NULL) {
  w <- shiny_update_target(session, inputId, "Checkbox")
  if (!is.null(label)) w$label <- label
  if (!is.null(value)) w$value <- value
  invisible(w)
}

#' @rdname shiny_update
#' @export
updateSelectInput <- function(session, inputId, label = NULL, selected = NULL) {
  w <- shiny_update_target(session, inputId, "Select")
  update_shiny_label(w, label)
  if (!is.null(selected)) w$value <- selected
  invisible(w)
}

#' @rdname shiny_update
#' @export
updateRadioButtons <- function(session, inputId, label = NULL, selected = NULL) {
  w <- shiny_update_target(session, inputId, "RadioSet")
  update_shiny_label(w, label)
  if (!is.null(selected)) w$value <- selected
  invisible(w)
}

#' @rdname shiny_update
#' @export
updateActionButton <- function(session, inputId, label = NULL) {
  w <- shiny_update_target(session, inputId, "Button")
  if (!is.null(label)) w$label <- label
  invisible(w)
}
