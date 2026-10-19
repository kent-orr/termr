# Minimal stable termr application.
# Run from a real terminal with: Rscript minimal-app.R

library(termr)

application <- app(
  vertical(
    label("What is your name?"),
    input(id = "name", placeholder = "Your name"),
    button("Say hello", id = "hello", variant = "primary"),
    label("", id = "output")
  ),
  on("button.pressed", "#hello", function(event, app) {
    name <- app$query_one("#name")$value
    app$query_one("#output")$update(paste("Hello,", name))
  }),
  bind("escape", "quit")
)

run(application)
