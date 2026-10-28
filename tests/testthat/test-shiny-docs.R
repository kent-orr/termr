# The Shiny guide, the reactivity guide and the agent skill's Shiny material
# are executable: every ```r block runs, in order, in one environment, with
# run() recording the app instead of taking over a terminal.

source_doc <- function(...) {
  path <- testthat::test_path("..", "..", ...)
  testthat::skip_if_not(file.exists(path),
    "Documentation is excluded from package builds; run this check from the source checkout.")
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- which(trimws(lines) == "```r")
  fences <- which(trimws(lines) == "```")
  expect_gt(length(starts), 0L)
  env <- new.env(parent = globalenv())
  env$run <- function(x, ...) {
    env$.ran <- c(env$.ran, list(x))
    invisible(x)
  }
  for (s in starts) {
    e <- min(fences[fences > s])
    code <- lines[seq.int(s + 1L, e - 1L)]
    utils::capture.output(eval(parse(text = code), envir = env))
  }
  env
}

source_script <- function(...) {
  path <- testthat::test_path("..", "..", ...)
  testthat::skip_if_not(file.exists(path),
    "The agent skill is excluded from package builds; run this check from the source checkout.")
  env <- new.env(parent = globalenv())
  env$run <- function(x, ...) {
    env$.ran <- c(env$.ran, list(x))
    invisible(x)
  }
  sys.source(path, envir = env)
  env
}

# Drive the cars example of docs/shiny.md the same way in either spelling.
drive_cars <- function(application) {
  pilot <- test_app(application, width = 80, height = 24)
  on.exit(pilot$stop(), add = TRUE)
  rows <- function() nrow(pilot$query_one("#cars")$data)
  summary <- function() pilot$query_one("#summary")$text
  out <- list(start = c(rows(), summary()))
  cyl <- pilot$query_one("#cyl")
  cyl$value <- "6"
  pilot$step()
  out$six <- c(rows(), summary())
  pilot$focus("#manual")
  pilot$press("space")
  out$manual <- c(rows(), summary())
  pilot$focus("#reset")
  pilot$press("enter")
  out$reset <- c(rows(), summary(), pilot$query_one("#cyl")$value, pilot$query_one("#manual")$value)
  out
}

test_that("docs/shiny.md runs and its example behaves the same written both ways", {
  doc <- source_doc("docs", "shiny.md")
  expect_true(inherits(doc$termr_app, "App"))
  expect_true(inherits(doc$shiny_app, "App"))
  native <- drive_cars(doc$termr_app)
  shiny <- drive_cars(doc$shiny_app)
  expect_identical(native, shiny)
  expect_identical(shiny$start[[1]], "32")
  expect_identical(shiny$six[[1]], "7")
  expect_identical(shiny$manual[[1]], "3")
  expect_identical(shiny$reset[c(1, 3, 4)], c("32", "All", "FALSE"))
  expect_match(shiny$six[[2]], "7 cars")
})

test_that("docs/shiny.md module example keeps two counters apart by id prefix", {
  doc <- source_doc("docs", "shiny.md")
  pilot <- test_app(doc$counters_app, width = 40, height = 10)
  on.exit(pilot$stop(), add = TRUE)
  pilot$focus("#left-add")
  pilot$press("enter", "enter")
  pilot$focus("#right-add")
  pilot$press("enter")
  expect_identical(pilot$query_one("#left-count")$text, "2")
  expect_identical(pilot$query_one("#right-count")$text, "1")
})

test_that("docs/reactivity.md runs every block", {
  doc <- source_doc("docs", "reactivity.md")
  expect_true(length(doc$.ran) >= 1L)
  for (a in doc$.ran) expect_true(inherits(a, "App"))
})

test_that("the agent skill's Shiny reference and template run", {
  ref <- source_doc(".agents", "skills", "termr", "references", "shiny.md")
  expect_true(inherits(ref$application, "App"))
  tpl <- source_script(".agents", "skills", "termr", "assets", "shiny-app.R")
  expect_length(tpl$.ran, 1L)
  pilot <- test_app(tpl$application, width = 40, height = 8)
  on.exit(pilot$stop(), add = TRUE)
  pilot$focus("#name")
  pilot$type("Ada")
  expect_identical(pilot$query_one("#greeting")$text, "Hello, Ada")
})

test_that("the agent skill routes Shiny-shaped terminal requests to termr", {
  path <- testthat::test_path("..", "..", ".agents", "skills", "termr", "SKILL.md")
  testthat::skip_if_not(file.exists(path), "The agent skill is excluded from package builds.")
  skill <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_false(grepl("Do not use for Shiny applications", skill, fixed = TRUE))
  expect_match(skill, "references/shiny.md", fixed = TRUE)
})
