# Introduction ------------------------------------------------------------
# As you saw in the previous chapter, Shiny encourages separation of the code that 
# generates your user interface (the front end) from the code that drives your app’s 
# behaviour (the back end).  In this chapter, we’ll dive deeper into the front end and 
# explore the HTML inputs, outputs, and layouts provided by Shiny. Learning more about 
# the front end will allow you to generate visually compelling, but simple apps.
library(shiny)

# Inputs ------------------------------------------------------------------
# As we saw in the previous chapter, you use functions like sliderInput(), 
# selectInput(), textInput(), and numericInput() to insert input controls into your UI 
# specification. Now we’ll discuss the common structure that underlies all input 
# functions and give a quick overview of the inputs built into Shiny.

## Common structure --------------------------------------------------------
# All input functions have the same first argument: InputId. This is the identifier used
# to connect the front end with the back end: if your UI has an input with ID "name",
# the server function will access it with input$name.

# The inputId has two constraints:

# It must be a simple string that contains only letters, numbers, and underscores (no
# spaces, dashes, periods, or other special characters are allowed). Name it like you
# would name an R variable.

# It must be unique. If it's not unique, you'll have no way to refer to this control in
# your server function.

# Most input functions have a second parameter called label. This is used to create a
# human-readable label for the control. Shiny doesn’t place any restrictions on this 
# string, but you’ll need to carefully think about it to make sure that your app is 
# usable by humans! The third parameter is typically value, which, where possible, 
# lets you set the default value. The remaining parameters are unique to the control.

# When creating an input, Hadley recommends supplying the inputId and label arguments 
# by position, and all other arguments by name. For example:
sliderInput("min", "Limit (minimum)", value = 50, min = 0, max = 100)

# Generally, it is recommend to only use sliders for small ranges, or cases where the 
# precise value is not so important. Attempting to precisely select a number on a small
# slider is an exercise in frustration!

# Collect a single day with dateInput() or a range of two days with dateRangeInput(). 
# These provide a convenient calendar picker, and additional arguments like 
# datesdisabled and daysofweekdisabled allow you to restrict the set of valid inputs.

# Date format, language, and the day on which the week starts defaults to US standards. 
# If you are creating an app with an international audience, set format, language, and 
# weekstart so that the dates are natural to your users.

## Limited choices ---------------------------------------------------------
# There are two different approaches to allow the user to choose from a prespecified 
# set of options: selectInput() and radioButtons(). For example:
animals <- c("dog", "cat", "mouse", "bird", "other", "I hate animals")

ui <- fluidPage(
  selectInput("state", "What's your favourite state?", state.name),
  radioButtons("animal", "What's your favourite animal?", animals)
)

# Radio buttons have two nice features: they show all possible options, making them 
# suitable for short lists, and via the choiceNames/choiceValues arguments, they can 
# display options other than plain text.
ui <- fluidPage(
  radioButtons("rb", "Choose one:",
    choiceNames = list(
      icon("angry"),
      icon("smile"),
      icon("sad-tear")
    ),
    choiceValues = list("angry", "happy", "sad")
  )
)

# Dropdowns created with selectInput() take up the same amount of space, regardless of 
# the number of options, making them more suitable for longer options. You can also set
# multiple = TRUE to allow the user to select multiple elements.
ui <- fluidPage(
  selectInput(
    "state", "What's your favourite state?", state.name,
    multiple = TRUE
  )
)

# NB!!! If you have a very large set of possible options, you may want to use 
# “server-side” selectInput() so that the complete set of possible options are not 
# embedded in the UI (which can make it slow to load), but instead sent as needed by 
# the server.

# There’s no way to select multiple values with radio buttons, but there’s an 
# alternative that’s conceptually similar: checkboxGroupInput().
ui <- fluidPage(
  checkboxGroupInput("animal", "What animals do you like?", animals)
)

# If you want a single checkbox for a single yes/no question, use checkboxInput():
ui <- fluidPage(
  checkboxInput("cleanup", "Clean up?", value = TRUE),
  checkboxInput("shutdown", "Shutdown?")
)

## File uploads ------------------------------------------------------------
# Allow the user to upload a file with fileInput():
ui <- fluidPage(
  fileInput("upload", NULL)
)
# fileInput() requires special handling on the server side, and is discussed in detail
# in Chapter 9.

### Action buttons ----------------------------------------------------------
# Let the user perform an action with actionButton() or actionLink(). These are most 
# naturally paired with observeEvent() or eventReactive() in the server function:
ui <- fluidPage(
  actionButton("click", "Click me!"),
  actionButton("drink", "Drink me!", icon = icon("cocktail"))
)

# You can customise the appearance using the class argument by using one of 
# "btn-primary", "btn-success", "btn-info", "btn-warning", or "btn-danger". You can 
# also change the size with "btn-lg", "btn-sm", "btn-xs". Finally, you can make 
# buttons span the entire width of the element they are embedded within using 
# "btn-block".
ui <- fluidPage(
  fluidRow(
    actionButton("click", "Click me!", class = "btn-danger"),
    actionButton("drink", "Drink me!", class = "btn-lg btn-success")
  ),
  fluidRow(
    actionButton("eat", "Eat me!", class = "btn-block")
  )
)

# Outputs -----------------------------------------------------------------
# Outputs in the UI create placeholders that are later filled by the server function. 
# Like inputs, outputs take a unique ID as their first argument: if your UI 
# specification creates an output with ID "plot", you’ll access it in the server 
# function with output$plot.

# Each output function on the front end is coupled with a render function in the back 
# end. There are three main types of output, corresponding to the three things you 
# usually include in a report: text, tables, and plots. The following sections show
# you the basics of the output functions on the front end, along with the 
# corresponding render functions in the back end.

## Text --------------------------------------------------------------------
# Output regular text with textOutput() and fixed code and console output with 
# verbatimTextOutput(). For example:
ui <- fluidPage(
  textOutput("text"),
  verbatimTextOutput("code")
)
server <- function(input, output, session) {
  output$text <- renderText({ 
    "Hello friend!" 
  })
  output$code <- renderPrint({ 
    summary(1:10) 
  })
}

# Note that the {} are not required in render functions, unless you need to run 
# multiple lines of code!!!

# You could also write the server function more compactly. Hadley recommends this 
# as a generally good style as you should do as little computation in your render 
# functions as possible.

# Note that there are two render functions that can be used with either of the text 
# outputs:

# renderText() combines the result into a single string.
# renderPrint() *prints* the result.

# We can see the difference by taking advantage of a hidden feature of the render 
# functions:
renderText("foo")()
#> [1] "foo"
renderPrint("foo")()
#> [1] "[1] \"foo\""

#  This is equivalent to the difference between cat() and print() in base R.

## Tables ------------------------------------------------------------------
# There are two options for displaying data frames in tables:

# tableOutput() and renderTable() render a static table of data, showing all the 
# data at once.

# dataTableOutput() and renderDataTable() render a dynamic table, showing a fixed 
# number of rows along with controls to change which rows are visible.

# tableOutput() is most useful for small, fixed summaries (e.g. model coefficients); 
# dataTableOutput() is most appropriate if you want to expose a complete data frame to
# the user. If you want greater control over the output of dataTableOutput(), Hadley
# highly recommends the reactable package by Greg Lin.
ui <- fluidPage(
  tableOutput("static"),
  dataTableOutput("dynamic")
)
server <- function(input, output, session) {
  output$static <- renderTable(head(mtcars))
  output$dynamic <- renderDataTable(mtcars, options = list(pageLength = 5))
}

## Plots -------------------------------------------------------------------
# You can display any type of R graphic (base, ggplot2, or otherwise) with 
# plotOutput() and renderPlot():
ui <- fluidPage(
  plotOutput("plot", width = "400px")
)
server <- function(input, output, session) {
  output$plot <- renderPlot(plot(1:5), res = 96)
}
# By default, plotOutput() will take up the full width of its container (more on that 
# shortly), and will be 400 pixels high. You can override these defaults with the
# height and width arguments. We recommend always setting res = 96 as that will make 
# your Shiny plots match what you see in RStudio as closely as possible.

# Plots are special because they are outputs that can also act as inputs. plotOutput() 
# has a number of arguments like click, dblclick, and hover. If you pass these a 
# string, like click = "plot_click", they’ll create a reactive input (input$plot_click) 
# that you can use to handle user interaction on the plot.

## Downloads ---------------------------------------------------------------
# You can let the user download a file with downloadButton() or downloadLink(). These 
# require new techniques in the server function, so we’ll come back to that.

# Layouts -----------------------------------------------------------------
# Now that you know how to create a full range of inputs and outputs, you need to be 
# able to arrange them on the page. That’s the job of the layout functions, which 
# provide the high-level visual structure of an app.

# Here we’ll focus on fluidPage(), which provides the layout style used by most apps. 
# In future chapters you’ll learn about other layout families like dashboards and 
# dialog boxes.

## Overview ----------------------------------------------------------------
# Layouts are created by a hierarchy of function calls, where the hierarchy in R 
# matches the hierarchy in the output. When you see complex layout code like this:
fluidPage(
  titlePanel("Hello Shiny!"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("obs", "Observations:", min = 0, max = 1000, value = 500)
    ),
    mainPanel(
      plotOutput("distPlot")
    )
  )
)
# First skim it by focusing on the hierarchy of the function calls:
fluidPage(
  titlePanel(),
  sidebarLayout(
    sidebarPanel(
      sliderInput("obs")
    ),
    mainPanel(
      plotOutput("distPlot")
    )
  )
)

## Page Functions ----------------------------------------------------------
# Behind the scenes, fluidPage() is doing a lot of work. The page function sets up all
# the HTML, CSS, and JS that Shiny needs. fluidPage() uses a layout system called 
# Bootstrap, that provides attractive defaults.

# Technically, fluidPage() is all you need for an app, because you can put inputs and 
# outputs directly inside of it. But while this is fine for learning the basics of 
# Shiny, dumping all the inputs and outputs in one place doesn’t look very good, so 
# you need to learn more layout functions. Here are two common structures, a page with
# sidebar and a multirow app, and then we’ll finish off with a quick discussion of 
# themes.

## Page with sidebar -------------------------------------------------------
# sidebarLayout(), along with titlePanel(), sidebarPanel(), and mainPanel(), makes it 
# easy to create a two-column layout with inputs on the left and outputs on the right.
# The basic code is shown below
ui <- fluidPage(
 titlePanel(
  # app title/description
 ),
 sidebarLayout(
  sidebarPanel(
   # inputs
  ),
  mainPanel(
   # outputs
  )
 )
)

# The following example shows how to use this layout to create a very simple app that
# demonstrates the Central Limit Theorem:
ui <- fluidPage(
 titlePanel("Central limit theorem"),
 sidebarLayout(
  sidebarPanel(
   numericInput("m", "Number of samples", value = 2, min = 1, max = 10000)
  ),
  mainPanel(
   plotOutput("hist")
  )
 )
)
server <- function(input, output, session) {
 output$hist <- renderPlot({
  means <- replicate(1e4, mean(runif(input$m)))
  hist(means, breaks = 20)
 }, res = 96)
}

## Multi-row ---------------------------------------------------------------
# Under the hood, sidebarLayout() is built on top of a flexible multi-row layout, 
# which you can use directly to create more visually complex apps. As usual, you 
# start with fluidPage(). Then you create rows with fluidRow(), and columns with 
# column().
fluidPage(
  fluidRow(
    column(4, 
      ...
    ),
    column(8, 
      ...
    )
  ),
  fluidRow(
    column(6, 
      ...
    ),
    column(6, 
      ...
    )
  )
)
# Note that the first argument to column() is the width, and the width of each row 
# must add up to 12. This gives you substantial flexibility because you can easily 
# create 2-, 3-, or 4-column layouts (more than that starts to get cramped), or use 
# narrow columns to create spacers.

## Themes ------------------------------------------------------------------
# Creating a complete theme from scratch is a lot of work (but often worth it!), but 
# you can get some easy wins by using the shinythemes package. The following code 
# shows four options:
theme_demo <- function(theme) {
  fluidPage(
    theme = shinythemes::shinytheme(theme),
    sidebarLayout(
      sidebarPanel(
        textInput("txt", "Text input:", "text here"),
        sliderInput("slider", "Slider input:", 1, 100, 30)
      ),
      mainPanel(
        h1("Header 1"),
        h2("Header 2"),
        p("Some text")
      )
    )
  )
}
theme_demo("darkly")
theme_demo("flatly")
theme_demo("sandstone")
theme_demo("united")

# Under the hood] ---------------------------------------------------------
# In the previous example you might have been surprised to see that I create a Shiny 
# app using a function, theme_demo(). This works because Shiny code is R code, and you
# can use all of your existing tools for reducing duplication. Remember the rule of 
# three: if you copy and paste code more than three times, you should consider writing
# a function or using a for loop.

# All input, output, and layout functions return HTML, the descriptive language that
# underpins every website. You can see that HTML by executing UI functions directly in
# the console:
fluidPage(
  textInput("name", "What's your name?")
)
# is...
<div class="container-fluid">
  <div class="form-group shiny-input-container">
    <label for="name">What is your name?</label>
    <input id="name" type="text" class="form-control" value=""/>
  </div>
</div>
# Shiny is designed so that, as an R user, you don’t need to learn about the details 
# of HTML. However, if you already know HTML (or want to learn!) you can also work 
# directly with HTML tags to achieve any level of customization you want. And these
# approaches are by no means exclusive: you can mix high-level functions with 
# low-level HTML as much as you like.

# End file ----------------------------------------------------------------