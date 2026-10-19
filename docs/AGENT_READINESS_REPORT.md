# Agent readiness report

## Scope

This review covers the package metadata and exports, README and contributor architecture, user and extension guides, bundled examples, test structure, and CI workflows on `feature/agents`. The package is termr 1.0.1, requires R >= 4.1, uses R6 and testthat edition 3, and keeps DBI, RSQLite, jsonlite, knitr, and withr in `Suggests`.

## Repository map

- `R/` implements the package. `NAMESPACE` lists exported functions and classes; `man/` contains generated help.
- `ARCHITECTURE.md` explains the widget tree, event loop, layout, rendering, terminal drivers, workers, export, and extension points.
- `docs/` contains user guides, API stability and inventory references, testing guidance, and platform notes.
- `inst/examples/` contains runnable applications, including forms, data and database tools, workers, and custom widgets.
- `tests/testthat/` contains unit, integration, property, snapshot, worker, and platform-specific tests. CI is configured in `.github/workflows/`.
- `tools/dev.R` provides documentation, test, and install modes. `tools/validate-dev.R` runs testthat with `NOT_CRAN=true` and can filter test files.

## What helps agents today

- The headless `test_app()` pilot exercises the real event loop and renderer with simulated input and time; `render_widget()` supports one-frame checks. `docs/testing.md` explains keys, mouse, resize, snapshots, workers, and stress coverage.
- The architecture guide identifies subsystem boundaries and terminal driver responsibilities. Platform testing and CI notes distinguish headless confidence from PTY and Windows console checks.
- External extension tests use qualified `termr::` calls and avoid `termr:::`. Optional database and export packages are documented as optional.
- Tests and examples are organized predictably, with snapshot files under `tests/testthat/_snaps/`.

## Obstacles to reliable agent-built applications

1. **API guidance is stale and internally inconsistent.** `DESCRIPTION` says 1.0.1, while `docs/stability.md` calls itself the 1.0.0 policy and repeatedly says experimental details can change before 1.0. That makes it unclear whether documented APIs are still pre-release. The inventory reports 155 direct exports, 72 without Rd examples, and 24 without direct references in README/docs/examples/tests. The generated inventory helps discovery, but it does not fill the missing usage recipes.
2. **The supported path is spread across many documents.** A new app author must combine getting-started, widget, event, layout, styling, testing, and stability guides. There is no short, maintained recipe that takes an app from a minimal form through state, worker/error handling, and a headless test. Agents can assemble plausible code from fragments without seeing a complete tested pattern.
3. **Extension contracts remain experimental.** `docs/extensions.md` and `docs/stability.md` classify custom widgets, custom layouts, and table sources as experimental. The external-extension fixture gives useful tests, but application authors cannot rely on those contracts remaining compatible across minor releases.
4. **Some work can block the event loop.** `docs/sql.md` and `docs/data-sources.md` describe synchronous query execution and page fetching. An agent can build an apparently responsive UI around a database workflow that freezes during a slow query or fetch unless it explicitly moves work elsewhere; workers are a separate experimental API and require process-safe inputs.
5. **Local validation has side effects and platform limits that need attention.** The default `Rscript tools/dev.R` runs roxygen generation before tests and can rewrite `NAMESPACE` and `man/`. The test suite has platform-specific coverage, while POSIX PTY and Windows console validation require CI or dedicated harnesses. Agents need to choose commands deliberately and report host coverage rather than treating one local pass as cross-platform evidence.

## Recommended next five improvements, ranked by impact

1. **Make the API contract current and authoritative.** Revise `docs/stability.md` for the current release, resolve the stable/experimental boundaries, and explain how agents should choose supported APIs. Regenerate `docs/api-inventory.md` from repository metadata so counts and references cannot drift.
2. **Add tested end-to-end application recipes.** Provide small canonical patterns for form/state/events, data browsing, worker lifecycle and errors, and `test_app()` assertions. Run these examples in tests so agents can copy known-good structures.
3. **Fill high-use help and example gaps.** Prioritize missing Rd examples and direct documentation references for common constructors, event types, lifecycle methods, and testing/export entry points. Keep examples minimal and runnable in a headless test where possible.
4. **Reduce event-loop blocking surprises.** Document the practical limits of synchronous database callbacks next to their API entry points, and establish a supported recipe or future API for long-running queries/page fetches with progress, cancellation, and cleanup.
5. **Make validation commands and platform evidence explicit.** Add a concise contributor validation matrix describing the exact local commands, optional dependency setup, test filters, side effects, and which CI jobs cover PTY, Windows input, and SQL. Keep the matrix aligned with the workflows.

## Validation notes

This report is a repository inspection, not a claim of full portability. On the available Windows R 4.5.2 environment, `Rscript -e "testthat::test_local('.', reporter = 'summary')"` did not pass: the run reached test failures in accessibility, button snapshots, and data-table sorting, plus worker test errors. R startup could not set the requested `C.UTF-8` locales, and the worker tests reported that the sandbox blocks processx child-process pipes. The output stopped after testthat reached its maximum of 10 reported failures, so this run does not establish a complete failure count. Re-run in the project's CI environments to distinguish host and sandbox limitations from code regressions.
