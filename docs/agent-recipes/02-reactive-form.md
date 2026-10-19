# 2. Form with validation

## Use case

Collect a name, show a validation message for blank input, and submit a greeting.
The input's documented validator and validity fields provide the state; this
recipe does not need the experimental signal graph.

## Required packages

- `termr`

## Complete app

Save this code as `validated-form.R`:

```r
library(termr)

name_input <- input(
  id = "name",
  placeholder = "Your name",
  validate = function(value) {
    if (nzchar(trimws(value))) NULL else "Enter a name."
  }
)

submit_form <- function(event, app) {
  name <- trimws(app$query_one("#name")$value)
  feedback <- app$query_one("#feedback")

  if (!nzchar(name)) {
    feedback$update("Enter a name.")
    return(invisible(NULL))
  }

  feedback$update(paste("Hello,", name))
}

application <- app(
  vertical(
    label("Name"),
    name_input,
    button("Submit", id = "submit", variant = "primary"),
    label("", id = "feedback")
  ),
  on("input.submitted", "#name", submit_form),
  on("button.pressed", "#submit", submit_form),
  bind("escape", "quit")
)
```

## Execute it

Save the code as `validated-form.R`, then run this in a real terminal:

```sh
Rscript -e "source('validated-form.R'); termr::run(application)"
```

Press Enter in the blank field to see the validation message. Enter a name,
then press Enter or Tab to Submit and press Enter. Escape exits.

## Test it

```r
source("validated-form.R")
pilot <- test_app(application, width = 40, height = 10)
pilot$press("enter")
stopifnot(identical(pilot$query_one("#feedback")$text, "Enter a name."))
pilot$type("Ada")
pilot$press("enter")
stopifnot(identical(pilot$query_one("#feedback")$text, "Hello, Ada"))
stopifnot(isTRUE(pilot$query_one("#name")$valid))
pilot$stop()
```

## Common mistakes

- A validator returns `NULL` or `TRUE` for valid input and an error message
  for invalid input. It does not return a logical vector of problems.
- `input.submitted` is sent when Enter is pressed in the input. A separate
  `button.pressed` handler is needed for the Submit button.
- Use `app$query_one()` to find mounted widgets in an event handler. The
  `Input` created before `app()` is not the source of the event data.
- Validation trims whitespace here deliberately; termr itself preserves
  spaces the user types.

## Public API references

- [Stable API policy](../stability.md), [events guide](../events.md)
- [input reference](../../man/input.Rd), [app reference](../../man/app.Rd),
  [event handlers](../../man/on.Rd), [headless testing](../../man/test_app.Rd)
