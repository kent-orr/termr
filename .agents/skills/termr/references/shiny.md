# Shiny-style termr apps

termr has a Shiny-shaped layer: `fluidPage()`, `textInput()`,
`observeEvent()`, `renderText()` and the rest, with a `ui` and a
`server(input, output, session)`. It draws in a terminal, not a browser.
Use it when the user knows Shiny, writes Shiny-style code, or wants a
Shiny app's logic in a terminal. Do not use it to build or deploy a web
app; that is Shiny itself.

The layer is experimental; the snake_case API under it is stable. Both
styles can be mixed in one app. The runnable starter is
[assets/shiny-app.R](../assets/shiny-app.R).

## A complete app

```r
library(termr)

ui <- fluidPage(
  titlePanel("Motor Trend cars"),
  sidebarLayout(
    sidebarPanel(
      selectInput("cyl", "Cylinders", c("All", "4", "6", "8")),
      numericInput("mpg", "Minimum mpg", value = 0, min = 0),
      textOutput("summary"),
      actionButton("reset", "Reset")
    ),
    mainPanel(tableOutput("cars"))
  )
)

server <- function(input, output, session) {
  cars <- reactive({
    cars <- mtcars
    if (input$cyl != "All") cars <- cars[cars$cyl == as.numeric(input$cyl), ]
    if (!is.na(input$mpg)) cars <- cars[cars$mpg >= input$mpg, ]
    cars
  })
  output$cars <- renderTable({ cars() })
  output$summary <- renderText({ paste(nrow(cars()), "cars") })
  observeEvent(input$reset, {
    updateSelectInput(session, "cyl", selected = "All")
    updateNumericInput(session, "mpg", value = 0)
  })
}

application <- app(ui, server = server)
```

Run it with `run(application)` in a real terminal.

## Rules that differ from Shiny

- `shinyApp(ui, server)` is `app(ui, server = server)`; `runApp()` is
  `run()`. `session` is the termr `App`: `session$exit()`,
  `session$notify()`, `session$set_interval()`.
- The layout column is `col(width, ...)`, not `column()`, which defines
  `data_table()` columns. `row()` / `fluidRow()` hold columns on a
  12-column grid.
- A terminal page does not scroll. Put a long table in
  `sidebarLayout()`/`mainPanel()` or in `row(..., fill = TRUE)` so it scrolls
  inside the screen instead of running off it.
- `input$<button>` is not a counter and cannot be read; use
  `observeEvent(input$go, ...)`. `numericInput()` gives `NA` while its text
  is not a valid number in range.
- `tableOutput()` is an interactive `data_table()`. A row selection arrives
  as `observeEvent(input$tbl, ...)` with `event$data$row` and
  `event$data$value`.
- Outputs: `textOutput()`, `verbatimTextOutput()`, `tableOutput()`, with
  `renderText()`, `renderPrint()`, `renderTable()`. `output$id <- value`
  is a one-shot write and also works for `metric()`, `progress_bar()`,
  `sparkline()` and buttons.
- Not available: `req()`, `validate()`, `eventReactive()`,
  `reactiveValues()`, `renderUI()`, `renderPlot()`, HTML tags, CSS,
  `NS()`/`moduleServer()`. For modules, prefix ids (`paste0(id, "-add")`)
  and call a plain server-side function with `input` and `output`.
- `observeEvent()`, `reactive()`, `observe()` and the render functions take
  a braced expression or a function.

## Testing

```r
pilot <- test_app(application, width = 80, height = 24)
updateSelectInput(pilot$app, "cyl", selected = "6")
pilot$step()
stopifnot(identical(pilot$query_one("#summary")$text, "7 cars"))
pilot$focus("#reset")
pilot$press("enter")
stopifnot(identical(pilot$query_one("#cyl")$value, "All"))
pilot$stop()
```

`pilot$focus("#id")` then `pilot$type()` / `pilot$press()` simulate the
user; `updateXInput(pilot$app, ...)` changes a control from the test.
