# 4. Headless keyboard and screen test

## Use case

Run a repeatable keyboard interaction check through termr's real event loop and
renderer without opening a terminal UI. The script checks both widget state and
visible screen text.

## Required packages

- `termr`

## Complete runnable test

Save this as `greeting-test.R`:

```r
library(termr)

application <- app(
  vertical(
    label("Name"),
    input(id = "name"),
    button("Greet", id = "greet"),
    label("", id = "result")
  ),
  on("button.pressed", "#greet", function(event, app) {
    app$query_one("#result")$update(
      paste("Hello,", app$query_one("#name")$value)
    )
  }),
  bind("escape", "quit")
)

verify_greeting <- function() {
  pilot <- test_app(application, width = 40, height = 8)
  on.exit(pilot$stop(), add = TRUE)

  pilot$type("Ada")
  pilot$press("tab", "enter")

  screen <- pilot$screen_text()
  stopifnot(identical(pilot$query_one("#result")$text, "Hello, Ada"))
  stopifnot(any(grepl("Hello, Ada", screen, fixed = TRUE)))
  screen
}

verified_screen <- verify_greeting()
cat(verified_screen, sep = "\n")
```

## Execute it

Run `Rscript greeting-test.R`. A successful run exits with status 0 and prints
the virtual screen. An assertion failure stops the script with an error.

## Test it

The script is itself the test. `test_app()` supplies simulated keys and time;
`screen_text()` reads the rendered virtual terminal. Use `on.exit()` inside a
helper function so the pilot is stopped even if an assertion fails.

## Common mistakes

- `pilot$type()` types characters into the focused widget; focus the expected
  input before typing when the app has multiple focusable controls.
- `pilot$press()` takes canonical key names such as `"tab"` and `"enter"`.
- `screen_text()` returns one string per row. Join the rows when a regular
  expression must search across rows, or search each row as this example does.
- Always stop the pilot after use. `on.exit()` handles cleanup when an
  assertion throws an error.

## Public API references

- [Testing guide](../testing.md), [stable API policy](../stability.md)
- [test_app and Pilot reference](../../man/test_app.Rd),
  [app reference](../../man/app.Rd), [input reference](../../man/input.Rd),
  [event handlers](../../man/on.Rd)
