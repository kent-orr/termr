---
name: termr
description: Build interactive terminal user interfaces in R using termr. Use for R TUI applications, terminal dashboards, keyboard-driven menus, interactive forms, data tables, and full-screen terminal applications, including Shiny-style ui/server apps meant for a terminal. Do not use for Shiny web applications, ordinary R scripts, static console printing, or terminal applications in other programming languages.
---

# Build R terminal applications with termr

Use this skill when a user wants an R program that owns an interactive terminal
screen, even if they have not named termr. Do not route Shiny web apps, static
output, ordinary scripts, or applications written in other languages here. A
user who knows Shiny and wants a terminal app belongs here: termr has a
Shiny-shaped layer (see [Shiny-style apps](references/shiny.md)).

## Workflow

1. Check the project's R setup and existing dependencies. `termr` requires R
   4.1 or newer. Do not add dependencies unless the requested feature needs
   one; database and export integrations are optional.
2. Read [the stable API guide](references/public-api.md). Prefer the stable
   constructors, event handlers, and in-memory data table API. Check the
   installed package help when the requested behavior depends on details not
   covered there.
3. For a new app, start from [the minimal template](assets/minimal-app.R) or
   one of the [application patterns](references/recipes.md). Keep the UI in
   `app()` and widgets, update mounted widgets in event handlers, and use
   documented event names and fields. If the user writes or asks for Shiny-style
   code (`fluidPage()`, `observeEvent()`, `renderText()`, a `server`
   function), start from [the Shiny-style template](assets/shiny-app.R) and
   follow [Shiny-style apps](references/shiny.md) instead.
4. Verify behavior with the [headless testing guide](references/testing.md).
   Use `test_app()` for keyboard, widget state, and rendered output. Run
   `run()` only in a real terminal; headless success does not prove platform
   terminal behavior.
5. Report commands run and distinguish headless results from real-terminal
   and cross-platform checks.

## Scope

Build or modify the requested app without refactoring termr internals. Avoid
`termr:::` and undocumented implementation details. The reactive graph,
the Shiny-shaped layer, workers, database adapters, lazy table sources, and custom extension points
are experimental; use them only when the user needs them and explain the
compatibility risk. Keep UI work synchronous and small unless the user needs
long-running work; database queries and table-source page callbacks can block
the event loop.

## Installation

Copy the complete `termr` skill directory, including `references/` and
`assets/`, into a skill directory recognized by the target agent. Agent-specific
paths and installation methods are listed in termr's compatibility guide. The
target R project must also have the `termr` package installed; this skill does
not install R packages.
