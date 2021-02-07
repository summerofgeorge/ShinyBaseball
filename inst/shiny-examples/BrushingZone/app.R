library(shiny)
library(ggplot2)
library(dplyr)

ui <- fluidPage(
  theme = shinythemes::shinytheme("slate"),
  column(4, wellPanel(
  h4(id="big-heading", "In-Play Brushing App"),
  tags$style(HTML("#big-heading{color: white;}")),
#  fileInput("file1", "Read in Statcast CSV File",
#            accept = ".csv"),
#  checkboxInput("header", "Header", TRUE),
  textInput("name", "Batter Name:", value = ""),
  radioButtons("measure", "Measure:",
               c("Launch Speed",
                 "Hit", "Home Run"),
               inline = FALSE)
  )),
  column(8,
         plotOutput("plot", brush =
              brushOpts("plot_brush",
                        fill = "#0000ff")),
         tableOutput("data")
         )
)

server <- function(input, output, session) {
  options(shiny.maxRequestSize=60*1024^2)
#  the_data <- reactive({
#    file <- input$file1
#    ext <- tools::file_ext(file$datapath)
#    req(file)
#   validate(need(ext == "csv", "Please upload a csv file"))
#   read.csv(file$datapath, header = input$header)
# })

  output$plot <- renderPlot({
    add_zone <- function(){
      topKzone <- 3.5
      botKzone <- 1.6
      inKzone <- -0.85
      outKzone <- 0.85
      kZone <- data.frame(
        x=c(inKzone, inKzone, outKzone, outKzone, inKzone),
        y=c(botKzone, topKzone, topKzone, botKzone, botKzone)
      )
      geom_path(aes(.data$x, .data$y),
                data=kZone, lwd = 1)
    }
    centertitle <- function(){
      theme(plot.title = element_text(
        colour = "blue", size = 18,
        hjust = 0.5, vjust = 0.8, angle = 0))
    }
#    sc <- the_data()
    mytitle <- paste(input$name, "-", input$measure)
    if(input$measure == "Hit"){
    ggplot() +
      geom_point(data = filter(sc2019_ip,
                          player_name == input$name),
                 aes(plate_x, plate_z, color = H)) +
      add_zone() +
      ggtitle(mytitle) +
      scale_colour_manual(values =
                   c("tan", "red")) +
      centertitle() +
      coord_equal()
    } else if(input$measure == "Home Run"){
      ggplot() +
        geom_point(data = filter(sc2019_ip,
                                 player_name == input$name),
                   aes(plate_x, plate_z, color = HR)) +
        add_zone() +
        ggtitle(mytitle) +
        scale_colour_manual(values =
                  c("tan", "red")) +
        centertitle() +
        coord_equal()
    } else if(input$measure == "Launch Speed"){
      ggplot() +
        geom_point(data = filter(sc2019_ip,
                                 player_name == input$name),
                   aes(plate_x, plate_z,
                       color = launch_speed)) +
        add_zone() +
        ggtitle(mytitle) +
        centertitle() +
        coord_equal() +
        scale_color_distiller(palette="RdYlBu")
    }
  }, res = 96)

  output$data <- renderTable({
    req(input$plot_brush)
#    sc <- the_data()
    sc1 <- brushedPoints(filter(sc2019_ip,
                      player_name == input$name),
                      input$plot_brush)
    data.frame(Name = input$name,
               BIP = nrow(sc1),
               H = sum(sc1$H),
               HR = sum(sc1$HR),
               Launch_Speed =
                 mean(sc1$launch_speed),
               H_Rate = sum(sc1$H) / nrow(sc1),
               HR_Rate = sum(sc1$HR) / nrow(sc1))
  }, digits = 3, width = '75%', align = 'c',
  bordered = TRUE,
  caption = "Brushed Region Stats")
}

shinyApp(ui = ui, server = server)