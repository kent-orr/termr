agent_recipe_code <- function(name) {
  path <- testthat::test_path("..", "..", "docs", "agent-recipes", name)
  testthat::skip_if_not(file.exists(path),
    "Recipe Markdown is excluded from package builds; run this check from the source checkout.")
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  start <- grep("^```r$", trimws(lines))
  if (!length(start)) stop("No R code block in ", name, call. = FALSE)
  end <- which(seq_along(lines) > start[[1]] & trimws(lines) == "```")
  if (!length(end)) stop("Unclosed R code block in ", name, call. = FALSE)
  env <- new.env(parent = globalenv())
  eval(parse(text = lines[seq.int(start[[1]] + 1L, end[[1]] - 1L)]),
       envir = env)
  env
}

test_that("basic app recipe builds and greets in the headless pilot", {
  recipe <- agent_recipe_code("01-basic-app.md")
  pilot <- test_app(recipe$application, width = 40, height = 10)
  on.exit(pilot$stop(), add = TRUE)
  pilot$type("Ada")
  pilot$press("tab", "enter")
  expect_identical(pilot$query_one("#output")$text, "Hello, Ada")
})

test_that("validated form recipe handles invalid and valid input", {
  recipe <- agent_recipe_code("02-reactive-form.md")
  pilot <- test_app(recipe$application, width = 40, height = 10)
  on.exit(pilot$stop(), add = TRUE)
  pilot$press("enter")
  expect_identical(pilot$query_one("#feedback")$text, "Enter a name.")
  pilot$type("Ada")
  pilot$press("enter")
  expect_identical(pilot$query_one("#feedback")$text, "Hello, Ada")
  expect_true(pilot$query_one("#name")$valid)
})

test_that("data table recipe navigates and sorts rows", {
  recipe <- agent_recipe_code("03-data-table.md")
  pilot <- test_app(recipe$application, width = 60, height = 8)
  on.exit(pilot$stop(), add = TRUE)
  pilot$press("down")
  expect_identical(pilot$query_one("#selection")$text, "Selected: Coffee (8 units)")
  pilot$press("s")
  expect_identical(recipe$items_table$sort_state$column, "item")
  expect_match(pilot$screen_text()[[3]], "Apple", fixed = TRUE)
  recipe$items_table$sort("units", decreasing = TRUE)
  pilot$step()
  expect_identical(recipe$items_table$sort_state$column, "units")
  expect_match(pilot$screen_text()[[3]], "Coffee", fixed = TRUE)
})

test_that("headless test recipe executes its keyboard and screen assertions", {
  recipe <- agent_recipe_code("04-headless-testing.md")
  expect_true(is.character(recipe$verified_screen))
  expect_true(any(grepl("Hello, Ada", recipe$verified_screen, fixed = TRUE)))
})
