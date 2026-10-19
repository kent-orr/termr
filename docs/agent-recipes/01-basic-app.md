# 1. Basic app

## Use case

Start with a small terminal app that accepts a name and displays a greeting.
This follows the pattern in [Getting started](../getting-started.md) and the
bundled `form` example.

## Required packages

- `termr`

## Complete app

Save this code as `basic-app.R`:

```r
library(termr)

ui <- vertical(
  label("What is your name?"),
  input(id = "name", placeholder = "Your name"),
  button("Say hello", id = "hello", variant = "primary"),
  label("", id = "output")
)

application <- app(
  ui,
  on("button.pressed", "#hello", function(event, app) {
    name <- app$query_one("#name")$value
    app$query_one("#output")$update(paste("Hello,", name))
  }),
  bind("escape", "quit")
)
```

## Execute it

Run from a real terminal, not an IDE console:

```sh
Rscript -e "source('basic-app.R'); termr::run(application)"
```

Type a name, press Tab, then Enter. Escape exits the app.

## Test it

The headless pilot drives the same event loop without taking over a terminal:

```r
source("basic-app.R")
pilot <- test_app(application, width = 40, height = 10)
pilot$type("Ada")
pilot$press("tab", "enter")
stopifnot(identical(pilot$query_one("#output")$text, "Hello, Ada"))
pilot$stop()
```

## Common mistakes

- `run()` needs a real terminal. Use `test_app()` for automated input and
  rendering checks.
- Widget lookup uses selectors such as `#name`; give a widget an `id` before
  querying it.
- The button handler reads the input widget's `$value`; it does not receive
  the input value as the button event's data.

## Public API references

- [Stable API policy](../stability.md)
- [Getting started](../getting-started.md)
- [App and run reference](../../man/app.Rd), [event handlers](../../man/on.Rd),
  [bindings](../../man/bind.Rd), [input](../../man/input.Rd),
  [button](../../man/button.Rd), [headless testing](../../man/test_app.Rd)
