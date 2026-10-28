# Minimal termr application written the Shiny way.
# Run from a real terminal with: Rscript shiny-app.R

library(termr)

ui <- fluidPage(
  titlePanel("Greeter"),
  textInput("name", "What is your name?", placeholder = "Your name"),
  textOutput("greeting")
)

server <- function(input, output, session) {
  output$greeting <- renderText({
    if (!nzchar(input$name)) return("")
    paste("Hello,", input$name)
  })
}

application <- app(ui, server = server)

run(application)
