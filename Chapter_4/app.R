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
 output$hist <- renderPlot({
  x1 <- rnorm(n = input$n1, mean = input$mean1, sd = input$sd1)
  x2 <- rnorm(n = input$n2, mean = input$mean2, sd = input$sd2)
  
  freqpoly(x1 = x1, x2 = x2, binwidth = input$binwidth, xlim = input$range)
 }, res = 96)
 
 output$ttest <- renderText({
  x1 <- rnorm(n = input$n1, mean = input$mean1, sd = input$sd1)
  x2 <- rnorm(n = input$n2, mean = input$mean2, sd = input$sd2)
  
  t_test(x1, x2)
 })
}
shinyApp(ui, server)