# Application recipes

These compact patterns use stable application APIs. The runnable starter is
in [assets/minimal-app.R](../assets/minimal-app.R). Each app can be driven
headlessly with `test_app()` before running it in a real terminal.

## Form with validation

Use the `Input` widget's validator and handle both Enter in the field and a
Submit button:

```r
name_input <- input(id = "name", validate = function(value) {
  if (nzchar(trimws(value))) NULL else "Enter a name."
})

submit <- function(event, app) {
  name <- trimws(app$query_one("#name")$value)
  app$query_one("#feedback")$update(
    if (nzchar(name)) paste("Hello,", name) else "Enter a name."
  )
}

application <- app(
  vertical(name_input, button("Submit", id = "submit"), label("", id = "feedback")),
  on("input.submitted", "#name", submit),
  on("button.pressed", "#submit", submit),
  bind("escape", "quit")
)
```

## Navigable, sortable in-memory table

```r
records <- data.frame(item = c("Tea", "Coffee"), units = c(5L, 8L))
table <- data_table(records, id = "records", header_sort = TRUE, zebra = TRUE)
application <- app(
  vertical(table, label("Use arrows to select; S sorts the active column.")),
  bind("q", "quit")
)
```

Use Up/Down to move between rows. Click a header or focus the table and press
`s` to sort. To sort from app code, the documented table method is
`table$sort("units", decreasing = TRUE)`. For a selected row, handle
`datatable.row_selected` and read its named row from `event$data$value`.

## Keep UI handlers small

Use `on("event.name", "#widget-id", function(event, app) ...)` to respond to
documented widget events. Put validation or small state changes in the
handler, then update the mounted output widget with its documented method.
For larger workflows, check the API stability guide before using termr's
experimental workers, signals, or database integrations.
