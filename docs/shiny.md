# termr for Shiny users

termr has a Shiny-shaped layer: the same function names, the same
`ui` / `server` split and the same `input` / `output` objects, drawn in a
terminal instead of a browser. It sits on top of termr's own API. Every
function in it builds ordinary termr widgets, handlers and signals, so the
two styles can be mixed in one app.

The layer is experimental (see [API stability](stability.md)). The
snake_case API underneath it is unchanged.

## A first app

```r
library(termr)

ui <- fluidPage(
  textInput("name", "Name", placeholder = "Your name"),
  textOutput("greeting")
)

server <- function(input, output, session) {
  output$greeting <- renderText({ paste("Hello,", input$name) })
}

run(app(ui, server = server))
```

Run it from R started in a real terminal, or with `Rscript app.R`. From
the RStudio or Positron console it opens in the Viewer pane instead, as a
Shiny app would (this needs the httpuv package). Tab moves focus and Ctrl+C
quits. `shinyApp(ui, server)` is
`app(ui, server = server)`, and `runApp()` is `run()`.

## Translation table

### App structure

| Shiny | termr, Shiny layer | termr, native |
|---|---|---|
| `shinyApp(ui, server)` | `app(ui, server = server)` | `app(widgets, on(...), bind(...))` |
| `runApp(app)` | `run(app)` | `run(app)` |
| `server <- function(input, output, session)` | same; `session` is the [App](../man/App-class.Rd) | handlers receive `(event, app)` |
| `session$close()` / `stopApp()` | `session$exit()` | `app$exit()` |
| `showNotification("Saved")` | `session$notify("Saved")` | `app$notify("Saved")` |
| `testServer()` / shinytest2 | `test_app(app(ui, server = server))` | `test_app(app)` |

### Inputs

Every input takes `inputId` first and `label` second. With a label it
returns the label above the control; the id is on the control itself, so
`input$id`, `observeEvent(input$id, ...)` and `app$query_one("#id")` all
find the control.

| Shiny | `input$id` is | termr, native |
|---|---|---|
| `textInput(id, label, value, placeholder)` | character | `input(id = )` |
| `passwordInput(id, label, value)` | character | `input(password = TRUE)` |
| `textAreaInput(id, label, value, rows = )` | character | `text_area()` |
| `numericInput(id, label, value, min, max)` | numeric, `NA` while invalid | `input(validate = )` |
| `checkboxInput(id, label, value)` | logical | `checkbox()` |
| `radioButtons(id, label, choices, selected)` | character | `radio_set()` of `radio_button()` |
| `selectInput(id, label, choices, selected)` | character | `dropdown()` |
| `actionButton(id, label)` | not readable; use `observeEvent()` | `button()` |

Named `choices` work as in Shiny: names are shown, values are returned.
The first choice is selected unless `selected` says otherwise.

### Outputs and render functions

| Shiny | termr, Shiny layer | termr, native |
|---|---|---|
| `textOutput(id)` | `textOutput(id)` | `label(id = )` |
| `verbatimTextOutput(id)` | `verbatimTextOutput(id)` | `label(id = )` in a `panel()` |
| `tableOutput(id)`, `DT::dataTableOutput(id)` | `tableOutput(id)` | `data_table(id = )` |
| `output$x <- renderText({ })` | same | `label(function() ...)` |
| `output$x <- renderPrint({ })` | same | `label(function() capture.output(print(...)))` |
| `output$x <- renderTable({ })` | same, returns a data frame | `app$query_one("#x")$set(data = df)` in a handler |
| `output$x <- "text"` (not allowed in Shiny) | a one-shot write | `app$query_one("#x")$update("text")` |

`tableOutput()` is a full `data_table()`: rows can be navigated, sorted,
searched and selected, and `observeEvent(input$tbl, ...)` fires on a row
selection. Plots have no output; `sparkline()`, `metric()` and
`progress_bar()` are the terminal's charts, and `output$id <- value` writes
them.

### Reactivity

| Shiny | termr, Shiny layer | termr, native |
|---|---|---|
| `reactiveVal(0)` | `reactiveVal(0)` | `signal(0)` |
| `reactive({ a() + 1 })` | `reactive({ a() + 1 })` | `computed(function() a() + 1)` |
| `observe({ })` | `observe({ })` | `watch(function() ...)` |
| `observeEvent(input$go, { })` | `observeEvent(input$go, { })` | `on("button.pressed", "#go", function(event, app) ...)` |
| `observeEvent(rv(), { })` | `observeEvent(rv, { })`, the signal itself | `watch()` that skips its first run |
| `isolate(x())` | `isolate(x())` | `peek(x)` or `untracked(x())` |
| `invalidateLater(1000)` | `invalidateLater(1000)` | `app$set_interval(1, function(app) ...)` |

`observeEvent()` also takes a selector string (`"#go"`, `"Button"`), a
widget object, and `event =` to pick a message other than the widget's
primary one (for example `event = "input.submitted"` to react to Enter in
a text input instead of every keystroke). See `?observeEvent`.

### Updating controls from the server

| Shiny | termr, native |
|---|---|
| `updateTextInput(session, "x", value = )` | `app$query_one("#x")$set(value = )` |
| `updateTextAreaInput()`, `updateNumericInput()`, `updateCheckboxInput()` | the same |
| `updateSelectInput(session, "x", selected = )` | `app$query_one("#x")$set(value = )` |
| `updateRadioButtons(session, "x", selected = )` | the same |
| `updateActionButton(session, "x", label = )` | `app$query_one("#x")$set(label = )` |
| `updateTabsetPanel(session, "tabs", selected = )` | `app$query_one("#tabs")$activate()` |

Each `update*()` also takes `label =`. Inside a server, `session` can be
left out.

### Layout

| Shiny | termr, Shiny layer | termr, native |
|---|---|---|
| `fluidPage(...)` | `fluidPage(...)` | `vertical(..., style = style(padding = c(0, 1)))` |
| `titlePanel("Sales")` | `titlePanel("Sales")` | bold `label()` with a bottom margin |
| `fluidRow(...)` | `row(...)` or `fluidRow(...)` | `horizontal(style = style(height = "auto"))` |
| `column(4, ...)` | `col(4, ...)` | `vertical(style = style(width = "4fr"))` |
| `column(4, offset = 2, ...)` | `col(4, offset = 2, ...)` | an empty `2fr` spacer before it |
| `sidebarLayout(sidebarPanel(), mainPanel())` | same | `horizontal()` with `4fr` and `8fr` children |
| `wellPanel(...)` | `wellPanel(...)` | `panel(...)` |
| `tabsetPanel(id = "t", tabPanel("A", ...))` | same; `input$t` is the selected tab's value | `tabs(tab("A", ...))` |
| `h1()` to `h4()`, `p()`, `hr()`, `br()` | same | styled `label()`, `rule()`, blank `label()` |

The column function is `col()`, not `column()`, because `column()` already
defines `data_table()` columns. `row()` and `col()` mask base R's versions
when termr is attached; given a matrix or a data frame they call base R.

A terminal page does not scroll. A row is as tall as its content, so a
long table in an ordinary row runs off the bottom of the screen. Give that
row `fill = TRUE` and it takes the height the other rows leave; the table
then scrolls inside it. `sidebarLayout()` fills by default.

## One app, written both ways

A filter over `mtcars`: a cylinder choice, a manual-only checkbox, a summary
line, a reset button, and the table. Both versions share two plain R
helpers.

```r
library(termr)

filter_cars <- function(cyl, manual) {
  cars <- mtcars
  if (cyl != "All") cars <- cars[cars$cyl == as.numeric(cyl), ]
  if (manual) cars <- cars[cars$am == 1, ]
  cars
}

describe_cars <- function(cars) {
  sprintf("%d cars, mean mpg %.1f", nrow(cars), mean(cars$mpg))
}
```

### The Shiny way

```r
ui <- fluidPage(
  titlePanel("Motor Trend cars"),
  sidebarLayout(
    sidebarPanel(
      selectInput("cyl", "Cylinders", c("All", "4", "6", "8")),
      checkboxInput("manual", "Manual only"),
      textOutput("summary"),
      actionButton("reset", "Reset")
    ),
    mainPanel(tableOutput("cars"))
  )
)

server <- function(input, output, session) {
  cars <- reactive({ filter_cars(input$cyl, input$manual) })
  output$cars <- renderTable({ cars() })
  output$summary <- renderText({ describe_cars(cars()) })

  observeEvent(input$reset, {
    updateSelectInput(session, "cyl", selected = "All")
    updateCheckboxInput(session, "manual", value = FALSE)
  })
}

shiny_app <- app(ui, server = server)
run(shiny_app)
```

### The termr way

```r
refresh <- function(event, app) {
  cars <- filter_cars(app$query_one("#cyl")$value, app$query_one("#manual")$value)
  app$query_one("#cars")$set(data = cars)
  app$query_one("#summary")$update(describe_cars(cars))
}

termr_app <- app(
  vertical(
    label("Motor Trend cars", style = style(bold = TRUE, margin = c(0, 0, 1, 0))),
    horizontal(
      panel(
        label("Cylinders"),
        dropdown(c("All", "4", "6", "8"), value = "All", id = "cyl"),
        checkbox("Manual only", id = "manual"),
        label(describe_cars(mtcars), id = "summary"),
        button("Reset", id = "reset"),
        style = style(width = "4fr")
      ),
      vertical(data_table(mtcars, id = "cars"), style = style(width = "8fr")),
      style = style(height = "1fr")
    ),
    style = style(padding = c(0, 1))
  ),
  on("dropdown.changed", "#cyl", refresh),
  on("checkbox.changed", "#manual", refresh),
  on("button.pressed", "#reset", function(event, app) {
    app$query_one("#cyl")$set(value = "All")
    app$query_one("#manual")$set(value = FALSE)
  })
)
run(termr_app)
```

### What differs

- **Who recomputes.** In the Shiny version, `cars()` knows it read
  `input$cyl` and `input$manual`, so changing either re-runs it and both
  outputs follow. In the termr version, each control has a handler that
  recomputes by hand, and the summary's starting text is computed
  separately.
- **Where behaviour lives.** The Shiny UI is a pure declaration; everything
  that happens is in `server`. The termr version mixes handlers into the
  `app()` call next to the widgets.
- **Reset.** Both versions only set the controls. Setting a control's value
  sends the same message a user would, so the filters re-run in both.
- **Layout.** `sidebarLayout()` is the `4fr` / `8fr` `horizontal()` with
  `height = "1fr"`, written for you.

## Things that work differently from Shiny

- **`input$button` is not a counter.** Reading an action button is an
  error. React to it with `observeEvent(input$go, ...)`, and keep a
  `reactiveVal()` if you need a count.
- **`input` holds widget values, nothing else.** There is no
  `input$tbl_rows_selected` or `input$tbl_search`. A table's selection
  arrives as `observeEvent(input$tbl, ...)`, with the row in
  `event$data$row` and its values in `event$data$value`.
- **`session` is the app.** It has `exit()`, `notify()`, `push_screen()`,
  `set_timeout()`, `set_interval()` and `query_one()`; it has no
  `sendCustomMessage()`, `userData` or `clientData`.
- **Expressions or functions.** `reactive()`, `observe()`,
  `observeEvent()` and the render functions take a braced expression, as in
  Shiny. A function also works: `observeEvent(input$go, function(event, app) ...)`.
  Expressions see `input`, `output`, `app` and, in `observeEvent()`,
  `event` (or `value` for a signal).
- **`reactive(value)` with a plain value** is the old way to declare a
  custom widget's state field. It still works and warns once; the new name
  is `state()`.
- **Not provided:** `req()`, `validate()` / `need()`, `eventReactive()`,
  `bindEvent()`, `debounce()`, `reactiveValues()`, `renderUI()` /
  `uiOutput()`, `conditionalPanel()`, `downloadButton()`, HTML tags and
  CSS. Return early from an expression instead of `req()`, and use a list
  in a `reactiveVal()` instead of `reactiveValues()`.
- **One user, one process.** A termr app runs in the R session that started
  it. There is no per-user session, no browser and no deployment step.

## Modules

Shiny's `NS()` and `moduleServer()` are not provided. The same reuse comes
from two plain functions sharing an id prefix: one builds the UI with
prefixed ids, the other is called from the server with the same prefix.

```r
counterUI <- function(id, title) {
  ns <- function(name) paste0(id, "-", name)
  wellPanel(h4(title), actionButton(ns("add"), "Add"), textOutput(ns("count")))
}

counterServer <- function(id, input, output) {
  ns <- function(name) paste0(id, "-", name)
  count <- reactiveVal(0L)
  observeEvent(input[[ns("add")]], count(count() + 1L))
  output[[ns("count")]] <- renderText({ count() })
}

counters_app <- app(
  row(col(6, counterUI("left", "Left")), col(6, counterUI("right", "Right"))),
  server = function(input, output, session) {
    counterServer("left", input, output)
    counterServer("right", input, output)
  }
)
run(counters_app)
```

`observeEvent()`, `observe()` and render assignments made anywhere while
the server runs belong to the app, so a module function needs nothing more
than `input` and `output`.

## Testing

`test_app()` runs the app headlessly with simulated keys and time, the
counterpart of shinytest2:

```r
pilot <- test_app(shiny_app, width = 80, height = 24)
updateSelectInput(pilot$app, "cyl", selected = "6")
pilot$step()
pilot$query_one("#summary")$text
pilot$focus("#reset")
pilot$press("enter")
pilot$query_one("#cyl")$value
pilot$stop()
```

`shiny_input(app)` and `shiny_output(app)` give `input` and `output`
objects for an app built outside a server, which is handy at the console.
See [Testing](testing.md) for keys, mouse, resize and snapshots.

## Further reading

- [Reactivity](reactivity.md): what makes a termr app change, and when the
  screen repaints.
- [Layout](layout.md): the `fr` units under `row()` and `col()`.
- [Events](events.md): every message a widget sends, for `observeEvent(event = )`.
- Help pages: `?observeEvent`, `?shiny_inputs`, `?shiny_render`,
  `?shiny_reactive`, `?shiny_layout`, `?shiny_update`, `?shiny_session`.
