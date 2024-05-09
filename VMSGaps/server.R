#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)

# Define server logic required to draw a histogram
function(input, output, session) {

    ## Esto permite filtrar el segundo menu, para que solo
    ## muestre barcos que estaban presentes ese mes.
    searchVessel <- reactive({
      sort(unique(montlyGaps[montlyGaps$month == input$mes,]$ssvid ))
    })
    output$selectUIVessels <- renderUI({
      selectInput("vessel", "Barcos", searchVessel())
    })

      output$distPlot <- renderPlot({

      allGaps <- montlyGaps
      gaps <- as.data.frame(allGaps) %>%
        filter(ssvid==input$vessel) %>%
        filter(month == input$mes) %>%
        mutate(lat = if_else(hours >= 5, NA, lat),
               lon = if_else(hours >= 5, NA, lon)) %>%
        distinct(lat, lon, speed, course, timestamp, hours,
                 seg_id, ssvid)

      gaps$time <- as.POSIXct(gaps$timestamp)
      coords <- c("lon","lat")
      group <- list(id = gaps$seg_id, ssvid=gaps$ssvid)
      time <- "time"
      error <- NA
      crs <- 4326
      #my_sftrack <- as_sftrack(data = gaps, coords = coords, group = group, time = time, error = error, crs = crs)
      my_sftraj <- as_sftraj(data = gaps, coords = coords, group = group, time = time, error = error, crs = crs)

      latmin <- min(gaps$lat, na.rm=T)-3
      if (latmin < -90) {latmin <- -90}
      latmax <- max(gaps$lat, na.rm=T)+3
      if (latmax > 90)  {latmax <- 90}
      lonmin <- min(gaps$lon, na.rm=T)-3
      if (lonmin < -180){lonmin <- -180}
      lonmax <- max(gaps$lon, na.rm=T)+3
      if (lonmax > 180) {lonmax <- 180}

      bounding <- transform_box(xlim = c(lonmin, lonmax),
                                ylim = c(latmin, latmax),
                                output_crs = fishwatchr::gfw_projections("Equal Earth")$proj_string)

      latlon <- gaps %>%
        filter(!is.na(lat)) %>%
        st_as_sf(coords = c("lon", "lat"), crs=4326)

      gfw_map(theme = 'dark', res = 10, eezs = T) +
        geom_sf(data=latlon, col="red", cex=.2) +
        geom_sftrack(data = my_sftraj) +
        coord_sf(xlim = c(bounding$box_out[['xmin']], bounding$box_out[['xmax']]),
                 ylim = c(bounding$box_out[['ymin']], bounding$box_out[['ymax']]),
                 crs = bounding$out_crs) +
        ggtitle(paste(input$vessel, max(as.Date(lubridate::ymd_hms(gaps$timestamp))))) +
        theme_gfw_map() +
        theme(legend.position = "none")
    })

}
