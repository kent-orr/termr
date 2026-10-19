# Public API and stable components

termr is an R package for full-screen terminal apps. The package requires R
4.1 or newer. Its API stability guide identifies the following as stable for
application authors; consult the installed help for exact arguments and
behavior.

## Stable building blocks

- **App lifecycle:** `app()` builds an app; `run()` starts it in a real
  terminal. `app()` accepts widgets, `on()` handlers, and `bind()` bindings.
- **Widgets and layout:** `label()`, `button()`, `input()`, `checkbox()`,
  `radio_set()`, `radio_button()`, `dropdown()`, `vertical()`,
  `horizontal()`, `grid_layout()`, `scroll_view()`, and documented display
  widgets.
- **Events and keyboard:** `on()` registers handlers; `bind()` maps key names
  to built-in or function actions. Common documented messages include
  `button.pressed`, `input.submitted`, and `datatable.row_selected`.
- **In-memory tables:** `data_table()` accepts a data frame or matrix.
  Documented table operations include row/cell navigation, sorting, filtering,
  and selection. `header_sort = TRUE` enables header sorting; `S` sorts the
  active column.
- **Presentation:** `style()`, `stylesheet()`, and `termr_theme()` configure
  appearance.
- **Headless app checks:** `test_app()` returns a pilot for simulated input,
  screen output, and widget queries; `render_widget()` paints a widget once.

## Common patterns

```r
application <- app(
  vertical(label("Name"), input(id = "name"),
           button("Greet", id = "greet"), label("", id = "result")),
  on("button.pressed", "#greet", function(event, app) {
    name <- app$query_one("#name")$value
    app$query_one("#result")$update(paste("Hello,", name))
  }),
  bind("escape", "quit")
)
```

Use `input(validate = function(value) ...)` for simple field validation. The
validator returns `NULL` or `TRUE` for a valid value, or an error message for
an invalid value. An input sends `input.submitted` when Enter is pressed; a
separate `button.pressed` handler handles a submit button.

An app handler can query a mounted widget by selector, for example
`app$query_one("#name")`. `datatable.row_selected` event data provides the
original row as a named list in `event$data$value` and the original row index
in `event$data$row`.

## Experimental and internal APIs

The reactive graph (`signal()`, `computed()`, and related functions), worker
and subprocess APIs, SQL and database support, lazy table sources, custom
widgets/layouts, and static export are documented as experimental in termr's
stability guide. Avoid relying on them for a routine app unless the feature
requires them. Never use `termr:::` or undocumented internals in application
code.

The package's `NAMESPACE`, installed R help, and `docs/stability.md` are the
authoritative API references when available. The repository-level guide is
at `docs/stability.md` in the termr source tree.
