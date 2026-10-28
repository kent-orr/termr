# Plan: a Shiny-shaped layer for termr

This fork keeps termr's existing snake_case API intact and adds a layer that
an R Shiny user can pick up without learning termr's own vocabulary first.
The layer is additive: every new function resolves to existing widgets,
handlers and signals. The three goals from the review drive it:

1. Lay out screens with rows and columns the way Shiny does.
2. Use the verbs Shiny users already know, in camelCase.
3. Make state changes explicit and discoverable, with `observeEvent()` as the
   primary way to react to the user, instead of per-widget `on_change`
   callbacks.

## Guiding decisions

- **camelCase for the Shiny layer, snake_case stays for termr.** The new
  functions mirror Shiny names exactly (`textInput`, `actionButton`,
  `observeEvent`, `fluidRow`). Nothing existing is renamed except where a
  name collides (see Open questions).
- **No `on_change` callbacks on controls.** Reaction to user input is
  declared at app level with `observeEvent()`, matching Shiny's
  `observeEvent(input$go, ...)`. Widgets keep posting the same messages they
  post today; `observeEvent()` subscribes to them.
- **One reactive graph.** Widget state fields are bridged into the signal
  graph so that reading `input$name` inside a reactive context records a
  dependency. This is the piece that makes `renderText({ input$name })`
  style code work and is the main gap found in the review.
- **UI and server are separate.** An app is a UI declaration plus a server
  function, as in Shiny. The UI is a pure widget tree with no handlers in
  it. The server is `function(input, output, session)` and runs once, after
  the tree is mounted and before the first frame. Everything reactive
  (`observeEvent()`, `observe()`, `output$x <- ...`) is written inside it.
  The current `app(widgets, on(...), bind(...))` style keeps working; the
  split is the documented default for the Shiny layer.
- **The eval model is Shiny's.** `observeEvent()`, `renderText()` and
  `reactive()` take braced expressions, evaluated in the caller's
  environment with `input`, `output`, `event` and `app` bound, the same
  way Shiny's `exprToFunction()` works. Function literals are accepted too.

## Phase 1: ui/server split, `observeEvent()` and the input constructors

Smallest useful slice. Depends on nothing new in the engine: `input` and
`output` are plain accessors in this phase and become reactive in Phase 2.

### The ui/server split

```r
app(ui, server = function(input, output, session) { ... })
```

- `ui` is a widget (usually a layout container). Anything else in `...`
  still works as today.
- `server` is called once per `run()`, after the screen is mounted and
  before the first frame, so every `#id` in the UI resolves. It is called
  positionally with the input accessor, the output accessor and the `App`
  object; name the third argument `session` or `app` as you prefer.
- While the server runs, the app is the *current registration target*:
  `observeEvent()`, `observe()` and the `render*()` functions register on it
  directly instead of returning a handler for `app(...)`. Outside a server
  they return a handler as before, so both styles compose.
- `input$name` reads `query_one("#name")$value`. `input[["name"]]` and
  `names(input)` work too. Reading an id that does not exist is an error
  naming the id. In Phase 1 the read is not tracked; inside an
  `observeEvent()` handler that is all that is needed.
- `output$greeting <- "text"` writes the natural field of the widget with
  that id: `text` for labels, `value` for progress bars and metrics, `data`
  for tables and key-value views. Writing to an unknown id is an error.
  `output$greeting <- renderText({ ... })` arrives in Phase 2.
- Handlers registered by the server are removed on shutdown, so running
  the same app twice does not double-register them.

Implementation touch points: `server =` argument on `App$initialize()` and
`app()`; an `input`/`output` accessor class in `R/shiny-session.R`; a
registration-target stack in the same file that `observeEvent()` consults.

### `observeEvent(eventExpr, handlerExpr, ..., event = NULL, ignoreNULL = TRUE, ignoreInit = TRUE, once = FALSE)`

`eventExpr` is captured unevaluated and resolved as follows:

| Form | Meaning |
|---|---|
| `input$go` | the widget with id `go`, on its primary message |
| `"#go"` or any selector string | same, via selector matching |
| a widget object | that exact widget as sender |
| a `signal()` or `computed()` | a `watch()` that skips the initial run |
| anything else | error naming the accepted forms |

Primary message per widget type: `button.pressed`, `input.changed`,
`checkbox.changed`, `dropdown.changed`, `radio_set.changed`,
`option_list.selected`, `textarea.changed`, `tabs.changed`,
`datatable.row_selected`, `tree.node_selected`, `splitpane.resized`,
`scroll.changed`. `event =` overrides it (for example `"input.submitted"`).
A widget with no primary message fires on every message it posts.

The handler is called with `event` and `app`, with `input` and `output`
bound when it runs inside a server. For signal targets it is called with
`value` and `app`. `once` removes the handler after its first run. Inside a
server the handler is registered immediately; outside one the return value
is a `termr_handler` (or a `termr_watch` for signals), both accepted by
`app(...)`.

Implementation touch points: new file `R/shiny-observe.R`; add an optional
`sender` field to `termr_handler` in `R/bindings.R`; let `App$add_items()`
accept `termr_watch` objects.

### Input constructors

All take `inputId` first and `label` second as Shiny does. With a label they
return `vertical(label(label), control, height = auto)` with the id on the
control, so `#inputId`, `observeEvent(input$inputId, ...)` and
`query_one()` all find the control itself.

| Shiny | termr target | Notes |
|---|---|---|
| `textInput(inputId, label, value, placeholder)` | `input()` | |
| `passwordInput(...)` | `input(password = TRUE)` | |
| `textAreaInput(..., rows)` | `text_area()` | `rows` sets a fixed height |
| `numericInput(..., min, max)` | `input(validate = )` | `$value` is character; a `numericValue()` helper or a `Numeric` subclass is a Phase 2 option |
| `checkboxInput(inputId, label, value)` | `checkbox()` | |
| `radioButtons(inputId, label, choices, selected)` | `radio_set()` + `radio_button()` | named vector gives labels; first choice selected by default |
| `selectInput(inputId, label, choices, selected)` | `dropdown()` | first choice selected by default |
| `actionButton(inputId, label)` | `button()` | |

Also the `update*Input(inputId, value, ..., app = current_app())` family,
resolving to `query_one()$set()`.

Tests: `tests/testthat/test-shiny-compat.R` (draft already written).


### Before and after

A button that greets the name typed into a field.

Today:

```r
app(
  vertical(
    label("Name"),
    input(id = "name", placeholder = "Your name"),
    button("Greet", id = "go"),
    label("", id = "out")
  ),
  on("button.pressed", "#go", function(event, app) {
    name <- app$query_one("#name")$value
    app$query_one("#out")$update(paste("Hello,", name))
  })
) |> run()
```

After Phase 1:

```r
ui <- vertical(
  textInput("name", "Name", placeholder = "Your name"),
  actionButton("go", "Greet"),
  textOutput("out")
)

server <- function(input, output, session) {
  observeEvent(input$go, {
    output$out <- paste("Hello,", input$name)
  })
}

app(ui, server = server) |> run()
```

What changed: the UI is a pure declaration with no handlers in it, the
constructors read like Shiny, the handler is declared by what it reacts to
rather than by an event-name string and a selector, and widgets are read
and written by id through `input` and `output` instead of `query_one()`.
What has not changed yet: `input$name` is a plain read, so a label
computed from it does not update on its own. That is Phase 2.

Reacting to a signal, today and after:

```r
count <- signal(0L)
watch(function() if (peek(count) > 0) cat("count is", count(), "\n"))   # today: runs now, every change

observeEvent(count, cat("count is", value, "\n"))                      # after: skips the initial value
```

## Phase 2: one reactive graph, `input`, `output` and render functions

This is the substantive change. It makes widget state visible to the signal
graph and gives apps Shiny's `input`/`output` objects.

### Bridge widget fields into the signal graph

Each widget gets a lazily created signal node per state field. The active
binding getter calls the tracker when a reactive context is running;
`Widget$set_state()` bumps the node version and invalidates subscribers.
Event handlers and timers already run inside `batch()`, so effects flush at
the end of the tick as they do for signals today. A guard prevents an effect
from writing widget state during paint.

Result: `label(function() paste("Hello", some_input$value))` updates, and the
silent staleness found in the review is gone.

### `input` and `output`

The Phase 1 accessors become reactive. `input$name` now records a
dependency through the bridge, so a `reactive()` or `renderText()` that
reads it re-runs when the user types. `output$name <- renderText({ ... })`
binds the render expression to the widget with that id and keeps it in
sync; plain assignment keeps working as a one-shot write.

### Outputs and renderers

| Shiny | termr target |
|---|---|
| `textOutput(outputId)` | `label(id = )` |
| `verbatimTextOutput(outputId)` | `label(id = )` in a bordered panel, monospace is a given |
| `tableOutput(outputId)` | `data_table(id = )` |
| `renderText(expr)`, `renderTable(expr)` | a `watch()` created at mount that assigns the widget field |

### Reactive aliases

| Shiny | termr |
|---|---|
| `reactiveVal(x)` | `signal(x)` |
| `reactive({ })` | `computed()` with expression capture |
| `observe({ })` | `watch()` with expression capture |
| `isolate({ })` | `untracked()` |
| `invalidateLater(ms)` | re-run via `set_timeout()` (see Open questions) |

The name `reactive()` collides with termr's state-field declarator. See
Open questions.


### Before and after

The same greeting app, now with the label computed from the input.

Today, the obvious code renders once and then goes stale, with no warning:

```r
name <- input(id = "name")
app(
  name,
  label(function() paste("Hello,", name$value))   # never updates: widget fields are not tracked
) |> run()
```

The working version today needs a signal and a handler to copy the value:

```r
typed <- signal("")
app(
  input(id = "name"),
  label(function() paste("Hello,", typed())),
  on("input.changed", "#name", function(event, app) typed(event$data$value))
) |> run()
```

After Phase 2 the first version works, because widget fields are tracked:

```r
name <- input(id = "name")
app(name, label(function() paste("Hello,", name$value))) |> run()
```

And the Shiny spelling works too, with no `observeEvent()` at all:

```r
ui <- vertical(textInput("name", "Name"), textOutput("greeting"))

server <- function(input, output, session) {
  output$greeting <- renderText({ paste("Hello,", input$name) })
}

app(ui, server = server) |> run()
```

Derived state, today and after:

```r
# today
total <- computed(function() sum(items()))
watch(function() cat("total:", total(), "\n"))

# after
total <- reactive({ sum(items()) })
observe({ cat("total:", total(), "\n") })
```

A custom widget's state field, today and after (if question 2 is answered
with the rename):

```r
# today
Counter <- widget("Counter", state = list(count = reactive(0L)), ...)

# after
Counter <- widget("Counter", state = list(count = state(0L)), ...)
```

## Phase 3: layout

| Shiny | termr target |
|---|---|
| `fluidPage(...)` | `vertical()` with padding |
| `titlePanel(title)` | bold `label()` with bottom margin |
| `fluidRow(...)` | `horizontal(height = auto)` |
| `column(width, ..., offset)` | `vertical(width = "<width>fr", height = auto)`; `offset` as an empty spacer of `<offset>fr` |
| `sidebarLayout(sidebarPanel(...), mainPanel(...))` | `horizontal()` with `4fr` / `8fr` children, or `split_pane()` if resizable is wanted |
| `wellPanel(...)` | `panel()` |
| `tabsetPanel(tabPanel(title, ...), ...)` | `tabs()` / `tab()` |
| `h1()`..`h4()`, `hr()`, `br()`, `p()` | styled `label()`, `rule()`, blank `label()` |

The 12-column grid is verified to map onto `fr` units in `horizontal()`;
`column(4)` and `column(8)` split 24 cells into 8 and 16.

`column()` collides with the DataTable column spec. See Open questions.


### Before and after

Two panels side by side under a title, with a sidebar on the left.

Today:

```r
app(
  vertical(
    label("Sales", style = style(bold = TRUE, margin = c(0, 0, 1, 0))),
    horizontal(
      panel(dropdown(c("2025", "2026"), id = "year"), title = "Filters",
            style = style(width = "4fr")),
      panel(data_table(sales, id = "tbl"), style = style(width = "8fr")),
      style = style(height = "1fr")
    ),
    horizontal(
      metric("Rows", nrow(sales), style = style(width = "1fr")),
      metric("Total", sum(sales$amount), style = style(width = "1fr")),
      style = style(height = "auto")
    ),
    style = style(padding = c(0, 1))
  )
) |> run()
```

After Phase 3:

```r
ui <- fluidPage(
  titlePanel("Sales"),
  sidebarLayout(
    sidebarPanel(selectInput("year", "Year", c("2025", "2026"))),
    mainPanel(tableOutput("tbl"))
  ),
  fluidRow(
    column(6, metric("Rows", nrow(sales))),
    column(6, metric("Total", sum(sales$amount)))
  )
)

server <- function(input, output, session) {
  output$tbl <- renderTable({ sales[sales$year == input$year, ] })
}

app(ui, server = server) |> run()
```

What changed: no `style()` calls, no `fr` units, no explicit heights. The
`fr` engine still does the work underneath; `column(6)` is `width = "6fr"`.

## Phase 4: documentation and release

- `docs/shiny.md`: a side-by-side translation table and a complete example
  app written both ways.
- Rewrite `docs/reactivity.md` around "what causes a change": assigning a
  widget field or calling `$set()`, writing a signal, an event reaching a
  handler, and timers, workers and animations. Then the tick model: handlers
  run in a batch, one repaint per tick, dirty rows only. Then the Shiny
  mapping.
- README section, NEWS entries, version bump, update the bundled agent
  skill (it currently tells agents not to use termr for Shiny-shaped
  requests).
- Decide whether any of this is proposed upstream.


### Before and after

The reactivity page today is a list of API bullets. After Phase 4 it opens
with a table a Shiny user can scan in a minute:

| You want to | Shiny | termr (after this plan) | termr (today) |
|---|---|---|---|
| hold a value | `reactiveVal(0)` | `reactiveVal(0)` | `signal(0)` |
| derive a value | `reactive({ a() + 1 })` | `reactive({ a() + 1 })` | `computed(function() a() + 1)` |
| run code on change | `observe({ })` | `observe({ })` | `watch(function() ...)` |
| react to a click | `observeEvent(input$go, { })` | `observeEvent(input$go, { })` | `on("button.pressed", "#go", function(event, app) ...)` |
| read without depending | `isolate(x())` | `isolate(x())` | `peek(x)` / `untracked(x())` |
| show text | `renderText({ })` | `renderText("id", { })` | `label(function() ...)` |
| change a control | `updateTextInput(session, "x", value = )` | `updateTextInput(session, "x", value = )` | `app$query_one("#x")$set(value = )` |
| structure an app | `shinyApp(ui, server)` | `app(ui, server = server)` | `app(widgets, on(...), bind(...))` |
| tick on a timer | `invalidateLater(1000)` | open question 5 | `app$set_interval(1, function(app) ...)` |

followed by the four triggers of change and the tick model.

## Open questions

These change what gets built, so they are yours to decide before Phase 1
starts.

1. **`column()` naming (Phase 3).** Options: (a) rename the DataTable spec
   to `table_column()` and keep `column()` as a deprecated alias that
   dispatches on its first argument (numeric width means layout, character
   label means table spec); (b) dispatch permanently without renaming;
   (c) give the layout function another name such as `col()` or
   `fluidColumn()`. Recommendation: (a). Divergence from upstream is
   accepted on this fork.
   answer: let's do row() and col() so we don't touch the stable API beneath - put them in the README.md example so it shows fast
2. **`reactive()` naming (Phase 2).** termr's `reactive()` declares a
   widget state field; Shiny's creates a derived value. Options: (a) rename
   the declarator to `state()` and make `reactive({ })` Shiny-like, with a
   deprecation path; (b) leave `reactive()` alone and offer only
   `reactiveVal()`, `observe()`, `isolate()`. Recommendation: (a), since the
   collision is the single most likely source of confusion for the target
   user.
   answer: let's take your recommendation of deprecating state
3. **`numericInput()` value type.** Shiny returns a number. termr's
   `input()` holds text. Options: a validated text input whose `$value` is
   character, or a small `Numeric` subclass whose `$value` is numeric with
   `NA` when invalid. Recommendation: the subclass, in Phase 2.
   answer: subclass
4. **Expression capture vs functions only.** Shiny-style braced expressions
   require non-standard evaluation. Functions are simpler to reason about
   and to test. Recommendation: support both, as Shiny does, and document
   the expression form as the primary one.
   answer: give me an example. I'm tempted to avoid non-standard as much as possible but I want to see examples
5. **`invalidateLater()`.** Shiny re-runs the enclosing reactive after a
   delay. A faithful version needs the reactive context to know its own
   node. Options: implement it properly in the bridge, or document
   `set_interval()` with a signal as the termr idiom and skip it.
   answer: tell me more
6. **Server signature.** Shiny's third argument is `session`, an object
   with its own methods. Here it is the `App` object, which already has
   `notify()`, `exit()`, `push_screen()` and timers. Options: pass the App
   and document that `session` is the app, or wrap it in a small `session`
   object that exposes only the Shiny-shaped subset. Recommendation: pass
   the App; one object to learn.
   answer: let's pass the app
7. **Modules.** Shiny's `moduleServer()` and `NS()` let a UI/server pair be
   reused with namespaced ids. Not in this plan. Worth a note in
   `docs/shiny.md` on how to achieve the same with id prefixes, and a
   candidate for a later phase once the split has been used in anger.
8. **Upstream.** Keep the layer fork-only, or propose it upstream as an
   optional "shiny-compat" set of exports once stable?

## Order of work

Phase 1 can start as soon as questions 3, 4 and 6 are answered. Phase 2 needs
question 2 and 5. Phase 3 needs question 1. Phase 4 follows the others.
Each phase is test-first with `testthat` and headless `test_app()`, lands as
its own commit with a patch version bump, and leaves the full suite green
(baseline on this machine: all tests pass, no warnings, no skips).
