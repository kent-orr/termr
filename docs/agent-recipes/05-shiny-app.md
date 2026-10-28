# 5. Shiny-style app

## Use case

Write a terminal app the way a Shiny app is written: a `ui` built from
Shiny-named constructors and a `server(input, output, session)` that
derives values with `reactive()`, fills outputs with render functions and
reacts to a button with `observeEvent()`. See
[termr for Shiny users](../shiny.md) for the full translation.

## Required packages

- `termr`

## Complete app

Save this code as `shiny-app.R`:

```r
library(termr)

items <- data.frame(
  item = c("Apple", "Coffee", "Bread", "Milk"),
  units = c(4, 8, 12, 10)
)

ui <- fluidPage(
  titlePanel("Stock"),
  sidebarLayout(
    sidebarPanel(
      numericInput("min", "Minimum units", value = 0, min = 0),
      textOutput("summary"),
      actionButton("reset", "Reset")
    ),
    mainPanel(tableOutput("items"))
  )
)

server <- function(input, output, session) {
  shown <- reactive({
    if (is.na(input$min)) items else items[items$units >= input$min, ]
  })
  output$items <- renderTable({ shown() })
  output$summary <- renderText({
    paste(nrow(shown()), "items,", sum(shown()$units), "units")
  })
  observeEvent(input$reset, {
    updateNumericInput(session, "min", value = 0)
  })
}

application <- app(ui, server = server)
```

## Execute it

Run from a real terminal, not an IDE console:

```sh
Rscript -e "source('shiny-app.R'); termr::run(application)"
```

Type a number into "Minimum units"; the table and the summary follow as you
type. Tab to Reset and press Enter to clear the filter. Ctrl+C exits.

## Test it

```r
source("shiny-app.R")
pilot <- test_app(application, width = 60, height = 16)
pilot$focus("#min")
pilot$press("backspace")
pilot$type("5")
stopifnot(identical(pilot$query_one("#summary")$text, "3 items, 30 units"))
pilot$focus("#reset")
pilot$press("enter")
stopifnot(identical(nrow(pilot$query_one("#items")$data), 4L))
pilot$stop()
```

## Common mistakes

- `shinyApp(ui, server)` does not exist; use `app(ui, server = server)`.
- The layout column is `col()`; `column()` defines `data_table()` columns.
- `input$reset` cannot be read: an action button has no value. React to it
  with `observeEvent(input$reset, ...)`.
- `numericInput()` gives `NA` while its text is empty or not a number in
  range; handle `NA` in the reactive expression.
- The Shiny-shaped layer is experimental; the native API in recipes 1 to 4
  is stable.

## Public API references

- [termr for Shiny users](../shiny.md), [reactivity](../reactivity.md)
- [observeEvent](../../man/observeEvent.Rd), [inputs](../../man/shiny_inputs.Rd),
  [render functions](../../man/shiny_render.Rd),
  [reactive functions](../../man/shiny_reactive.Rd),
  [layout](../../man/shiny_layout.Rd), [update functions](../../man/shiny_update.Rd),
  [headless testing](../../man/test_app.Rd)
