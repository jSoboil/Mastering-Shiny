# Data:
prod_codes <- setNames(products$code, products$title)

ui <- fluidPage(
 fluidRow(
  column(6, 
         selectInput("code", "Product", choices = prod_codes)
         )
 ),
 fluidRow(
  column(4, tableOutput("diag")),
  column(4, tableOutput("body_part")),
  column(4, tableOutput("location"))
 ),
 fluidRow(
  column(12, plotOutput("age_sex"))
 )
)
server <- function(input, output, session) {
 selected <- reactive({
  injuries %>% 
   filter(prod_code == input$code)}
  )
 
 # Count function:
count_top <- function(df, var, n = 5) {
  df %>%
    mutate({{ var }} := fct_lump(fct_infreq({{ var }}), n = n)) %>%
    group_by({{ var }}) %>%
    summarise(n = as.integer(sum(weight)))
}
  output$diag <- renderTable(count_top(selected(), diag), width = "100%")
  output$body_part <- renderTable(count_top(selected(), body_part), width = "100%")
  output$location <- renderTable(count_top(selected(), location), width = "100%")
 
 summary <- reactive({
  selected() %>% 
   count(age, sex, wt = weight) %>%
   left_join(population, by = c("age", "sex")) %>%
   mutate(rate = n.x / n.y * 1e4)
 })
 
 output$age_sex <- renderPlot({
  summary() %>% 
   ggplot(aes(age, n.x, colour = sex)) +
   geom_line() + 
   labs(y = "Estimated number of injuries")
 }, res = 96)

}
shinyApp(ui, server)