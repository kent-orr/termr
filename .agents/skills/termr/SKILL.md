---
name: termr
description: Build interactive terminal user interfaces in R using termr. Use for R TUI applications, terminal dashboards, keyboard-driven menus, interactive forms, data tables, and full-screen terminal applications. Do not use for Shiny applications, ordinary R scripts, static console printing, or terminal applications in other programming languages.
---

# Build R terminal applications with termr

Use this skill when a user wants an R program that owns an interactive terminal
screen, even if they have not named termr. Do not route Shiny, static output,
ordinary scripts, or applications written in other languages here.

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
   documented event names and fields.
4. Verify behavior with the [headless testing guide](references/testing.md).
   Use `test_app()` for keyboard, widget state, and rendered output. Run
   `run()` only in a real terminal; headless success does not prove platform
   terminal behavior.
5. Report the commands run and distinguish headless results from real
   terminal or cross-platform checks.

## Scope

Build or modify the requested app without refactoring termr internals. Avoid
`termr:::` and undocumented implementation details. The reactive graph,
workers, database adapters, lazy table sources, and custom extension points
are experimental; use them only when the user needs them and explain the
compatibility risk. Keep UI work synchronous and small unless the user needs
long-running work; database queries and table-source page callbacks can block
the event loop.

## Install this skill elsewhere

For a project-specific skill, copy this `termr` directory to the other
repository's `.agents/skills/termr/`. For user-wide use, copy it to
`$CODEX_HOME/skills/termr/` or `~/.codex/skills/termr/`. See [installation
notes](INSTALL.md). The target R project must also have `termr` installed;
this skill does not install R packages.
