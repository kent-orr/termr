# Agent recipes

Short, verified patterns for building and testing termr applications. The
first three recipes define apps that can be run in a real terminal and driven
headlessly with `test_app()`. The fourth is a standalone headless test script.
The fifth writes an app the Shiny way, with a `ui` and a `server`.

## Index

1. [Basic app](01-basic-app.md) — input, button, event handler, and greeting.
2. [Form with validation](02-reactive-form.md) — built-in input validation and
   submission feedback without the experimental reactive graph.
3. [Navigable data table](03-data-table.md) — in-memory table navigation,
   selection, and sorting.
4. [Headless keyboard and screen test](04-headless-testing.md) — keyboard
   input, widget state, rendered screen output, and cleanup.
5. [Shiny-style app](05-shiny-app.md) — `ui` / `server`, `reactive()`,
   render functions, `observeEvent()` and `update*Input()`.

## Validation results

The examples are executed by `tests/testthat/test-agent-recipes.R` from the
source checkout. The documentation directory is excluded from package builds,
so that focused test reports a clear skip when run only from a built package;
the standalone scripts were also executed directly in the source checkout.

| Recipe | App construction / execution | Headless behavior | Notes |
| --- | --- | --- | --- |
| [01 Basic app](01-basic-app.md) | Pass | Pass | App source evaluated; greeting asserted through the pilot. |
| [02 Form with validation](02-reactive-form.md) | Pass | Pass | Blank validation and successful submission asserted. |
| [03 Data table](03-data-table.md) | Pass | Pass | Row navigation, `s` sorting, and programmatic sorting asserted. |
| [04 Headless testing](04-headless-testing.md) | Pass | Pass | Standalone script ran its keyboard and screen assertions. |
| [05 Shiny-style app](05-shiny-app.md) | Pass | Pass | Typed filter, summary and reset asserted through the pilot (Linux, R 4.5). |

These checks verify app construction and behavior with the headless driver.
They do not establish interactive terminal behavior on every OS; see the
[platform testing guide](../platform-testing.md). The focused run passed on
Windows with R 4.5.2. R startup printed warnings that the `C.UTF-8` locales
could not be set; these recipe assertions passed despite those warnings.
