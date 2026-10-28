# Shiny-named layout functions. Each one builds termr containers sized in
# fr units, so the 12-column grid of Shiny maps onto the existing layout
# engine: col(4) is a vertical() of width "4fr" inside a row().

check_grid_width <- function(x, arg, min = 1L) {
  if (!is_scalar_number(x) || x != round(x) || x < min || x > 12) {
    stop(sprintf("`%s` must be a whole number from %d to 12.", arg, min), call. = FALSE)
  }
  as.integer(x)
}

grid_spacer <- function(n) Vertical$new(style = style(width = sprintf("%dfr", n), height = "auto"))

#' @title Col widget
#' @description A column of a 12-column [row()]. See [col()].
#' @rdname Col-class
#' @export
Col <- R6::R6Class(
  "Col",
  inherit = Vertical,
  public = list(
    #' @field span Width in grid columns (1 to 12).
    span = 12L,
    #' @field offset Empty grid columns placed before the column by [row()].
    offset = 0L,

    #' @description Create a column. See [col()].
    #' @param span Width in grid columns.
    #' @param ... Child widgets.
    #' @param offset Empty grid columns before the column.
    #' @param id,classes,style See [Widget].
    initialize = function(span, ..., offset = 0L, id = NULL, classes = NULL, style = NULL) {
      self$span <- check_grid_width(span, "width")
      self$offset <- check_grid_width(offset, "offset", min = 0L)
      if (self$span + self$offset > 12L) {
        stop("`width` plus `offset` must fit in 12 columns.", call. = FALSE)
      }
      super$initialize(..., id = id, classes = classes, style = style)
    },

    #' @description The built-in style: `span` fr wide, as tall as its content.
    default_style = function() style(width = sprintf("%dfr", self$span), height = "auto", layout = "vertical")
  )
)

#' Shiny-style layout
#'
#' Layout functions named after Shiny's, building termr containers. Sizes
#' are `fr` shares, so nothing here needs [style()]: `col(4)` next to
#' `col(8)` splits a row one third to two thirds at any terminal width.
#'
#' | Shiny | termr |
#' |---|---|
#' | `fluidPage(...)` | [vertical()] with one cell of padding left and right |
#' | `titlePanel(title)` | bold [label()] with a blank line below |
#' | `fluidRow(...)` | `row(...)`: [horizontal()] |
#' | `column(width, ..., offset)` | `col(width, ..., offset)`: a `"<width>fr"` [vertical()] |
#' | `sidebarLayout(sidebarPanel(), mainPanel())` | [horizontal()] filling the height |
#' | `sidebarPanel(..., width = 4)` | [panel()] `"4fr"` wide |
#' | `mainPanel(..., width = 8)` | [vertical()] `"8fr"` wide |
#' | `wellPanel(...)` | [panel()] |
#' | `tabsetPanel(tabPanel(title, ...), ...)` | [tabs()] and [tab()] |
#' | `h1()` to `h4()`, `p()` | styled [label()]s |
#' | `hr()`, `br()` | [rule()], a blank [label()] |
#'
#' ## The 12-column grid
#' Inside `row()`, the `col()` widths are out of 12. A row whose columns
#' add up to less than 12 leaves the rest empty, `offset` leaves empty
#' columns before a column, and columns that do not fit on the line wrap
#' onto the next one, as in Shiny. A `row()` of other widgets is a plain
#' [horizontal()]. Outside a `row()`, a `col()` is simply `"<width>fr"` wide.
#'
#' A row is as tall as its content. A terminal does not scroll the page the
#' way a browser does, so a row holding a long table would run off the
#' screen: `row(..., fill = TRUE)` makes the row take the height left over
#' by the other rows instead, with its columns as tall as the row, and the
#' table scrolls inside it.
#'
#' The layout column is called `col()` because `column()` is the
#' [data_table()] column spec. `row()` and `col()` mask base R's matrix
#' functions of the same names when termr is attached; given a matrix or
#' data frame they call [base::row()] and [base::col()], so existing code
#' keeps working.
#'
#' ## Tabs
#' `tabsetPanel(id = "tabs")` makes the selected tab readable as
#' `input$tabs`: the `value` of the selected `tabPanel()`, which defaults to
#' its title. React to a change with `observeEvent(input$tabs, ...)` and
#' switch tabs with [updateTabsetPanel()].
#'
#' @param ... Child widgets. For `row()` and `fluidRow()`, usually `col()`s;
#'   for `tabsetPanel()`, `tabPanel()`s. For `h1()` to `h4()` and `p()`,
#'   text, pasted together with spaces.
#' @param fill Make the row take the height left over by its siblings,
#'   with every column as tall as the row?
#' @param width Width in grid columns, 1 to 12.
#' @param offset Empty grid columns to leave before the column.
#' @param title Title text.
#' @param sidebarPanel,mainPanel The panels made by `sidebarPanel()` and
#'   `mainPanel()`.
#' @param position Side of the sidebar: `"left"` or `"right"`.
#' @param value Value of a tab, reported by `input$<tabsetPanel id>`.
#' @param selected Value of the initially selected tab; the first by default.
#' @param id Optional identifier (for `#id` selectors and `input$id`).
#' @param classes Optional classes.
#' @param style A [style()], applied on top of the built-in one.
#' @return A widget: `row()` returns a `Horizontal` (a `Vertical` of
#'   `Horizontal` lines when columns wrap), `col()` a [Col], `fluidPage()`
#'   and `mainPanel()` a `Vertical`, `sidebarPanel()` and `wellPanel()` a
#'   `Panel`, `tabsetPanel()` a `Tabs`, `tabPanel()` a [TabPanel], `hr()` a
#'   `Rule` and the others a `Label`.
#' @name shiny_layout
#' @seealso [shiny_inputs], [app()], [vertical()], [grid_layout()].
#' @examples
#' ui <- fluidPage(
#'   titlePanel("Sales"),
#'   sidebarLayout(
#'     sidebarPanel(selectInput("year", "Year", c("2025", "2026"))),
#'     mainPanel(textOutput("summary"))
#'   ),
#'   row(
#'     col(6, metric("Rows", 120)),
#'     col(6, metric("Total", 4500))
#'   )
#' )
#' render_widget(ui, 60, 16)
NULL

#' @rdname shiny_layout
#' @export
row <- function(..., fill = FALSE, id = NULL, classes = NULL, style = NULL) {
  if (...length() && !is.null(dim(..1))) return(base::row(...))
  check_flag(fill, "fill")
  kids <- flatten_widgets(list(...))
  line_style <- if (fill) style(height = "1fr")
  style <- merge_styles(line_style, as_style(style))
  if (!length(kids) || !all(vapply(kids, inherits, logical(1), "Col"))) {
    return(horizontal(kids, id = id, classes = classes, style = style))
  }
  if (fill) for (k in kids) k$style <- merge_styles(style(height = "1fr"), k$style)
  lines <- list()
  line <- list()
  used <- 0L
  close_line <- function() {
    if (used < 12L) line[[length(line) + 1L]] <<- grid_spacer(12L - used)
    lines[[length(lines) + 1L]] <<- line
  }
  for (k in kids) {
    need <- k$offset + k$span
    if (used + need > 12L && length(line)) {
      close_line()
      line <- list()
      used <- 0L
    }
    if (k$offset > 0L) line[[length(line) + 1L]] <- grid_spacer(k$offset)
    line[[length(line) + 1L]] <- k
    used <- used + need
  }
  close_line()
  if (length(lines) == 1L) return(horizontal(lines[[1]], id = id, classes = classes, style = style))
  vertical(lapply(lines, horizontal, style = line_style), id = id, classes = classes,
           style = merge_styles(style(height = if (fill) "1fr" else "auto"), style))
}

#' @rdname shiny_layout
#' @export
fluidRow <- function(..., fill = FALSE, id = NULL, classes = NULL, style = NULL) {
  row(..., fill = fill, id = id, classes = classes, style = style)
}

#' @rdname shiny_layout
#' @export
col <- function(width, ..., offset = 0L, id = NULL, classes = NULL, style = NULL) {
  if (!missing(width) && !is.null(dim(width))) return(base::col(width, ...))
  Col$new(width, ..., offset = offset, id = id, classes = classes, style = style)
}

#' @rdname shiny_layout
#' @export
fluidPage <- function(..., id = NULL, classes = NULL, style = NULL) {
  vertical(..., id = id, classes = classes, style = merge_styles(style(padding = c(0, 1)), as_style(style)))
}

#' @rdname shiny_layout
#' @export
titlePanel <- function(title, id = NULL, classes = NULL, style = NULL) {
  label(title, id = id, classes = classes,
        style = merge_styles(style(bold = TRUE, margin = c(0, 0, 1, 0)), as_style(style)))
}

#' @rdname shiny_layout
#' @export
sidebarLayout <- function(sidebarPanel, mainPanel, position = "left", id = NULL, classes = NULL, style = NULL) {
  position <- check_choice(position, c("left", "right"), "position")
  kids <- if (position == "left") list(sidebarPanel, mainPanel) else list(mainPanel, sidebarPanel)
  horizontal(kids, id = id, classes = classes, style = merge_styles(style(height = "1fr"), as_style(style)))
}

#' @rdname shiny_layout
#' @export
sidebarPanel <- function(..., width = 4L, id = NULL, classes = NULL, style = NULL) {
  width <- check_grid_width(width, "width")
  panel(..., id = id, classes = classes,
        style = merge_styles(style(width = sprintf("%dfr", width), height = "1fr"), as_style(style)))
}

#' @rdname shiny_layout
#' @export
mainPanel <- function(..., width = 8L, id = NULL, classes = NULL, style = NULL) {
  width <- check_grid_width(width, "width")
  vertical(..., id = id, classes = classes,
           style = merge_styles(style(width = sprintf("%dfr", width), height = "1fr"), as_style(style)))
}

#' @rdname shiny_layout
#' @export
wellPanel <- function(..., id = NULL, classes = NULL, style = NULL) {
  panel(..., id = id, classes = classes, style = style)
}

#' @title TabPanel widget
#' @description A [TabPane] with a Shiny-style `value`, reported by
#'   `input$<tabsetPanel id>` while it is selected. See [tabPanel()].
#' @rdname TabPanel-class
#' @export
TabPanel <- R6::R6Class(
  "TabPanel",
  inherit = TabPane,
  public = list(
    #' @field value The tab's value.
    value = NULL,

    #' @description Create a tab panel. See [tabPanel()].
    #' @param title Tab label.
    #' @param ... Child widgets.
    #' @param value The tab's value; the title by default.
    #' @param id,classes,style See [Widget].
    initialize = function(title, ..., value = NULL, id = NULL, classes = NULL, style = NULL) {
      super$initialize(title, ..., id = id, classes = classes, style = style)
      value <- value %||% as.character(as_text(self$label))
      check_scalar_character(value, "value")
      self$value <- value
    }
  )
)

tab_value <- function(pane) {
  if (inherits(pane, "TabPanel")) return(pane$value)
  pane$id %||% as.character(as_text(pane$label))
}

tab_index_by_value <- function(tabs, selected) {
  check_scalar_character(selected, "selected")
  values <- vapply(tabs$children, tab_value, character(1))
  i <- match(selected, values)
  if (is.na(i)) {
    stop(sprintf("No tab has the value \"%s\" (values: %s).", selected,
                 paste(encodeString(values, quote = "\""), collapse = ", ")), call. = FALSE)
  }
  i
}

# input$<tabs id>: the value of the selected tab, or NULL without tabs.
tabs_selected_value <- function(tabs) {
  pane <- tabs$active_tab
  if (is.null(pane)) NULL else tab_value(pane)
}

#' @rdname shiny_layout
#' @export
tabsetPanel <- function(..., id = NULL, selected = NULL, classes = NULL, style = NULL) {
  w <- tabs(..., id = id, classes = classes, style = style)
  if (!is.null(selected)) w$activate(tab_index_by_value(w, selected))
  w
}

#' @rdname shiny_layout
#' @export
tabPanel <- function(title, ..., value = NULL, id = NULL, classes = NULL, style = NULL) {
  TabPanel$new(title, ..., value = value, id = id, classes = classes, style = style)
}

shiny_text <- function(...) paste(vapply(unlist(list(...)), format_value, character(1)), collapse = " ")

shiny_heading <- function(text_style) {
  function(..., id = NULL, classes = NULL, style = NULL) {
    label(shiny_text(...), id = id, classes = classes, style = merge_styles(text_style, as_style(style)))
  }
}

#' @rdname shiny_layout
#' @export
h1 <- shiny_heading(style(bold = TRUE, underline = TRUE))

#' @rdname shiny_layout
#' @export
h2 <- shiny_heading(style(bold = TRUE))

#' @rdname shiny_layout
#' @export
h3 <- shiny_heading(style(underline = TRUE))

#' @rdname shiny_layout
#' @export
h4 <- shiny_heading(style(italic = TRUE))

#' @rdname shiny_layout
#' @export
p <- function(..., id = NULL, classes = NULL, style = NULL) {
  label(shiny_text(...), id = id, classes = classes, style = merge_styles(style(wrap = "word"), as_style(style)))
}

#' @rdname shiny_layout
#' @export
hr <- function(id = NULL, classes = NULL, style = NULL) rule(id = id, classes = classes, style = style)

#' @rdname shiny_layout
#' @export
br <- function(id = NULL, classes = NULL, style = NULL) label("", id = id, classes = classes, style = style)
