ui <- fluidPage(
 fluidRow(
  column(4, 
         "Distribution 1",
         numericInput(inputId = "n1", label = "n", value = 1000, min = 1),
         numericInput(inputId = "mean1", label = "µ", value = 0, step = 0.1),
         numericInput(inputId = "sd1", label = "σ", value = 0.5, min = 0.1, 
                      step = 0.1)
         ),
  column(4, 
         "Distribution 2",
         numericInput(inputId = "n2", label = "n", value = 1000, min = 1),
         numericInput(inputId = "mean2", label = "µ", value = 0, step = 0.1),
         numericInput(inputId = "sd2", label = "σ", value = 0.5, min = 0.1, 
                      step = 0.1)
         ),
  column(4,
         "Frequency Polygon",
         numericInput(inputId = "binwidth", label = "Bin width", value = 0.1, 
                      step = 0.1),
         sliderInput(inputId = "range", label = "Range", value = c(-3, 3), min = -5, 
                     max = 5)
         )
 ),
 fluidRow(
  column(9, plotOutput(outputId = "hist")),
  column(3, verbatimTextOutput("ttest"))
 )
)
server <- function(input, output, session) {
 x1 <- reactive(
  rnorm(n = input$n1, mean = input$mean1, sd = input$sd1)
  )
 x2 <- reactive(
  rnorm(n = input$n2, mean = input$mean2, sd = input$sd2)
 )
 
 output$hist <- renderPlot({
  freqpoly(x1(), x2(), binwidth = input$binwidth, xlim = input$range)
 }, res = 96)
 
 output$ttest <- renderText({
  t_test(x1(), x2())
 })
}
shinyApp(ui, server)
# This transformation yields the substantially simpler graph. This rewrite also makes 
# the app much more efficient since it does much less computation. Now, when you change
# the binwidth or range, only the plot changes, not the underlying data.

# Modules allow you to extract out repeated code for reuse, while guaranteeing that 
# it’s isolated from everything else in the app. Modules are an extremely useful and 
# powerful technique for more complex apps.

# You might be familiar with the “rule of three” of programming: whenever you copy and
# paste something three times, you should figure out how to reduce the duplication 
# (typically by writing a function). This is important because it reduces the amount of 
# duplication in your code, which makes it easier to understand, and easier to update as your requirements change.

















