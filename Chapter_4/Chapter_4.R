# Basic Reactivity --------------------------------------------------------
# Reactive programming is an elegant and powerful programming paradigm, but it can be 
# disorienting at first because it’s a very different paradigm to writing a script. The
# key idea of reactive programming is to specify a graph of dependencies so that when 
# an input changes, all related outputs are automatically updated. This makes the flow 
# of an app considerably simpler.

library(shiny)

## The server function  ----------------------------------------------------
# The guts of every Shiny app look like this:
ui <- fluidPage(
  # front end interface
)

server <- function(input, output, session) {
  # back end logic
}

# Initiate app
shinyApp(ui, server)

# The server back end is more complicated because every user needs to get an 
# independent version of the app; when user A moves a slider, user B shouldn’t see
# their outputs change.

# To achieve this independence, Shiny invokes your server() function each time a new 
# session starts. Just like any other R function, when the server function is called it
# creates a new local environment that is independent of every other invocation of the 
# function. This allows each session to have a unique state, as well as isolating the 
# variables created inside the function. This is why almost all of the reactive 
# programming you’ll do in Shiny will be inside the server function.

# Server functions take three parameters: input, output, and session. Because you never
# call the server function yourself, you’ll never create these objects yourself. 
# Instead, they’re created by Shiny when the session begins, connecting back to a 
# specific session. For the moment, we’ll focus on the input and output arguments, and 
# leave session for later chapters.

### Input -------------------------------------------------------------------
# The input argument is a list-like object that contains all the input data sent from 
# the browser, named according to the input ID. For example, if your UI contains a 
# numeric input control with an input ID of count, like so:
ui <- fluidPage(
 numericInput("count", label = "Number of values", value = 100)
)
# then you can access the value of that input with input$count. It will initially 
# contain the value 100, and it will be automatically updated as the user changes the 
# value in the browser.

# Unlike a typical list, input objects are read-only. If you attempt to modify an 
# input inside the server function, you’ll get an error:
server <- function(input, output, session) {
 input$count <- 10
}

#> Error: Attempted to assign value to a read-only reactivevalues object

# This error occurs because input reflects what’s happening in the browser, and the 
# browser is Shiny’s “single source of truth”. If you could modify the value in R, you
# could introduce inconsistencies, where the input slider said one thing in the 
# browser, and input$count said something different in R. Later, in Chapter 8, you’ll 
# learn how to use functions like updateNumericInput() to modify the value in the 
# browser, and then input$count will update accordingly.

# One more important thing about input: it’s selective about who is allowed to read it.
# To read from an input, you must be in a reactive context created by a function like
# renderText() or reactive(). We’ll come back to that idea very shortly, but it’s an
# important constraint that allows outputs to automatically update when an input 
# changes. This code illustrates the error you’ll see if you make this mistake:
server <- function(input, output, session) {
 message("The value of input$count is", input$count)
}

#> Error: Operation not allowed without an active reactive context. 
#> (You tried to do something that can only be done from inside 
#> a reactive expression or observer.)

### Output ------------------------------------------------------------------
# output is very similar to input: it’s also a list-like object named according to the 
# output ID. The main difference is that you use it for sending output instead of 
# receiving input. You always use the output object in concert with a render function, 
# as in the following simple example:
ui <- fluidPage(
 textOutput("greeting")
)
server <- function(input, output, session) {
 output$greeting <- renderText("Hello human!")
}
# (Note that the ID is quoted in the UI, but not in the server.)

# The render function does two things:

# 1. It sets up a special reactive context that automatically tracks what inputs the 
#    output uses.
# 2. It converts the output of your R code into HTML suitable for display on a 
#    web page.

#2 Like the input, the output is picky about how you use it. You’ll get an error if:
# You forget the render function:
server <- function(input, output, session) {
 output$greeting <- "Hello human!"
}
#> Error: Unexpected character output for greeting

# Or if you You attempt to read from an output:
server <- function(input, output, session) {
 message("The greeting is ", output$greeting)
}
#> Error: Reading from shinyoutput object is not allowed.

## Reactive programming ----------------------------------------------------
# An app is going to be pretty boring if it only has inputs or only has outputs. 
# The real magic of Shiny happens when you have an app with both. Let’s look at a 
# simple example:
ui <- fluidPage(
 textInput(inputId = "name", label = "What's your name?"),
 textOutput(outputId = "greeting")
)
server <- function(input, output, session) {
 output$greeting <- renderText({
  paste0("Hello ", input$name, "!")
 })
}

# This is the big idea in Shiny: you don’t need to tell an output when to update, 
# because Shiny automatically figures it out for you. How does it work? What exactly 
# is going on in the body of the function? Let’s think about the code inside the 
# server function more precisely:
output$greeting <- renderText({
 paste0("Hello ", input$name, "!")
})

# It’s easy to read this as “paste together ‘hello’ and the user’s name, then send it 
# to output$greeting”. But this mental model is wrong in a subtle, but important, way. 
# Think about it: with this model, you only issue the instruction once. But Shiny 
# performs the action every time we update input$name, so there must be something more
# going on.

# The app works because the code doesn’t tell Shiny to create the string and send it 
# to the browser, but instead, it informs Shiny how it could create the string if it
# needs to. It’s up to Shiny when (and even if!) the code should be run. It might be
# run as soon as the app launches, it might be quite a bit later; it might be run 
# many times, or it might never be run! This isn’t to imply that Shiny is capricious,
# only that it’s Shiny’s responsibility to decide when code is executed, not yours. 
# Think of your app as providing Shiny with recipes, not giving it commands.

### Imperative vs declarative programming -----------------------------------
# This difference between commands and recipes is one of the key differences between 
# two important styles of programming:

# In imperative programming, you issue a specific command and it’s carried out 
# immediately. This is the style of programming you’re used to in your analysis 
# scripts: you command R to load your data, transform it, visualise it, and save the 
# results to disk.

# In declarative programming, you express higher-level goals or describe important 
# constraints, and rely on someone else to decide how and/or when to translate that 
# into action. This is the style of programming you use in Shiny.

# With imperative code you say “Make me a sandwich”. With declarative code you say 
# “Ensure there is a sandwich in the refrigerator whenever I look inside of it”. 
# Imperative code is assertive; declarative code is passive-aggressive.

### Laziness ----------------------------------------------------------------
# One of the strengths of declarative programming in Shiny is that it allows apps to 
# be extremely lazy. A Shiny app will only ever do the minimal amount of work needed 
# to update the output controls that you can currently see. This laziness, however, 
# comes with an important downside that you should be aware of. Can you spot what’s 
# wrong with the server function below?
server <- function(input, output, session) {
 output$greetnig <- renderText({
  paste0("Hello ", input$name, "!")
 })
}
# greetnig is written instead of greeting. This won’t generate an error in Shiny, but
# it won’t do what you want. The greetnig output doesn’t exist, the code inside 
# renderText() will never be run.

# If you’re working on a Shiny app and you just can’t figure out why your code never 
# gets run, double check that your UI and server functions are using the same 
# identifiers.

### The reactive graph ------------------------------------------------------
# Shiny’s laziness has another important property. In most R code, you can understand
# the order of execution by reading the code from top to bottom. That doesn’t work in 
# Shiny, because code is only run when needed. To understand the order of execution 
# you need to instead look at the reactive graph, which describes how inputs and 
# outputs are connected.

# Describing the example above, the reactive graph contains one symbol for every input
# and output, and we connect an input to an output whenever the output accesses the 
# input. This graph tells you that greeting will need to be recomputed whenever name 
# is changed. We’ll often describe this relationship as greeting has a reactive 
# dependency on name.

# The reactive graph is a powerful tool for understanding how your app works. As your
# app gets more complicated, it’s often useful to make a quick high-level sketch of 
# the reactive graph to remind you how all the pieces fit together. In Chapter 14, 
# you’ll learn how to use reactlog which will draw the graph for you.

### Reactive expressions ----------------------------------------------------
# There’s one more important component that you’ll see in the reactive graph: the 
# reactive expression. We’ll come back to reactive expressions in detail very shortly;
# for now think of them as a tool that reduces duplication in your reactive code by 
# introducing additional nodes into the reactive graph.

### Execution order ---------------------------------------------------------
# It’s important to understand that the order in which your code is run is determined
# solely by the reactive graph. This is different from most R code where the 
# execution order is determined by the order of lines. For example, we could flip the 
# order of the two lines in our simple server function:
server <- function(input, output, session) {
 output$greeting <- renderText(string())
 string <- reactive(paste0("Hello ", input$name, "!"))
}
# You might think that this would yield an error because output$greeting refers to a 
# reactive expression, string, that hasn’t been created yet. But remember Shiny is 
# lazy, so that code is only run when the session starts, after string has been 
# created.

# This concept is very important and different to most other R code, so again: the 
# order in which reactive code is run is determined only by the reactive graph, not 
# by its layout in the server function. However, it is still best practice to 
# maintain the code in a sequential order.

## Reactive expressions ----------------------------------------------------
# Reactive expressions are important for two reasons:

# 1. They give Shiny more information so that it can do less recomputation when inputs
#    change, making apps more efficient.
# 2. They make it easier for humans to understand the app by simplifying the reactive
#    graph.

# Reactive expressions have a flavour of both inputs and outputs:

# 1. Like inputs, you can use the results of a reactive expression in an output.
# 2. Like outputs, reactive expressions depend on inputs and automatically know when 
#    they need updating.

# Because of this duality, some functions work with either reactive inputs or 
# expressions, and some functions work with either reactive expressions or reactive 
# outputs. We’ll use producers to refer to either reactive inputs or expressions, and 
# consumers to refer to either reactive expressions or outputs.

# We’re going to need a more complex app to see the benefits of using reactive 
# expressions. First, we’ll set the stage by defining some regular R functions that 
# we’ll use to power our app.

### The motivation ----------------------------------------------------------
library(ggplot2)
# Imagine you want to compare two simulated datasets with a plot and a hypothesis 
# test. After a little experimentation, you come up with the functions below: 
# freqpoly() visualises the two distributions with frequency polygons and t_test() 
# uses a t-test to compare means and summarises the results with a string:
freqpoly <- function(x1, x2, binwidth = 0.1, xlim = c(-3, 3)) {
 df <- data.frame(
  x = c(x1, x2),
  g = c(rep("x1", length(x1)), rep("x2", length(x2)))
 )
 
 ggplot(df, aes(x, colour = g)) + 
  geom_freqpoly(binwidth = binwidth, size = 1) + 
  coord_cartesian(xlim = xlim)
}

t_test <- function(x1, x2) {
 test <- t.test(x1, x2)
 
 sprintf("p value: %0.3f\n[%0.2f, %0.2f]",
         test$p.value, test$conf.int[1], test$conf.int[2])
}

# If you have some simulated data, you can use these functions to compare two 
# variables:
x1 <- rnorm(n = 100, mean = 0, sd = 0.5)
x2 <- rnorm(n = 200, mean = 0.15, sd = 0.9)

freqpoly(x1, x2)
cat(t_test(x1, x2))

# Extracting imperative code out into regular functions is an important technique for
# all Shiny apps: the more code you can extract out of your app, the easier it will be
# to understand. This is good software engineering because it helps isolate concerns: 
# the functions outside of the app focus on the computation so that the code inside of
# the app can focus on responding to user actions.

### The app -----------------------------------------------------------------
# Suppose you'd like to use these two tools to quickly explore a bunch of simulations.
# A Shiny app is a great way to do this because it lets you avoid tediously modifying 
# and re-running R code. You can wrap the pieces into a Shiny app where you can 
# interactively tweak the inputs.

# Let’s start with the UI. The first row has three columns for input controls 
# (distribution 1, distribution 2, and plot controls). The second row has a wide 
# column for the plot, and a narrow column for the hypothesis test.
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
# The server function combines calls to freqpoly() and t_test() functions after 
# drawing from the specified distributions:
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

### The reactive graph ------------------------------------------------------

























