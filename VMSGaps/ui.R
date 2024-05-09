#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)

# Define UI for application that draws a histogram
fluidPage(
  title="Escapement Explorer",
  theme = shinytheme("flatly"),

    # Application title
    titlePanel("Vacios de Transmición"),

    # Sidebar with a slider input for number of bins
        sidebarPanel(
          selectInput("mes", "Elija el mes de interes", choices = sort(lMonth)),
          htmlOutput("selectUIVessels")
        ),

        # Show a plot of the generated distribution
        mainPanel(
        #    plotOutput("distPlot")
        #)
        tabsetPanel(type = "tabs",
                    tabPanel("Plot", plotOutput('distPlot')),
                    tabPanel("Tabla", tableOutput('tbl')),
                    tabPanel("Detalles",HTML(
                      '<b>Data Origin</b>:<br>
                            The data used in this application is Escapement_location_linked.csv

                      '))
        )
    )
)

