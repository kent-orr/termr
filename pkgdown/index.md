# termr — Reactive Terminal UI Framework for R

termr is a reactive terminal user interface (TUI) framework for R. Build
keyboard-driven dashboards, data explorers and analytical tools from reusable
widgets and layouts. Handle events in R while termr manages terminal input,
layout and incremental rendering; test interactions without opening a terminal.

[![CRAN status](https://www.r-pkg.org/badges/version/termr)](https://CRAN.R-project.org/package=termr)

## Quick start

After installation, save this as `hello.R` and run `Rscript hello.R` in a real
terminal:

```r
library(termr)

application <- app(
  vertical(label("Hello from termr"), button("Quit", id = "quit")),
  on("button.pressed", "#quit", function(event, app) app$exit()),
  bind("escape", "quit")
)
run(application)
```

Press Enter on the button or Escape to exit. IDE consoles are not terminal
hosts; use a terminal tab for interactive applications. The
[getting started tutorial](articles/getting-started.html) adds a form and a
headless keyboard test using stable APIs.

## Installation

`termr` requires R 4.1 or newer.

### CRAN (recommended stable release)

Install the latest stable release from [CRAN](https://CRAN.R-project.org/package=termr):

```r
install.packages("termr")
```

### R-universe (alternative)

R-universe provides an R package repository that works with the standard
`install.packages()` function. Install termr and its dependencies with:

```r
install.packages(
  "termr",
  repos = c(
    "https://menshikovs.r-universe.dev",
    "https://cloud.r-project.org"
  )
)
```

### GitHub (development version)

For the development version, install `remotes` and then install from GitHub:

```r
install.packages("remotes")
remotes::install_github("menshikovs/termr")
```

The package declares its runtime imports in `DESCRIPTION`; its installation
command installs those package dependencies. No package-specific
`SystemRequirements` are declared.

## Start building

- [Build a terminal UI in R](articles/getting-started.html)
- [Build interactive terminal dashboards](articles/terminal-dashboards.html)
- [Verified application recipes](https://github.com/menshikovs/termr/tree/main/docs/agent-recipes)
- [Test terminal applications](articles/testing-terminal-ui.html)
- [API stability](https://github.com/menshikovs/termr/blob/main/docs/stability.md)

The [function reference](reference/index.html) is generated from the package's
documented exports. The [changelog](news/index.html) is generated from
[`NEWS.md`](https://github.com/menshikovs/termr/blob/main/NEWS.md).

## Guides

The tutorials above run on this site. Detailed source guides remain available
in the repository:

- [Widgets](https://github.com/menshikovs/termr/blob/main/docs/widgets.md)
- [Layouts](https://github.com/menshikovs/termr/blob/main/docs/layout.md)
- [Events](https://github.com/menshikovs/termr/blob/main/docs/events.md)
- [Styling](https://github.com/menshikovs/termr/blob/main/docs/styling.md)
- [Data tools](https://github.com/menshikovs/termr/blob/main/docs/data.md)
- [SQL workflows](https://github.com/menshikovs/termr/blob/main/docs/sql.md)
- [API stability](https://github.com/menshikovs/termr/blob/main/docs/stability.md)

## Data explorers and SQL workflows

`data_table()` provides keyboard navigation, sorting and selection for
in-memory data. Combine it with metrics and event handlers in a
[terminal dashboard](articles/terminal-dashboards.html), or use `browse_data()`
for direct exploration. Database adapters, lazy sources and `sql_editor()` are
experimental; DBI integrations remain optional and queries are synchronous.
See the [SQL guide](https://github.com/menshikovs/termr/blob/main/docs/sql.md).

Core application construction, layouts, events, in-memory tables and basic
headless testing are stable. The reactive graph, workers, database tools and
static export remain experimental. Consult the
[stability policy](https://github.com/menshikovs/termr/blob/main/docs/stability.md)
before depending on advanced features.

See the [GitHub repository](https://github.com/menshikovs/termr) for source,
issues, examples, and contribution information.
