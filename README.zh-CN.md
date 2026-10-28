# termr

[English](https://github.com/menshikovs/termr/blob/main/README.md) | **简体中文**

![R](https://img.shields.io/badge/R-%E2%89%A5%204.1-276DC3?style=flat-square&logo=r&logoColor=white)
[![CRAN status](https://www.r-pkg.org/badges/version/termr)](https://CRAN.R-project.org/package=termr)
[![DeepWiki](https://img.shields.io/badge/DeepWiki-termr-blue)](https://deepwiki.com/menshikovs/termr)

> 面向 R 语言的终端用户界面（TUI）框架，提供响应式组件，
> 并将数据工作流作为一等公民来支持。

![termr demo](https://raw.githubusercontent.com/41929424/termr/main/docs/termr-clean.gif)

使用 R 构建现代化终端应用：数据浏览器、仪表板、数据库浏览器、SQL 工作台以及内部分析工具。termr 将组件、布局、事件、响应式状态和主题整合到同一个框架中，并且无需交互式终端也能进行测试。

R 本身已经非常适合数据处理、统计分析和机器学习。termr 为这些工作流增加了终端应用层。它通过虚拟帧缓冲区和增量渲染，仅将发生变化的字符单元发送到终端；应用代码只需处理组件和事件，而不必直接操作 ANSI 转义序列。

## 快速开始

在真实终端中启动 R，然后运行以下代码：

```r
library(termr)
selected <- signal(0L)
ui <- app(
  vertical(
    horizontal(
      metric("Rows", nrow(mtcars)),
      metric("Selected row", function() selected())
    ),
    data_table(mtcars, id = "cars", zebra = TRUE, header_sort = TRUE),
    button("Quit", on_press = function(event, app) app$exit())
  ),
  on("datatable.row_selected", "#cars", function(event, app) {
    selected(event$data$row)
  }),
  bind("q", "quit")
)
run(ui)
```

使用方向键在表格行之间移动，按 Tab 切换焦点，按 F1 查看帮助，点击“Quit”按钮或按 `q` 退出。`signal()` 属于实验性的响应式依赖图；核心应用、布局、事件和内存表格 API 计划保持稳定。若只想直接查看数据框，可调用 `browse_data(mtcars)`。

### 如果你熟悉 Shiny

同一个应用也可以按 Shiny 的方式编写：用 `row()` 和 `col()` 在 12 列网格上布局 UI，再用一个 server 函数响应 `input` 并填充 `output`。

```r
library(termr)

ui <- fluidPage(
  titlePanel("Motor Trend cars"),
  row(
    col(4, wellPanel(
      selectInput("cyl", "Cylinders", c("All", "4", "6", "8")),
      textOutput("summary"),
      actionButton("quit", "Quit")
    )),
    col(8, tableOutput("cars")),
    fill = TRUE
  )
)

server <- function(input, output, session) {
  cars <- reactive({
    if (input$cyl == "All") mtcars else mtcars[mtcars$cyl == as.numeric(input$cyl), ]
  })
  output$cars <- renderTable(cars())
  output$summary <- renderText(paste(nrow(cars()), "cars, mean mpg", round(mean(cars()$mpg), 1)))
  observeEvent(input$quit, session$exit())
}

run(app(ui, server = server))
```

无论终端多宽，`col(4)` 和 `col(8)` 都按三分之一与三分之二的比例分割这一行。`fill = TRUE` 让这一行占满屏幕剩余高度，因此表格会在行内滚动，而不会超出屏幕底部。布局函数命名为 `col()`，是因为 `column()` 已用于定义 `data_table()` 的列。与基础 R 一样，`row()` 和 `col()` 仍可用于矩阵。[面向 Shiny 用户的 termr 指南](docs/shiny.md)（英文）提供完整的对照表、以两种方式编写的同一应用，以及与 Shiny 的不同之处。这一 Shiny 风格层仍处于实验阶段。

## 为什么选择 termr

- **组合式应用开发：** 构建组件树，处理类型化事件和命令，并将显示值绑定到响应式状态。
- **让数据处理过程清晰可见：** 查看数据行和记录，展示指标与进度，并通过后台 R 工作进程运行耗时计算。
- **可测试的界面：** 无需实际终端，即可通过确定性的输入和时间控制来驱动事件循环与渲染器，包括模态对话框和焦点行为。

## 数据工作流

`data_table()` 负责格式化并绘制当前可见区域。内存表格支持排序、筛选、搜索、选择，以及调整列宽、隐藏列和冻结列。[惰性表格数据源](https://github.com/41929424/termr/blob/main/docs/data-sources.md) 可按页获取有限量的数据，无需将整个数据集加载到 R 数据框中。框架内置 SQLite 表和查询适配器；其他 DBI 驱动也可以通过分页回调接入。

`sql_editor()`、`db_connection()` 和 `db_explorer()` 借助可选的 DBI 相关包，将 SQL 编辑、数据库元数据查看和查询结果浏览组合起来。查询执行和分页获取是同步进行的；对于独立的分析任务，则可以使用后台工作进程。详见[数据工具](https://github.com/41929424/termr/blob/main/docs/data.md)、[SQL 工作流](https://github.com/41929424/termr/blob/main/docs/sql.md)和[数据库浏览器](https://github.com/41929424/termr/blob/main/docs/database-explorer.md)。

```r
run_example()                  # list bundled examples
run_example("data-explorer")
run_example("data-workbench")
```

## 框架功能

通过控件、标签页、分割面板、滚动视图、树形视图、Markdown、指标卡和迷你趋势图，组合表单与仪表板。还可以加入自动生成的帮助信息、模态对话框、通知和命令面板。样式表与主题支持单色模式／`NO_COLOR`、高对比度和减少动态效果。

![termr 组件展示：标签页、指标、进度和迷你趋势图](https://raw.githubusercontent.com/41929424/termr/main/docs/images/widget-showcase.png)

这张截图来自 RC1 源码树，其中显示的软件包版本为 `0.9.0.9000`。

后台工作进程和子进程可以流式输出结果与进度，并支持超时、取消及进程清理。静态渲染可将屏幕内容导出为文本、Markdown、HTML、SVG 和 JSON，供脚本以及可选的 knitr/Quarto 输出使用。这些导出结果是屏幕快照；静态渲染不会启动应用事件循环。

## 安装

termr 要求 R >= 4.1。

### CRAN（推荐的稳定版本）

从 [CRAN](https://CRAN.R-project.org/package=termr) 安装最新稳定版本：

```r
install.packages("termr")
```

### R-universe（替代安装方式）

也可以通过项目现有的 R-universe 仓库安装 termr 及其依赖：

```r
install.packages(
  "termr",
  repos = c(
    "https://menshikovs.r-universe.dev",
    "https://cloud.r-project.org"
  )
)
```

### GitHub（开发版本）

如需开发版本，先安装 `remotes`，再从 GitHub 安装：

```r
install.packages("remotes")
remotes::install_github("menshikovs/termr")
```

termr 只依赖少量 R 运行时软件包；DBI、RSQLite、jsonlite 和 knitr 均为可选依赖。termr 本身不包含需要编译的源代码。

## 运行环境

交互式应用需要真正的终端：可以执行 `Rscript app.R`，或在终端内启动 R。Linux/macOS 上的 POSIX 终端机制通过 PTY 持续集成（CI）测试；Windows 控制台输入由已安装的 PowerShell 辅助程序读取，其解析器在 Windows CI 中接受测试。

在 RC1 阶段，Windows 真实交互式控制台冒烟测试，以及通过真实 `ssh -t` 会话进行的 Linux 测试，均被人工报告为通过（PASS）。macOS 真实终端、tmux、screen 和 RStudio Terminal 尚未经过人工验证。RStudio 和 Positron 的控制台不是终端宿主环境；要运行交互式应用，请使用它们的终端标签页。测试依据与限制见[平台测试矩阵](https://github.com/41929424/termr/blob/main/docs/platform-testing.md)和 [SSH 指南](https://github.com/41929424/termr/blob/main/docs/ssh.md)。

对于 knitr、CI 及其他非 TTY 环境，请使用[静态导出](https://github.com/41929424/termr/blob/main/docs/export.md)。

## 测试

```r
pilot <- test_app(app(label("Ready")), width = 40, height = 3)
stopifnot(grepl("Ready", paste(pilot$screen_text(), collapse = "\n")))
pilot$stop()
```

`test_app()` 使用真实的事件循环和渲染器，同时模拟输入与时间。[测试文档](https://github.com/41929424/termr/blob/main/docs/testing.md)涵盖键盘、鼠标、粘贴、窗口大小调整、工作进程和快照测试。[完整 CI 运行记录 37758703750](https://github.com/41929424/termr/actions/runs/37758703750) 显示，RC1 提交通过了以下测试：Ubuntu 的 release、oldrel-1、R 4.1 和 devel；macOS 与 Windows 的 release；SQL 集成；Linux/macOS PTY；以及 Windows 输入。六个 R CMD check 任务均报告 0 个错误、0 个警告和 0 条备注。

## Agent 技能

官方的 [termr Agent Skill](https://github.com/menshikovs/termr/blob/main/.agents/skills/termr/SKILL.md) 包含经过验证的 API 说明、操作示例、可运行的模板，以及无终端测试指南。

对于支持的 Agent，可以通过以下命令将其安装到项目范围内：

```sh
npx skills add menshikovs/termr --skill termr --agent <agent> --copy
```

也可以将其复制到对应 Agent 的技能目录。有关支持的目录路径、调用方式和验证状态，请参阅 [Agent 兼容性指南](https://github.com/menshikovs/termr/blob/main/docs/AGENT_COMPATIBILITY.md)。由于验证环境存在网络限制，安装命令未能在该环境中实际执行。

## API 稳定性

termr 1.0.0 是首个稳定版本。核心应用与组件构建、基础布局、事件、命令、样式与主题、内存 DataTable 和基础测试功能构成稳定 API；不兼容的变更将在 NEWS 和迁移说明中明确列出。

响应式依赖图、工作进程、编辑器、惰性数据源、数据库支持、静态导出和自定义扩展仍处于实验阶段。在 1.0 发布周期后期加入的工作流组件也仍属于实验性功能。完整分类见 [API 稳定性说明](https://github.com/41929424/termr/blob/main/docs/stability.md)；变更详情请参阅[迁移说明](https://github.com/41929424/termr/blob/main/docs/migration-to-1.0.md)和 [NEWS](https://github.com/menshikovs/termr/blob/main/NEWS.md)。

## 文档

建议从[入门指南](https://github.com/41929424/termr/blob/main/docs/getting-started.md)开始，再依次了解[组件](https://github.com/41929424/termr/blob/main/docs/widgets.md)、[布局](https://github.com/41929424/termr/blob/main/docs/layout.md)、[事件](https://github.com/41929424/termr/blob/main/docs/events.md)、[响应式机制](https://github.com/41929424/termr/blob/main/docs/reactivity.md)、[面向 Shiny 用户的指南](docs/shiny.md)、[样式](https://github.com/41929424/termr/blob/main/docs/styling.md)、[工作进程](https://github.com/41929424/termr/blob/main/docs/workers.md)和[扩展](https://github.com/41929424/termr/blob/main/docs/extensions.md)。

[Agent 实战示例](https://github.com/41929424/termr/tree/main/docs/agent-recipes)提供经过验证的端到端示例；[termr Codex skill](https://github.com/41929424/termr/tree/main/.agents/skills/termr)可帮助 Agent 在其他仓库中构建和测试应用。[ARCHITECTURE.md](https://github.com/41929424/termr/blob/main/ARCHITECTURE.md)介绍内部实现，供项目贡献者参考。

## 许可证

MIT
