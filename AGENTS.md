# Instructions for Codex

## Start here

- Read `README.md`, `docs/getting-started.md`, and `docs/stability.md` before proposing application-facing changes.
- For implementation work, read `ARCHITECTURE.md` and the relevant guide under `docs/`. Treat `NAMESPACE` and `man/` as the checked-in public API reference; `docs/api-inventory.md` maps exports to their definitions and help topics.
- Check `git status --short` first. Preserve existing user changes and do not reset, overwrite, or stage unrelated files.

## Project conventions

- This is an R package (R >= 4.1) using R6, roxygen2, and testthat edition 3. Function and file names use `snake_case`; exported R6 classes use `UpperCamelCase`. Tests live in `tests/testthat/test-*.R` and examples in `inst/examples/`.
- Keep optional integrations optional. `DESCRIPTION` is the dependency source of truth; do not add a dependency without a clear need and corresponding documentation.
- Follow `docs/stability.md`: use exported, documented APIs in application and extension code; do not rely on `termr:::` or internal registries. Check whether an API is stable or experimental before depending on it.
- Keep terminal I/O in drivers, layout separate from painting, and widget behavior in the widget/app layers, as described in `ARCHITECTURE.md`.
- Do not edit generated `man/` or `NAMESPACE` by hand. When an R API change is explicitly in scope, update roxygen source and regenerate with `Rscript tools/dev.R doc`.

## Validation

- Run focused tests with `Rscript -e "testthat::test_local('.', filter = 'pattern', reporter = 'summary')"` (filter matches test file names).
- Run the full suite with `Rscript tools/dev.R test` or `Rscript tools/validate-dev.R`; the latter enables full non-CRAN workloads. See `docs/testing.md` for workload and platform limits.
- `Rscript tools/dev.R` runs roxygen generation and the full suite. Avoid it when documentation regeneration is outside scope; use the `test` or `doc` mode explicitly.
- Terminal and platform behavior is not fully established by headless tests. Use `.github/workflows/` and `docs/platform-testing.md` to identify the relevant CI or manual checks, and report checks that could not be run.

## Change discipline

- Keep changes within the requested scope. Do not change R source, exported symbols, or dependencies unless the task explicitly calls for it.
- Add or update tests and runnable examples when behavior changes; keep expected snapshots intentional and inspect snapshot diffs.
- Do not claim a test, platform, or example passed unless it was run in the current environment. Summarize changed files, commands, and results.
