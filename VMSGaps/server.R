#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#



# Define server logic required to draw a histogram
function(input, output, session) {

    ## Esto permite filtrar el segundo menu, para que solo
    ## muestre barcos que estaban presentes ese mes.
    searchVessel <- reactive({
      sort(unique(montlyGaps[montlyGaps$month == input$mes,]$ssvid ))
    })
    output$selectUIVessels <- renderUI({
      req(input$mes)
      selectInput("vessel", "Barcos", searchVessel())
    })

    output$distPlot <- renderPlot({
        req(input$mes)
        req(input$vessel)

  ## Process de VMS data

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
      group <- list(id = gaps$seg_id)
      time <- "time"
      error <- NA
      crs <- 4326
      #my_sftrack <- as_sftrack(data = gaps, coords = coords, group = group, time = time, error = error, crs = crs)
      my_sftraj <- as_sftraj(data = gaps, coords = coords, group = group, time = time, error = error, crs = crs)

## Now manipulate the AIS data

      aisAll <- as.data.frame(aisxgaps) %>%
        mutate(month = month(timestamp)) %>%
        filter(n_name == input$vessel) %>%
        filter(month == input$mes) %>%
        rename(hours = gapHours) %>%
        distinct(lat, lon, fullName, timestamp, hours, ssvid, month)

      AISlatlon <- aisAll %>%
        filter(!is.na(lat)) %>%
        st_as_sf(coords = c("lon", "lat"), crs=4326)

## Bounding box
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
        geom_sf(data=AISlatlon, col="yellow", cex=.1) +
        #geom_sf(data=latlon, col="red", cex=1) +
        geom_sftrack(data = my_sftraj, size = 1, step_mode = TRUE, linewidth = 1) +
        coord_sf(xlim = c(bounding$box_out[['xmin']], bounding$box_out[['xmax']]),
                 ylim = c(bounding$box_out[['ymin']], bounding$box_out[['ymax']]),
                 crs = bounding$out_crs) +
        ggtitle(paste(input$vessel, max(as.Date(lubridate::ymd_hms(gaps$timestamp))))) +
        theme_gfw_map() +
        theme(legend.position = "none")



    })


    output$tbl <- function() ({
      req(input$mes)
      req(input$vessel)

      allGaps <- montlyGaps
      gaps <- as.data.frame(allGaps) %>%
        filter(ssvid==input$vessel,
               speed > 1,
               hours >= 3) %>%
        #rename(hours = DurVacio) %>%
        filter(month == input$mes) %>%
        distinct(lat, lon, speed, course, timestamp, hours,
                 seg_id, ssvid)

      gaps <- gaps %>%
        mutate(Gap = round(hours, 1)) %>%
        select(-seg_id, -hours)

      gaps %>%
        kbl("html") %>%
        kable_styling("striped", full_width = F)
    })



}
