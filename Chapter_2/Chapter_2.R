# Your first Shiny app ----------------------------------------------------
## Introduction ------------------------------------------------------------
# In this chapter, we'll create a simply Shiny app. The minimum boilerplate needed
# for a Shiny app will be shown first. We will learn how to initiate and stop the
# app. Second, we will learn the two key components of every Shiny app: the UI 
# which defines how how your app looks, and the server function which defines how 
# your app works. Shiny uses reactive programming to automatically update outputs
# when inputs change, which will learn last in this chapter.

## Create app directory and file -------------------------------------------
# There are several ways to create a Shiny app. The simplest way is to create a
# directory for your app, and out a single file called app.R it it. This app.R 
# file will be used to tell Shiny both how your app should look and how it should
# behave.

# This is a complete, if trivial, Shiny app! Looking closely at the code above, our
# app.R does four things:

# 1. It calls library(shiny) to load the shiny package.
# 2. It defines the user interface, the HTML webpage that humans interact with. 
#    In this case, it’s a page containing the words “Hello, world!”.
# 3. It specifies the behavior of our app by defining a server function. It’s
#    currently empty, so our app doesn’t do anything, but we’ll be back to 
#    revisit this shortly.
# 4. It executes shinyApp(ui, server) to construct and start a Shiny application 
#    from UI and server.

# Before you close the app, go back to RStudio and look at the R console. You’ll
# notice that it says something like:
# Listening on http://127.0.0.1:4580

# This tells you the URL where your app can be found: 127.0.0.1 is a standard 
# address that means “this computer” and 3827 is a randomly assigned port number. 
# You can enter that URL into any compatible1 web browser to open another copy of 
# your app.

# IMPORTANT: While a Shiny app is running, it “blocks” the R console. This means
# that you can’t run new commands at the R console until the Shiny app stops.

# You can stop the app and return access to the console using any one of these 
# options:
# Click the stop sign icon on the R console toolbar.
# Click on the console, then press Esc.
# Close the Shiny app window.

# The basic workflow of Shiny app development is to write some code, start the app, 
# play with the app, write some more code, and repeat. If you’re using RStudio, 
# you don’t even need to stop and re-start the app to see your changes — you can 
# either press the Reload app button in the toolbox or use the Cmd/Ctrl + Shift + 
# Enter keyboard shortcut.

## Adding UI controls ------------------------------------------------------
# Next, we’ll add some inputs and outputs to our UI so it’s not quite so minimal. 
# We’re going to make a very simple app that shows you all the built-in data 
# frames included in the datasets package.

# This example uses four new functions:

# fluidPage() is a layout function that sets up the basic visual structure of the 
# page

# selectInput() is an input control that lets the user interact with the app by
# providing a value. In this case, it's a select box with the label "Dataset", and
# lets you choose one of the built-in datasets that come with R.

# verbatimTextOutput() and tableOutput() are output controls that tell Shiny where
# to put rendered output. verbatimOutput() displays code and tableOutput() 
# displays tables.

# Layout functions, inputs, and outputs have different uses, but they are 
# fundamentally the same under the covers: they’re all just fancy ways to 
# generate HTML, and if you call any of them outside of a Shiny app, you’ll see
# HTML printed out at the console.

## Adding behaviour --------------------------------------------------------
# Next, we’ll bring the outputs to life by defining them in the server function.

# Shiny uses reactive programming to make apps interactive. For now,  just be 
# aware that reactive programming involves telling Shiny how to perform a 
# computation, not ordering Shiny to actually go do it. It’s like the difference 
# between giving someone a recipe versus demanding that they go make you a 
# sandwich.

# In this simple case, we’re going to tell Shiny how to fill in the summary and 
# table outputs — we’re providing the “recipes” for those outputs.

# Almost every output you’ll write in Shiny will follow this same pattern:
# output$ID <- renderTYPE({
   # Expression that generates whatever kind of output
   # renderTYPE expects
# })

# The left-hand side of the assignment operator (<-), output$ID, indicates that 
# you’re providing the recipe for the Shiny output with the matching ID. The 
# right-hand side of the assignment uses a specific render function to wrap some 
# code that you provide; in the example above, we use renderPrint() and
# renderTable() to wrap our app-specific logic.

# Each render* function is designed to work with a particular type of output 
# that’s passed to an *Output function. In this case, we’re using renderPrint() 
# to capture and display a statistical summary of the data with fixed-width 
# (verbatim) text, and renderTable() to display the actual data frame in a 
# table.

# Because both of the rendering code blocks I wrote used input$dataset, whenever
#the value of input$dataset changes (i.e. the user changes their selection in 
# the UI), both outputs will recalculate and update in the browser.

## Reducing duplication with reactive expressions --------------------------
# Even in this simple example, we have some code that’s duplicated: the 
# following line is present in both outputs.

# dataset <- get(input$dataset, "package:datasets")

# In every kind of programming, it’s poor practice to have duplicated code; it 
# can be computationally wasteful, and more importantly, it increases the 
# difficulty of maintaining or debugging the code.

# In traditional R scripting, we use two techniques to deal with duplicated 
# code: either we capture the value using a variable, or capture the computation
# with a function. Unfortunately neither of these approaches work here. We need 
# a new mechanism: reactive expressions.

# You create a reactive expression by wrapping a block of code in 
# reactive({...}) and assigning it to a variable, and you use a reactive 
# expression by calling it like a function. But while it looks like you’re 
# calling a function, a reactive expression has an important difference: it only 
# runs the first time it is called and then it caches its result until it needs
# to be updated.












