# Headless testing and verification

`test_app(application, width, height)` starts termr's normal event loop with a
headless driver. It simulates input and time, renders through the regular
renderer, and returns a pilot. It does not require a terminal.

```r
verify_greeting <- function(application) {
  pilot <- test_app(application, width = 40, height = 10)
  on.exit(pilot$stop(), add = TRUE)

  pilot$type("Ada")
  pilot$press("tab", "enter")
  stopifnot(identical(pilot$query_one("#result")$text, "Hello, Ada"))
  stopifnot(any(grepl("Hello, Ada", pilot$screen_text(), fixed = TRUE)))
}

verify_greeting(application)
```

Useful pilot methods include:

- `type(text)`, `paste(text)`, and `press(...)` for text and keys.
- `click(selector)` and `scroll(selector, direction)` for pointer behavior.
- `resize(width, height)` and `advance(seconds)` for layout and simulated
  timers.
- `query_one(selector)` and `screen_text()` for widget state and visible text.
- `stop()` to clean up the pilot.

For package tests, use testthat (`Suggests`) and assertions such as
`expect_identical()`, `expect_true()`, and `expect_snapshot()`. Prefer stable
state and text assertions; terminal colors, Unicode borders, and platform
terminal behavior may depend on the host. Do not accept changed snapshots
without reviewing why they changed.

Run interactive apps with `run(application)` from a real terminal. A passing
headless test verifies app logic and rendered output in the virtual terminal;
it does not establish behavior in every terminal or operating system. Consult
the package's platform testing guide for PTY and Windows console coverage.
