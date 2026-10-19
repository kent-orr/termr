# Agent discoverability report

Audit date: 2026-10-19. This report records repository content and search
results observed on that date. Search results vary by engine, locale, query,
and time; they do not establish stable ranking or comprehensive visibility.

## Findings

### Repository metadata

The public GitHub repository is `menshikovs/termr` (the local remote uses the
older `41929424/termr` path). GitHub currently describes it as “A reactive
terminal UI framework for R. Build interactive data explorers, dashboards and
SQL tools.” Its topics include `cli`, `dashboard`, `data-analysis`,
`data-science`, `r`, `reactive`, `stats`, `terminal-ui`, `termr`, and `tui`.
These already provide useful language and product-category signals.

### README and documentation

The README title is `termr`; its opening described “modern reactive terminal
applications for R” and highlighted data workflows. It includes a dashboard
quick start, installation from GitHub, examples, capabilities, API stability,
and a documentation index. The opening now spells out “terminal user interface
(TUI) framework for R.” The documentation index now links to the verified
recipes and the Codex skill.

The documentation tree has a task-oriented getting-started guide, API topic
guides, testing and stability guides, bundled examples under `inst/examples/`,
and four verified recipes under `docs/agent-recipes/`. The skill is stored at
`.agents/skills/termr/` with supporting references and a runnable template.
The repository file search found no sitemap, robots file, or pkgdown site
configuration. GitHub Markdown is the current primary documentation entry
point.

The README installation section offers GitHub and local checkout installation
and describes CRAN installation conditionally. No CRAN availability claim is
made here based on search results: a search for `termr` and CRAN did not return
an authoritative package page in the results inspected.

### Search observations

Searches were run for “R TUI framework,” “R terminal user interface library,”
“Build interactive terminal applications in R,” “R terminal dashboard,” and
“R curses alternative.” Results included unrelated terminal frameworks in
other languages, older general R terminal articles, and packages with narrower
terminal helpers. A Posit Community post specifically about termr appeared for
R terminal UI searches. This points to a useful external technical-content
opportunity, but does not show termr's position across search engines or users.

Sources inspected:

- [termr on GitHub](https://github.com/menshikovs/termr) for repository
  description and topics.
- [Posit Community: “I built a reactive terminal UI framework for R”](https://forum.posit.co/t/i-built-a-reactive-terminal-ui-framework-for-r/218901)
  for an existing R-community announcement.
- [cursr package description](https://bioconductor.statistik.tu-dortmund.de/cran/web/packages/cursr/index.html)
  as an example of a narrower R terminal package in search results.
- [“TUI in R – Rendering and key presses”](https://tomratford.co.uk/posts/tui-in-r-01/)
  as an older general R terminal article surfaced in the searches.

## Recommended improvements by priority

1. **GitHub metadata:** Keep the current concise description or use the
   following wording to include the expanded term and common application
   types: “A terminal user interface (TUI) framework for R. Build interactive
   dashboards, data explorers, forms, and keyboard-driven applications.” Keep
   the relevant current topics (`r`, `terminal-ui`, `tui`, `dashboard`,
   `reactive`, `data-analysis`, and `termr`). Consider adding `rstats`,
   `r-package`, and `terminal-applications` if they fit GitHub's topic limit.
   The current description/topics are already substantially aligned; update
   them only if the concise wording is preferred.
2. **README positioning:** State the full category phrase early and make the
   first navigation choices obvious: getting started, verified recipes,
   testing, API stability, and the agent skill. The README opening and docs
   links have been updated accordingly.
3. **Searchable documentation:** Maintain stable page titles and descriptive
   first paragraphs that say which R terminal task a page solves. Add a
   generated documentation site with canonical URLs and a sitemap only if it
   can be maintained alongside the existing source docs.
4. **Standalone tutorials and examples:** Keep the four recipes runnable and
   tested. Publish focused tutorials for a dashboard, validated form, and
   data-table workflow, linking each to its tested source and headless tests.
5. **Agent installation and skill discovery:** Keep the skill in the
   conventional `.agents/skills/termr/` directory, link it from the README,
   and provide copy/install instructions. Skill selection is runtime agent
   behavior: this improves explicit discovery when the skill is installed, but
   does not guarantee automatic activation in every agent product.

## Web search, model training, and skill activation

These are separate discovery paths. Web search depends on indexed pages and
query-specific ranking; this audit did not measure rank or traffic. Model
training data may or may not include the repository and cannot be updated by
editing these files. Skill activation depends on an agent reading or selecting
an installed skill and its declared description; documenting installation
and scope helps users configure that path but cannot force activation.

## External technical-content plan

Publish a small series of practical, non-promotional articles in R-focused
venues and link each to the matching repository guide and executable recipe:

1. **Build a full-screen R terminal app:** start with the stable app, layout,
   widget, event, and `run()` APIs in the getting-started recipe.
2. **Test keyboard-driven R interfaces without a terminal:** show
   `test_app()`, simulated key input, widget assertions, and screen output.
3. **Make an R data explorer in the terminal:** cover a real data frame,
   in-memory table navigation and sorting, and clearly mark experimental
   features when mentioned.

Include the R and termr versions, installation command, complete code, test
command and result, and links to the relevant API stability page. Prefer one
substantive article per use case over repeated keyword-focused announcements.
Share in R communities that welcome package tutorials, and keep the canonical
version in the repository so external posts can point to maintained details.
