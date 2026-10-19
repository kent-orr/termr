# 3. Navigable data table

## Use case

Display an in-memory data frame, move through its rows with the keyboard, and
show the selected record. The table also enables header sorting.

## Required packages

- `termr`

## Complete app

Save this code as `table-app.R`:

```r
library(termr)

items <- data.frame(
  item = c("Tea", "Coffee", "Apple"),
  units = c(5L, 8L, 3L),
  stringsAsFactors = FALSE
)

items_table <- data_table(
  items,
  id = "items",
  zebra = TRUE,
  header_sort = TRUE
)

application <- app(
  vertical(
    label("Inventory"),
    items_table,
    label("Use Up/Down to select a row. Click a header or press S to sort.", id = "selection")
  ),
  on("datatable.row_selected", "#items", function(event, app) {
    row <- event$data$value
    app$query_one("#selection")$update(
      sprintf("Selected: %s (%d units)", row$item, row$units)
    )
  }),
  bind("q", "quit")
)
```

## Execute it

Save the code as `table-app.R`, then run this in a real terminal:

```sh
Rscript -e "source('table-app.R'); termr::run(application)"
```

Use Up and Down to move the row cursor. Click a column header or press S to
sort by the active column. Press q to exit.

## Test it

```r
source("table-app.R")
pilot <- test_app(application, width = 60, height = 8)
pilot$press("down")
stopifnot(identical(pilot$query_one("#selection")$text, "Selected: Coffee (8 units)"))
items_table$sort("units", decreasing = TRUE)
pilot$step()
stopifnot(identical(items_table$sort_state$column, "units"))
stopifnot(grepl("Coffee", pilot$screen_text()[[3]], fixed = TRUE))
pilot$stop()
```

## Common mistakes

- `data_table()` accepts a data frame or matrix. Lazy table sources and database
  adapters are experimental; this recipe uses the stable in-memory path.
- `datatable.row_selected` reports the selected row in `event$data$value` as a
  named list, and includes the original row number in `event$data$row`.
- Sorting via `header_sort = TRUE` is interactive. The documented
  `items_table$sort()` method is useful when an app or test needs to sort
  programmatically.
- Database queries and table-source page fetches are synchronous; this recipe
  does not connect to a database.

## Public API references

- [Stable API policy](../stability.md), [data guide](../data.md),
  [events guide](../events.md)
- [data table reference](../../man/data_table.Rd), [table class and methods](../../man/DataTable-class.Rd),
  [app reference](../../man/app.Rd), [headless testing](../../man/test_app.Rd)
