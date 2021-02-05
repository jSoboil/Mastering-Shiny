# Case Study: ER injuries -------------------------------------------------

## Introduction ------------------------------------------------------------
# We’ll now walk through a richer Shiny app that explores a fun dataset and pulls 
# together many of the ideas that you’ve seen so far. We’ll start by doing a little data 
# analysis outside of Shiny, then turn it into an app, starting simply, then 
# progressively layering on more detail.

# In this chapter, we’ll supplement Shiny with vroom (for fast file reading) and the 
# tidyverse (for general data analysis).
library(shiny)
library(vroom)
library(tidyverse)
library(neiss)

# Data:
top_prod <- injuries %>%
  filter(trmt_date >= as.Date("2017-01-01"), trmt_date < as.Date("2018-01-01")) %>%
  count(prod1, sort = TRUE) %>%
  filter(n > 5 * 365)

injuries <- vroom::vroom("data-raw/injuries.tsv")
injuries

products %>%
  semi_join(top_prod, by = c("code" = "prod1")) %>%
  rename(prod_code = code) %>%
  vroom::vroom_write("data-raw/products.tsv")

population %>%
  filter(year == 2017) %>%
  select(-year) %>%
  rename(population = n) %>%
  vroom::vroom_write("data-raw/population.tsv")

## Exploration -------------------------------------------------------------
# Let’s explore the data a little. We’ll start by looking at a product with an 
# interesting story: 649, “toilets”. First we’ll pull out the injuries associated with 
# this product:
selected <- injuries %>% filter(prod_code == 649)
nrow(selected)

# Next we’ll perform some basic summaries looking at the location, body part, and 
# diagnosis of toilet related injuries. Note that I weight by the weight variable so 
# that the counts can be interpreted as estimated total injuries across the whole US.
selected %>% 
 count(location, wt = weight, sort = TRUE)
selected %>% 
 count(body_part, wt = weight, sort = TRUE)
selected %>% 
 count(diag, wt = weight, sort = TRUE)
# As you might expect, injuries involving toilets most often occur at home. The most 
# common body parts involved possibly suggest that these are falls (since the head and 
# face and not usually involved in routine toilet usage), and the diagnoses seem rather
# varied.

# We can also explore the pattern across age and sex. We have enough data here that a
# table is not that useful, and so you make a plot that makes the patterns more obvious.
summary <- selected %>% 
 count(age, sex, wt = weight)
summary

summary %>% 
 ggplot(aes(x = age, y = n, colour = sex)) +
 geom_line() + 
 labs(y = "Estimated number of injuries")
# We see a spike for young boys peaking at age 3, and then an increase (particularly 
# for women) starting around middle age, and a gradual decline after age 80. We can 
# suspect the peak is because boys usually use the toilet standing up, and the increase
# for women is due to osteoporosis (i.e. I suspect women and men have injuries at the 
# same rate, but more women end up in the ER because they are at higher risk of 
# fractures).

# One problem with interpreting this pattern is that we know that there are fewer older
#people than younger people, so the population available to be injured is smaller. We
# can control for this by comparing the number of people injured with the total 
# population and calculating an injury rate. Here I use a rate per 10,000.
summary <- selected %>% 
  count(age, sex, wt = weight) %>% 
  left_join(population, by = c("age", "sex")) %>% 
  mutate(rate = n.x / n.y * 1e4)
summary

# Plotting the rate below yields a strikingly different trend after age 50: the 
# difference between men and women is much smaller, and we no longer see a decrease. 
# This is because women tend to live longer than men, so at older ages there are 
# simple more women alive to be injured by toilets.
summary %>% 
  ggplot(aes(age, rate, colour = sex)) + 
  geom_line(na.rm = TRUE) + 
  labs(y = "Injuries per 10,000 people")

# Finally, we can look at some of the narratives. Browsing through these is an 
# informal way to check our hypotheses, and generate new ideas for further 
# exploration. Here I pull out a random sample of 10:
selected %>% 
  sample_n(10) %>% 
  pull(narrative)

## Prototype ---------------------------------------------------------------
# When building a complex app, it is strongly recommended to start as simple as 
# possible, so that you can confirm the basic mechanics work before you start doing 
# something more complicated. Here we'll start with one input (the product code), 
# three tables, and one plot.

# When designing a first prototype, the challenge is in making it “as simple as 
# possible”. There’s a tension between getting the basics working quickly and 
# planning for the future of the app. Either extreme can be bad: if you design too
# narrowly, you’ll spend a lot of time later on reworking your app; if you design too 
# rigorously, you’ll spend a bunch of time writing code that later ends up on the 
# cutting floor.

# Here we have one row for the inputs (accepting that we'll probably add more inputs 
# before this app is done), one row for all three tables (giving each table 4 columns, 
# 1/3 of the 12 column width), and then one row for the plot:
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
# Note the use of setNames() in the selectInput() choices: this shows the product name
# in the UI and returns the product code to the server.

# The server function is relatively straightforward. We first convert the selected and
# summary variables created in the previous section to reactive expressions. This is a
# reasonable general pattern: you create variables in your data analysis to decompose 
# the analysis into steps, and to avoid recomputing things multiple times, and 
# reactive expressions play the same role in Shiny apps.

# Often it’s a good idea to spend a little time cleaning up your analysis code before 
# you start your Shiny app, so you can think about these problems in regular R code, 
# before you add the additional complexity of reactivity.
server <- function(input, output, session) {
 selected <- reactive(injuries %>% filter(prod_code == input$cpde))
 
 output$diag <- renderTable(
  selected() %>% count(diag, wt = weight, sort = TRUE)
 )
 output$body_part <- renderTable(
  selected() %>% count(body_part, wt = weight, sort = TRUE)
 )
 output$location <- renderTable(
  selected() %>% count(location, wt = weight, sort = TRUE)
 )
 
 summary <- reactive({
  selected %>% 
   count(age, sex, wt = weight) %>% 
   left_join(population, by = c("age", "sex")) %>% 
   mutate(rate = n.x / n.y * 1e4)
 })
 
 output$age_sex <- renderPlot({
  summary() %>% 
   ggplot(aes(age, n, colour = sex)) + 
   geom_line() + 
   labs(y = "Estimated number of injuries")
 }, res = 96)
}

## Polish Tables -----------------------------------------------------------
# Now that we have the basic components in place and working, we can progressively 
# improve our app.

# The first problem with this app is that it shows a lot of information in the tables, 
# where we probably just want the highlights. To fix this we need to first figure out 
# how to truncate the tables. We can do this using a combination of forcats functions: 
# first convert the variable to a factor, order by the frequency of the levels, and 
# then lump together all levels after the top 5.
injuries %>% 
 mutate(diag = fct_lump(fct_infreq(diag), n = 5)) %>% 
 group_by(diag) %>% 
 summarise(n = as.integer(sum(weight)))

# Wed can write a little function to automate this for any variable:
count_top <- function(df, var, n = 5) {
  df %>%
    mutate({{ var }} := fct_lump(fct_infreq({{ var }}), n = n)) %>%
    group_by({{ var }}) %>%
    summarise(n = as.integer(sum(weight)))
}
# We can then use this in the server function:
output$diag <- renderTable({
 count_top(selected(), diag), width = "100%"
})
output$body_part <- renderTable({
 count_top(selected(), body_part), width = "100%"
 })
output$location <- renderTable({
 count_top(selected(), location), width = "100%"
 })
# The above also made one other change to improve the aesthetics of the app: it forced 
# all tables to take up the maximum width (i.e. fill the column that they appear in).
# This makes the output more aesthetically pleasing because it reduces the amount of 
# incidental variation.

## Rate vs count -----------------------------------------------------------
# So far, we’re displaying only a single plot, but we’d like to give the user the 
# choice between visualising the number of injuries or the population-standardised 
# rate.

# First, we can add a control to the UI. Here we choose selectInput() because it 
# makes states explicit, and it would be easy to add new states in the future.:
fluidRow(
 column(8, 
        selectInput("code", "Product", 
                    choices = setNames(products$code, products$title),
                    width = "100%"
                    )
        ),
 column(1, 
        selectInput("y", "Y axis", c("rate", "count")))
)
# And then we condition on that inputs when generating the plot:
output$age_sex <- renderPlot({
 if (input$y == "count") {
  summary() %>% 
   ggplot(aes(age, n.x, colour = sex)) + 
   geom_line() + 
   labs(y = "Estimated number of injuries")
 } else {
  summary() %>% 
   ggplot(aes(age, rate, colour = sex)) + 
   geom_line(na.rm = TRUE) + 
   labs(y = "Injuries per 100,000 people")
  }
 }, res = 96)

## Narrative ---------------------------------------------------------------
# Say you want to provide some way to access the narratives because they are so
# interesting, and they give an informal way to cross-check the hypotheses you come
# up with when looking at the plots. In the R code, you can sample multiple narratives
# at once, but there’s no reason to do that in an app where you can explore 
# interactively.

# There are two parts to the solution. First we add a new row to the bottom of the UI.
# You can use an action button to trigger a new story, and put the narrative in a
# textOutput():
fluidRow(
 column(2, 
        actionButton("story", "Tell me a story")
        ),
 column(10, textOutput("narrative"))
)
# We can then use eventReactive() to create a reactive that only updates when the 
# button is clicked or the underlying data changes.
narrative_sample <- eventReactive(
 list(input$story, selected()),
 selected() %>%
  pull(narrative) %>% 
  sample(1)
)
output$narrative <- renderText({
 narrative_sample
})

## Final app:
# Data:
prod_codes <- setNames(products$code, products$title)

ui <- fluidPage(
 fluidRow(
 column(8, 
        selectInput("code", "Product", 
                    choices = prod_codes,
                    width = "100%"
                    )
        ),
 column(2, 
        selectInput("y", "Y axis", c("rate", "count")))
),
 fluidRow(
  column(4, tableOutput("diag")),
  column(4, tableOutput("body_part")),
  column(4, tableOutput("location"))
 ),
 fluidRow(
  column(12, plotOutput("age_sex"))
 ),
fluidRow(
 column(2, 
        actionButton("story", "Tell me a story")
        ),
 column(10, textOutput("narrative"))
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
 if (input$y == "count") {
  summary() %>%
   ggplot(aes(age, n.x, colour = sex)) +
   geom_line() +
   labs(y = "Estimated number of injuries")
  } else {
   summary() %>%
    ggplot(aes(age, rate, colour = sex)) +
    geom_line(na.rm = TRUE) +
    labs(y = "Injuries per 100,000 people")
   }
 }, res = 96)

  narrative_sample <- eventReactive(
    list(input$story, selected()
         ),
    selected() %>% pull("narrative") %>% sample(size = 1, replace = FALSE)
  )
  output$narrative <- renderText(narrative_sample())
}