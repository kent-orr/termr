# Phase 3: Shiny-style layout ------------------------------------------------

widths_of <- function(...) vapply(list(...), function(w) w$region$width, 1L)
xs_of <- function(...) vapply(list(...), function(w) w$region$x, 1L)

test_that("col() widths are shares of a 12-column row", {
  a <- col(4, label("a"), id = "a")
  b <- col(8, label("b"), id = "b")
  root <- row(a, b)
  expect_true(inherits(root, "Horizontal"))
  expect_true(inherits(a, "Col"))
  expect_identical(a$span, 4L)
  layout_tree(root, rect(1, 1, 24, 3))
  expect_identical(widths_of(a, b), c(8L, 16L))
  expect_identical(xs_of(a, b), c(1L, 9L))
})

test_that("a row whose columns sum to less than 12 leaves the rest empty", {
  a <- col(4, label("a"))
  b <- col(4, label("b"))
  root <- row(a, b)
  layout_tree(root, rect(1, 1, 24, 3))
  expect_identical(widths_of(a, b), c(8L, 8L))
  expect_length(root$children, 3L)
})

test_that("offset pushes a column right by that many grid columns", {
  a <- col(4, label("a"), offset = 2)
  b <- col(6, label("b"))
  root <- row(a, b)
  layout_tree(root, rect(1, 1, 24, 3))
  expect_identical(xs_of(a, b), c(5L, 13L))
  expect_identical(widths_of(a, b), c(8L, 12L))
})

test_that("columns past 12 wrap onto a new line, as in Shiny", {
  a <- col(6, label("a"))
  b <- col(6, label("b"))
  c <- col(6, label("c"))
  root <- row(a, b, c, id = "cards")
  expect_identical(root$id, "cards")
  layout_tree(root, rect(1, 1, 24, 6))
  expect_identical(c(a$region$y, b$region$y, c$region$y), c(1L, 1L, 2L))
  expect_identical(widths_of(a, b, c), c(12L, 12L, 12L))
})

test_that("a row of other widgets is a plain horizontal()", {
  a <- label("a")
  b <- label("b")
  root <- row(a, b)
  expect_true(inherits(root, "Horizontal"))
  expect_length(root$children, 2L)
  expect_identical(fluidRow(label("x"))$computed_style()$height$type, "auto")
})

test_that("row(fill = TRUE) takes the leftover height so a long table scrolls", {
  side <- col(4, label("side"))
  tbl <- tableOutput("cars")
  main <- col(8, tbl)
  page <- fluidPage(titlePanel("Cars"), row(side, main, fill = TRUE), label("footer", id = "foot"))
  tbl$data <- mtcars
  layout_tree(page, rect(1, 1, 40, 12))
  # title (1) + blank line (1) + footer (1) leave 9 rows for the filled row.
  expect_identical(main$region$height, 9L)
  expect_identical(side$region$height, 9L)
  expect_identical(tbl$region$height, 9L)
  expect_identical(page$query_one("#foot")$region$y, 12L)

  # Without fill the row is as tall as its content and the table runs off the screen.
  tbl2 <- tableOutput("cars2")
  tbl2$data <- mtcars
  page2 <- fluidPage(row(col(12, tbl2)))
  layout_tree(page2, rect(1, 1, 40, 12))
  expect_gt(tbl2$region$height, 12L)

  # An explicit height on a column wins over fill.
  fixed <- col(6, label("x"), style = style(height = 3))
  layout_tree(row(fixed, fill = TRUE), rect(1, 1, 24, 10))
  expect_identical(fixed$region$height, 3L)
})

test_that("col() validates width and offset", {
  expect_error(col(0), "width")
  expect_error(col(13), "width")
  expect_error(col(2.5), "width")
  expect_error(col(4, offset = -1), "offset")
  expect_error(col(8, offset = 6), "12")
})

test_that("row() and col() still work on matrices, as base R's do", {
  m <- matrix(1:6, 2)
  expect_identical(row(m), base::row(m))
  expect_identical(col(m), base::col(m))
  expect_identical(col(m, as.factor = TRUE), base::col(m, as.factor = TRUE))
  expect_identical(row(as.data.frame(m)), base::row(as.data.frame(m)))
})

test_that("fluidRow() is row()", {
  a <- col(6, label("a"))
  root <- fluidRow(a, col(6, label("b")))
  layout_tree(root, rect(1, 1, 24, 3))
  expect_identical(a$region$width, 12L)
})

test_that("fluidPage pads its content and titlePanel shows a bold title", {
  t <- titlePanel("Sales")
  expect_true(inherits(t, "Label"))
  expect_true(attrs_decode(t$computed_style()$attrs)[["bold"]])
  body <- label("body")
  page <- fluidPage(t, body)
  expect_true(inherits(page, "Vertical"))
  layout_tree(page, rect(1, 1, 24, 6))
  expect_identical(body$region$x, 2L)
  expect_identical(body$region$y, 3L) # title, then a blank line below it
  lines <- strip_ansi(render_lines(fluidPage(titlePanel("Sales")), 24, 3))
  expect_match(lines[[1]], "^ Sales")
})

test_that("sidebarLayout splits 4/8 by default and can put the sidebar on the right", {
  side <- sidebarPanel(label("filters"))
  main <- mainPanel(label("content"))
  expect_true(inherits(side, "Panel"))
  layout <- sidebarLayout(side, main)
  layout_tree(layout, rect(1, 1, 24, 10))
  expect_identical(widths_of(side, main), c(8L, 16L))
  expect_identical(xs_of(side, main), c(1L, 9L))
  expect_identical(side$region$height, 10L)

  side <- sidebarPanel(label("filters"), width = 3)
  main <- mainPanel(label("content"), width = 9)
  layout <- sidebarLayout(side, main, position = "right")
  layout_tree(layout, rect(1, 1, 24, 10))
  expect_identical(xs_of(main, side), c(1L, 19L))
  expect_identical(widths_of(main, side), c(18L, 6L))
  expect_error(sidebarLayout(side, main, position = "top"), "position")
})

test_that("wellPanel is a bordered panel", {
  w <- wellPanel(label("inside"), id = "well")
  expect_true(inherits(w, "Panel"))
  expect_identical(w$id, "well")
  lines <- render_lines(w, 12, 3)
  expect_match(strip_ansi(lines[[2]]), "inside")
})

test_that("headings, paragraphs, rules and breaks build labels and rules", {
  expect_true(inherits(h1("Title"), "Label"))
  expect_true(attrs_decode(h1("Title")$computed_style()$attrs)[["bold"]])
  for (h in list(h2, h3, h4)) expect_true(inherits(h("x"), "Label"))
  expect_true(inherits(hr(), "Rule"))
  expect_identical(br()$text, "")
  para <- p("A long sentence", "that wraps.")
  expect_identical(para$text, "A long sentence that wraps.")
  expect_identical(para$computed_style()$wrap, "word")
})

test_that("tabsetPanel and tabPanel build tabs and report the selected value", {
  ui <- tabsetPanel(
    tabPanel("Plot view", label("plot")),
    tabPanel("Summary", label("summary"), value = "sum"),
    id = "tabs", selected = "sum"
  )
  expect_true(inherits(ui, "Tabs"))
  expect_identical(ui$active, 2L)
  expect_identical(ui$active_tab$value, "sum")
  seen <- character()
  a <- app(ui, server = function(input, output, session) {
    observeEvent(input$tabs, seen <<- c(seen, input$tabs))
  })
  pilot <- test_app(a, 30, 5)
  expect_identical(shiny_input(a)$tabs, "sum")
  updateTabsetPanel(a, "tabs", selected = "Plot view")
  pilot$step()
  expect_identical(shiny_input(a)$tabs, "Plot view")
  expect_identical(seen, "Plot view")
  expect_error(updateTabsetPanel(a, "tabs", selected = "nope"), "nope")
  pilot$stop()
  expect_error(tabsetPanel(tabPanel("A"), selected = "B"), "B")
})

test_that("a renderText that reads the selected tab updates when it changes", {
  ui <- vertical(
    tabsetPanel(tabPanel("One", label("1")), tabPanel("Two", label("2")), id = "tabs"),
    textOutput("which")
  )
  a <- app(ui, server = function(input, output, session) {
    output$which <- renderText(paste("on", input$tabs))
  })
  pilot <- test_app(a, 30, 6)
  expect_identical(pilot$query_one("#which")$text, "on One")
  updateTabsetPanel(a, "tabs", selected = "Two")
  pilot$step()
  expect_identical(pilot$query_one("#which")$text, "on Two")
  pilot$stop()
})

test_that("the PLAN.md phase 3 example lays out a full page", {
  sales <- data.frame(year = c("2025", "2026", "2026"), amount = c(10, 20, 30))
  ui <- fluidPage(
    titlePanel("Sales"),
    sidebarLayout(
      sidebarPanel(selectInput("year", "Year", c("2025", "2026"))),
      mainPanel(tableOutput("tbl"))
    ),
    fluidRow(
      col(6, metric("Rows", nrow(sales))),
      col(6, metric("Total", sum(sales$amount)))
    )
  )
  a <- app(ui, server = function(input, output, session) {
    output$tbl <- renderTable(sales[sales$year == input$year, ])
  })
  pilot <- test_app(a, 60, 20)
  text <- paste(pilot$screen_text(), collapse = "\n")
  expect_match(text, "Sales")
  expect_match(text, "Year")
  expect_match(text, "Rows")
  expect_match(text, "Total")
  expect_identical(nrow(pilot$query_one("#tbl")$data), 1L)
  tbl <- pilot$query_one("#tbl")
  # The sidebar layout takes the height left over by the title and the metrics row.
  expect_gt(tbl$region$height, 8L)
  pilot$stop()
})

test_that("the README Shiny example runs, filters and quits", {
  ui <- fluidPage(
    titlePanel("Motor Trend cars"),
    row(
      col(4, wellPanel(
        selectInput("cyl", "Cylinders", c("All", "4", "6", "8")),
        textOutput("summary"),
        actionButton("quit", "Quit")
      )),
      col(8, tableOutput("cars")),
      fill = TRUE
    )
  )
  server <- function(input, output, session) {
    cars <- reactive({
      if (input$cyl == "All") mtcars else mtcars[mtcars$cyl == as.numeric(input$cyl), ]
    })
    output$cars <- renderTable(cars())
    output$summary <- renderText(paste(nrow(cars()), "cars, mean mpg", round(mean(cars()$mpg), 1)))
    observeEvent(input$quit, session$exit())
  }
  a <- app(ui, server = server)
  pilot <- test_app(a, 80, 24)
  expect_identical(pilot$query_one("#summary")$text, "32 cars, mean mpg 20.1")
  expect_lte(pilot$query_one("#cars")$region$height, 22L)
  updateSelectInput(a, "cyl", selected = "6")
  pilot$step()
  expect_identical(nrow(pilot$query_one("#cars")$data), 7L)
  expect_match(pilot$query_one("#summary")$text, "^7 cars")
  pilot$focus("#quit")
  pilot$press("enter")
  expect_false(a$running)
  pilot$stop()
})
