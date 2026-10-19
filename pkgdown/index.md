# Build terminal applications with R

`termr` is an R framework for interactive, keyboard-driven terminal user
interfaces. Compose applications from widgets and layouts, handle typed events,
and inspect data in a full-screen terminal interface.

## Install from GitHub

`termr` requires R 4.1 or newer and is not yet published on CRAN. Install the
GitHub installer once, then install termr from its repository:

```r
install.packages("remotes")
remotes::install_github("menshikovs/termr")
```

The package declares its runtime imports in `DESCRIPTION`; its installation
command installs those package dependencies. No package-specific
`SystemRequirements` are declared.

## Start building

- [Getting started](https://github.com/menshikovs/termr/blob/main/docs/getting-started.md)
- [Verified application recipes](https://github.com/menshikovs/termr/tree/main/docs/agent-recipes)
- [Headless testing](https://github.com/menshikovs/termr/blob/main/docs/testing.md)
- [API stability](https://github.com/menshikovs/termr/blob/main/docs/stability.md)

The [function reference](reference/index.html) is generated from the package's
documented exports. The [changelog](news/index.html) is generated from
[`NEWS.md`](https://github.com/menshikovs/termr/blob/main/NEWS.md).

## Guides

The project's Markdown guides remain maintained in the source repository and
are linked here rather than copied into the generated site:

- [Widgets](https://github.com/menshikovs/termr/blob/main/docs/widgets.md)
- [Layouts](https://github.com/menshikovs/termr/blob/main/docs/layout.md)
- [Events](https://github.com/menshikovs/termr/blob/main/docs/events.md)
- [Styling](https://github.com/menshikovs/termr/blob/main/docs/styling.md)
- [Data tools](https://github.com/menshikovs/termr/blob/main/docs/data.md)
- [SQL workflows](https://github.com/menshikovs/termr/blob/main/docs/sql.md)
- [API stability](https://github.com/menshikovs/termr/blob/main/docs/stability.md)

See the [GitHub repository](https://github.com/menshikovs/termr) for source,
issues, examples, and contribution information.
