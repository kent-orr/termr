# Reactivity

What makes a termr app change on screen, and when the change is drawn.

## At a glance

| You want to | Shiny | termr, Shiny layer | termr, native |
|---|---|---|---|
| hold a value | `reactiveVal(0)` | `reactiveVal(0)` | `signal(0)` |
| derive a value | `reactive({ a() + 1 })` | `reactive({ a() + 1 })` | `computed(function() a() + 1)` |
| run code on change | `observe({ })` | `observe({ })` | `watch(function() ...)` |
| react to a click | `observeEvent(input$go, { })` | `observeEvent(input$go, { })` | `on("button.pressed", "#go", function(event, app) ...)` |
| read without depending | `isolate(x())` | `isolate(x())` | `peek(x)` / `untracked(x())` |
| show text | `output$x <- renderText({ })` | `output$x <- renderText({ })` | `label(function() ...)` |
| change a control | `updateTextInput(session, "x", value = )` | `updateTextInput(session, "x", value = )` | `app$query_one("#x")$set(value = )` |
| structure an app | `shinyApp(ui, server)` | `app(ui, server = server)` | `app(widgets, on(...), bind(...))` |
| tick on a timer | `invalidateLater(1000)` | `invalidateLater(1000)` | `app$set_interval(1, function(app) ...)` |

[termr for Shiny users](shiny.md) has the full translation and an app
written both ways.

## What causes a change

Four things change what an app shows. Nothing else does: assigning an
ordinary R variable is invisible to termr, and so is changing something
*inside* a list or data frame held by a signal (replace the whole value
instead).

1. **A widget field is assigned.** `w$value <- "x"`, `w$set(value = "x")`,
   `label$update("x")` and the user typing into an input all set a state
   field. The widget is marked for repaint, and controls post their change
   message (`"input.changed"`, `"dropdown.changed"`, ...) whether the user
   or your code made the change. Anything reactive that read the field
   re-runs.
2. **A signal is written.** `count(5)` or `reactiveVal` writes invalidate
   every `computed()`, `watch()` and bound widget function that read it.
   Writing an `identical()` value does nothing.
3. **An event reaches a handler.** Keys go to the focused widget and mouse
   events to the widget under the pointer; widgets turn them into messages
   that bubble up to the app, where `on()` and `observeEvent()` handlers
   run. A handler causes a change by doing 1 or 2.
4. **Time passes.** Timers (`app$set_timeout()`, `app$set_interval()`,
   `invalidateLater()`), background workers (`app$run_worker()`,
   `app$run_process()`) and animations (`animate()`) run callbacks from the
   event loop. Like handlers, they cause a change by doing 1 or 2.

All four, in one app:

```r
library(termr)

name <- input(id = "name", placeholder = "Your name")
clicks <- signal(0L)

application <- app(
  vertical(
    name,
    label(function() paste("Hello,", name$value)),       # 1. reads a widget field
    label(function() paste("Clicks:", clicks())),        # 2. reads a signal
    button("Click", id = "click"),
    label("", id = "clock")
  ),
  on("button.pressed", "#click", function(event, app) {  # 3. an event
    clicks(clicks() + 1L)
  })
)
application$set_interval(1, function(app) {             # 4. a timer
  app$query_one("#clock")$update(format(Sys.time(), "%H:%M:%S"))
})
run(application)
```

The same app in the Shiny layer reads the same way, with the reactive
parts moved into the server:

```r
ui <- vertical(
  textInput("name", placeholder = "Your name"),
  textOutput("hello"),
  textOutput("clicks"),
  actionButton("click", "Click"),
  textOutput("clock")
)

server <- function(input, output, session) {
  clicks <- reactiveVal(0L)
  output$hello <- renderText({ paste("Hello,", input$name) })
  output$clicks <- renderText({ paste("Clicks:", clicks()) })
  observeEvent(input$click, clicks(clicks() + 1L))
  output$clock <- renderText({
    invalidateLater(1000)
    format(Sys.time(), "%H:%M:%S")
  })
}

run(app(ui, server = server))
```

## The tick

A running app repeats one *tick* until it exits:

1. wait for input, but no longer than until the next timer is due;
2. route keys and mouse events to widgets;
3. poll background workers, running their callbacks;
4. fire due timers (animations are driven by a timer);
5. dispatch queued messages to handlers;
6. if anything was marked for repaint, draw one frame.

Each handler and each timer callback runs inside `batch()`. Writes made
during it mark things dirty, and watchers (including render functions and
bound widget functions) run once, when the handler returns, however many
writes there were. A frame is drawn at most once per tick, after all
handlers of that tick, so the user never sees a half-updated screen.

Drawing is incremental. termr lays out again only if a change can move or
resize something, paints only the rectangles of the widgets that changed,
and sends the terminal only the cells that differ from the previous frame.
Changing one label in a large dashboard repaints that label, not the
screen.

Reactive effects never run in the middle of drawing a frame. If painting
adjusts a widget's state (a table clamping its scroll offset, say), the
effects run after the frame, and the next tick draws their result.

Worker callbacks (`on_complete`, `on_progress`, ...) run outside a batch,
so each signal write in them settles at once. Wrap several writes in
`batch()` when they belong together.

Batching outside an app:

```r
count <- signal(0)
runs <- 0
w <- watch(function() {
  count()
  runs <<- runs + 1
})
batch({
  count(1)
  count(2)
  count(3)
})
runs   # 2: once when created, once after the batch
dispose(w)
```

## Signals

The signal graph holds application state that is not a widget field.

```r
count  <- signal(0)
double <- computed(function() count() * 2)
watch(function() cat("double is", double(), "\n"))   # prints now
count(5)                                             # prints "double is 10"
```

* `signal(x)`: `s()` reads, `s(value)` writes. Collections are replaced as a
  whole (`items(c(items(), "x"))`). `reactiveVal()` is the same function.
* `computed(fn)`: lazy and cached; re-evaluates when read after a dependency
  changed. A computed that depends on itself is an error. `reactive({ })`
  is the same with an expression.
* `watch(fn)`: runs now and after its dependencies changed, in creation order,
  only if a dependency really changed. Writes inside a watcher settle; a loop
  between watchers stops with an error after a bounded number of runs.
  `observe({ })` is the same with an expression.
* `batch(expr)`: watchers run once, at the end.
* `peek(x)` / `untracked(expr)` / `isolate(expr)`: read without a
  dependency. `dispose()` ends a watcher or computed. `update_signal(x, fn)`
  applies a function.
* `inspect_signal(x)` shows a node's direct dependencies and subscribers,
  disposed/dirty state, version, and cumulative read/evaluation/run/write
  counters. Give nodes a `name` to make cycle paths readable; errors include
  the named path through the cycle.

Signals hold their subscribers: `dispose()` watchers you no longer need.
Watchers, render functions and `observe()` calls made in a server are
disposed for you when the app stops.

## Widgets in the graph

Widget state fields are signals too. Reading one inside a reactive context
(`computed()`, `watch()`, a render function, a bound widget function) is a
dependency, so this label follows the input as the user types:

```r
name <- input(id = "name")
greeting <- label(function() paste("Hello,", name$value))
run(app(vertical(name, greeting)))
```

`label()`, `button()`, `progress_bar()`, `metric()`, `sparkline()` and
`key_value()` accept a function wherever they take their value; the function
is evaluated again when what it reads changes, and the binding ends when the
widget is removed. For other widgets use
`widget$bind_reactive("field", fn)`. In the Shiny layer,
`output$id <- renderText({ })` does the same for the widget with that id.

A custom widget declares its own fields with `state()`; assigning one
repaints the widget (see [custom widgets](custom-widgets.md)). Until termr
1.0.3 the declarator was called `reactive()`; that spelling still works for
a plain value and warns once.
