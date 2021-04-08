library(shiny)
library(bslib)
# Layout, Themes, HTML ----------------------------------------------------
# Using fluidpage() is okay for defining a page layout when working quickly. However, it does
# not create usable or visually appealing apps.

## Single Page Layouts -----------------------------------------------------
# Layout functions provide the high-level visual structure of an app. Layouts are created by a 
# hierarchy of function calls, where the hierarchy in R matches the hierarchy in the 
# generated HTML. This helps you understand layout code. For example, when you look at 
# layout code like this:
fluidpage(
 titlePanel("Hello Shiny!"),
 sidebarLayout(
  sidebarPanel(
   sliderInput("obs", "Observations", min = 0, max = 1000, value = 500
               ),
   mainPanel(
    plotOutput("distPlot")
   )
  )
 )
)
# Focus on the hierarchy of the function calls:
fluidPage(
 titlePanel(),
 sidebarLayout(
  sidebarPanel(),
  mainPanel()
 )
)
# The ability to easily see hierarchy through indentation is one of the reasons it’s a good 
# idea to use a consistent style.

### Page functions ----------------------------------------------------------
# The most important, but least interesting, layout function is fluidPage(). However, it is
# the most simple way to achieve a straightforward layout, as fluidPage() sets up all the
# HTML, CSS, and JavaScript that Shiny needs.

# In addition to fluidPage(), Shiny provides a couple of other page functions that can come
# in handy in more specialised situations: fixedPage() and fillPage(). fixedPage() works 
# like fluidPage() but has a fixed maximum width, which stops your apps from becoming 
# unreasonable wide on bigger screens. fillPage() fills the full height of the browser and 
# is useful if you want to make a plot that occupies the whole screen.

### Themes ------------------------------------------------------------------
# Bootstrap is so ubiquitous within the R community that it’s easy to get style fatigue: 
# after a while every Shiny app and Rmd start to look the same. The solution is theming with
# the bslib package. bslib is relatively new package that allows you to override many 
# Bootstrap defaults in order to create an appearance that is uniquely yours.

#### Getting started ---------------------------------------------------------
# Create a theme with bslib::bs_theme() then apply it to an app with the theme argument of 
# the page layout function:
fluidPage(
 theme = bslib::bs_theme(...)
)
# By default, bslib uses bootstrap v4. Using v4 instead of v3 will not cause problems when 
# using built-in components. There is, however, a possibility that might cause problems if
# you've used custom HTML. If this happens, you can force bslib to use v3 by setting 
# version = 3.

#### Shiny themes ------------------------------------------------------------
# The easiest way to change the overall look of your app is to pick a premade “bootswatch” 
# theme using the bootswatch argument to bslib::bs_theme(). For example:
ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "darkly"),
  sidebarLayout(
    sidebarPanel(
      textInput("txt", "Text input:", "text here"),
      sliderInput("slider", "Slider input:", 1, 100, 30)
    ),
    mainPanel(
      h1(paste0("Theme: darkly")),
      h2("Header 2"),
      p("Some text")
    )
  )
)
# Alternatively, you can construct your own theme using the other arguments to bs_theme() 
# like bg (background colour), fg (foreground colour) and base_font
theme <- bslib::bs_theme(
  bg = "#0b3d91", 
  fg = "white", 
  base_font = "Source Sans Pro"
)

# Note! An easy way to preview and customise your theme is to use 
# bslib::bs_theme_preview(theme). This will open a Shiny app that shows what the 
# theme looks like when applied many standard controls, and also provides you with
# interactive controls for customising the most important parameters.

#### Plot themes -------------------------------------------------------------
# If you’ve heavily customised the style of your app, you may want to also customise your 
# plots to match. Luckily, this is really easy thanks to the thematic package which 
# automatically themes ggplot2, lattice, and base plots. Just call thematic_shiny() in 
# your server function. 
library(ggplot2)

ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "darkly"),
  titlePanel("A themed plot"),
  plotOutput("plot"),
)

server <- function(input, output, session) {
  thematic::thematic_shiny()
  
  output$plot <- renderPlot({
    ggplot(mtcars, aes(wt, mpg)) +
      geom_point() +
      geom_smooth()
  }, res = 96)
}

# End file ----------------------------------------------------------------