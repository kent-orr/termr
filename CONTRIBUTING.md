# Contributing to termr

## Welcome and scope

Thank you for helping improve termr, a reactive terminal UI framework for R.
First-time contributors are welcome. Participation in official project spaces
is covered by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to contribute

Report reproducible bugs, improve documentation and examples, add tests,
help reproduce terminal-specific issues, or submit focused fixes. Look for
`good first issue` and `help wanted` labels when choosing a task.
Use [Discussions](https://github.com/menshikovs/termr/discussions) for general
questions, usage help, and early ideas; use
[Issues](https://github.com/menshikovs/termr/issues) for bugs and concrete proposals.
Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## Before starting

Search existing issues and pull requests. You may submit a PR directly for
bug fixes, documentation improvements, additional or improved tests, and small
internal refactoring that preserves behavior.

Discuss the following in an Issue or Discussion and agree on the direction
with the maintainer before implementation:

- New features or widgets.
- Significant architectural changes or major changes to established behavior.
- Breaking changes to stable APIs or significant changes to experimental APIs.
- New dependencies, including optional dependencies.

Discussion helps avoid spending time on changes that might not be accepted.
A proposal does not guarantee implementation or acceptance.

Read the [README](https://github.com/menshikovs/termr/blob/main/README.md), [getting started guide](https://github.com/menshikovs/termr/blob/main/docs/getting-started.md),
[repository instructions](AGENTS.md), [architecture](ARCHITECTURE.md), and
[API stability policy](https://github.com/menshikovs/termr/blob/main/docs/stability.md), then the guide relevant to your change
under [docs/](https://github.com/menshikovs/termr/tree/main/docs).

## Development environment

Fork the repository, clone your fork, and create a branch from `main`.
Use R >= 4.1; [DESCRIPTION](https://github.com/menshikovs/termr/blob/main/DESCRIPTION) is the dependency source of truth.
To use termr, install the stable CRAN release with `install.packages("termr")`.
See the [installation guide](https://github.com/menshikovs/termr/blob/main/README.md#installation)
for R-universe and GitHub alternatives. For contributions, work from your local
checkout so tests exercise your changes.

From R in the repository root, install any missing packages listed in `Imports`
and `testthat` for local testing. Install packages from `Suggests` only as needed
for the tests or integrations you are working on. DBI, RSQLite, jsonlite, and
knitr integrations must remain optional.

For example, once those development dependencies are available:

```sh
Rscript -e "testthat::test_local('.', filter = 'button', reporter = 'summary')"
```

`test_local()` loads the source package for you. Install `roxygen2` if changing
R API documentation. No IDE or additional tooling is required for ordinary
fixes. Interactive apps need R or Rscript in a real terminal; see the
[terminal guide](https://github.com/menshikovs/termr/blob/main/docs/terminal.md).

## Code conventions

Follow [AGENTS.md](AGENTS.md) and nearby code. termr uses R6, roxygen2, and
testthat edition 3. Use `snake_case` for functions and files and `UpperCamelCase`
for exported R6 classes. Tests belong in `tests/testthat/test-*.R`; runnable
examples belong in `inst/examples/`.

Keep terminal I/O in drivers, layout separate from painting, and widget
behavior in widgets and the app layer, following [ARCHITECTURE.md](ARCHITECTURE.md).
Keep changes focused and preserve unrelated work. Application and extension
examples must use exported, documented APIs, without `termr:::` or internal
registries. See the [API inventory](https://github.com/menshikovs/termr/blob/main/docs/api-inventory.md), [NAMESPACE](https://github.com/menshikovs/termr/blob/main/NAMESPACE),
and [man/](https://github.com/menshikovs/termr/tree/main/man) for the public reference.

## Testing and validation

Add or update meaningful tests and runnable examples when behavior changes.
Start with affected test files; the filter matches test file names:

```sh
Rscript -e "testthat::test_local('.', filter = 'button|focus', reporter = 'summary')"
```

For broader changes, run the full suite using one of:

```sh
Rscript tools/dev.R test
Rscript tools/validate-dev.R
```

The second command explicitly enables full non-CRAN workloads and writes a
summary under R's temporary directory. See [testing](https://github.com/menshikovs/termr/blob/main/docs/testing.md) for
workload modes, snapshots, headless tests, and platform limits. Inspect snapshot
diffs before accepting updates.

For changes affecting package installation, metadata, or examples, build and
check the source package. Replace the archive placeholder with the filename
printed by the build:

```sh
R CMD build .
R CMD check --no-manual --as-cran termr_<version>.tar.gz
```

The existing [R-CMD-check workflow](https://github.com/menshikovs/termr/blob/main/.github/workflows/R-CMD-check.yaml) runs
package checks and extended regressions on Linux, macOS, and Windows, including
R 4.1, oldrel-1, release, and devel on Linux. It also runs CRAN incoming checks
with the PDF manual, optional SQL integration, Unix PTY tests, and Windows input
regressions. The [pkgdown workflow](https://github.com/menshikovs/termr/blob/main/.github/workflows/pkgdown.yaml) builds the
documentation site on PRs. Separate worker and pre-RC diagnostic workflows
are targeted tools, not required checks on ordinary PRs.

For terminal changes, test the relevant behavior on an available host and
record the OS, terminal, and result. Consult the
[platform matrix and commands](https://github.com/menshikovs/termr/blob/main/docs/platform-testing.md) and [SSH guide](https://github.com/menshikovs/termr/blob/main/docs/ssh.md).
Headless and parser tests do not certify a terminal host. You do not need to
manually test every OS; CI provides cross-platform coverage. Explain unavailable
checks and let the maintainer assess any remaining coverage. Documentation-only
changes normally need link and formatting checks, not the full R suite.

## API compatibility

[docs/stability.md](https://github.com/menshikovs/termr/blob/main/docs/stability.md) is the canonical classification and
versioning policy, including event, command, snapshot, and deprecation contracts.
Preserve backward compatibility for stable public APIs unless a breaking change
has been explicitly discussed, approved, and scheduled for an appropriate release.
For stable APIs, semantic versioning means:

- PATCH: backward-compatible fixes for behavior that contradicts documentation.
- MINOR: backward-compatible enhancements, with the documented deprecation process.
- MAJOR: incompatible stable API changes, following the stability policy.

Experimental APIs may evolve in minor releases without a deprecation period
when impractical; compatibility is not guaranteed. Significant changes still
require discussion, and the stability policy's specific contracts still apply.

## Documentation and NEWS.md

Update the canonical guide and relevant examples when behavior changes.
For an agreed R API change, edit roxygen comments in `R/` and regenerate with:

```sh
Rscript tools/dev.R doc
```

Do not edit generated `man/` files or `NAMESPACE` by hand. Avoid bare
`Rscript tools/dev.R` when documentation regeneration is outside scope: its
default mode regenerates documentation and runs tests.

Add a concise [NEWS.md](https://github.com/menshikovs/termr/blob/main/NEWS.md) entry for user-visible fixes and features,
experimental API changes, deprecations, and breaking changes. Include migration
guidance where needed; minor editorial or internal-only changes usually do not
need a NEWS entry. Coordinate release placement with the maintainer.

## Pull request workflow

1. Make a focused change on your branch and update relevant tests and docs.
2. Review your diff and run checks appropriate to the change.
3. Open a PR against `main` using the template. Explain the problem, resulting
   behavior, related issues or prior discussion, and compatibility impact.
4. Record commands actually run and their results. Explain skipped or unavailable
   checks; leave unperformed validation unchecked.
5. Respond to review and update the branch as needed. Draft PRs are welcome
   for work that is not ready for acceptance.

The standard merge strategy is **Squash and merge**: each accepted PR becomes
one meaningful commit on `main`. You do not need to squash your branch manually.

## Review and maintenance expectations

termr currently has one maintainer, who has final authority over architecture,
public API decisions, PR acceptance, and releases. External contributions are
welcome; contributing does not automatically grant merge permissions.

Review happens as maintainer capacity allows, without fixed issue or PR response
times. The maintainer may request changes, defer a proposal, or decline work
that does not fit the project. Small, well-explained contributions are easier
to review and maintain. GitHub administrators can find the remaining repository
configuration steps in [Community setup](https://github.com/menshikovs/termr/blob/main/.github/COMMUNITY_SETUP.md).
