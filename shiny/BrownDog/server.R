library(shiny)
library(leaflet)
library(RPostgreSQL)
library(PEcAn.DB)
library(PEcAn.visualization)


# Define server logic
server <- shinyServer(function(input, output, session) {
  output$typeSelector <- renderUI({
    # get the files in library PEcAn.data.atmosphere under registration
    data.atmosphere.registration <- system.file("registration", package="PEcAn.data.atmosphere")
    datatype <- list.files(data.atmosphere.registration)
    # convert a list of string like "register.AmerifluxLBL.xml" to "AmerifluxLBL"
    datatype <- gsub("register.", "", datatype)
    datatype <- gsub(".xml", "", datatype)
    selectInput("type", "Type", datatype)
  })
  
  output$modelSelector <- renderUI({
    bety <- betyConnect("../../web/config.php")
    con <- bety$con
    on.exit(db.close(con))
    models <- db.query("SELECT name FROM modeltypes;", con)
    selectInput("model", "Model", models)
  })
  
  output$agreementUI <- renderUI({
    if (is.null(input$type)) {
      return()
    }
    
    # Depending on input$type, we'll generate a different lincense agreement
    switch(
      input$type,
      "Ameriflux" = checkboxInput(
        "agreement",
        HTML(
          "I agree to <a href='http://ameriflux.lbl.gov/data/data-policy/'>AmeriFlux license</a>."
        ),
        value = FALSE,
        width = NULL
      ),
      "NARR" = checkboxInput(
        "agreement",
        HTML(
          "I agree to <a href='http://www.esrl.noaa.gov/psd/data/gridded/data.narr.html'>NARR license</a>."
        ),
        value = FALSE,
        width = NULL
      ),
      "Fluxnet2015" = checkboxInput(
        "agreement",
        HTML("I agree to FLUXNET license."),
        value = FALSE,
        width = NULL
      )
    )
  })
  
  observeEvent(input$type, {
    # get all sites name, lat and lon by sitegroups
    bety <- betyConnect("../../web/config.php")
    con <- bety$con
    on.exit(db.close(con))
    sites <-
      db.query(
        paste0(
          "SELECT sitename, ST_X(ST_CENTROID(geometry)) AS lon, ST_Y(ST_CENTROID(geometry))
          AS lat FROM sites, sitegroups_sites where sites.id = sitegroups_sites.site_id
          and sitegroups_sites.sitegroup_id in ( select id from sitegroups  where
          sitegroups.name like '",
          input$type,
          "');"
          ),
        con
        )
    
    ids <- sites$sitename
    latitude <- sites$lat
    longitude <- sites$lon
    
    # fake sites to run on local (without DB)
    # latitude<-c(35.94077, 35.83770, 35.84545, 35.81584, 35.79387, 36.05600)
    # longitude<-c(-78.58010, -78.78084, -78.72444, -78.62568, -78.64262, -78.67600)
    # ids<-c("a", "b", "c", "d", "e", "f")
    
    #add markers on the map
    map = createLeafletMap(session, 'map')
    session$onFlushed(once = TRUE, function() {
      map$addMarker(lat = latitude,
                    lng = longitude,
                    layerId = ids)
    })
    
    observe({
      click <- input$map_marker_click
      #default site is US-Dk3
      if (is.null(click)) {
        click <- list(id = "US-Dk3",
                      lat = 35.9782,
                      lng = -79.0942)
      } else{
        text <- paste(click$id)
        map$clearPopups()
        map$showPopup(click$lat, click$lng, text)
      }
      selectedsite <- reactive({
        if (is.null(input$agreement) || input$agreement) {
          paste(
            c(
              "<input>",
              paste0("  <type>", input$type, "</type>"),
              paste0("  <site>", click$id, "</site>"),
              paste0("  <lat>", click$lat, "</lat>"),
              paste0("  <lon>", click$lng, "</lon>"),
              paste0(
                "  <start_date>",
                if (input$start_date != "")
                  input$start_date
                else
                  "2001",
                "-01-01 00:00:00</start_date>"
              ),
              paste0(
                "  <end_date>",
                if (input$end_date != "")
                  input$end_date
                else
                  "2001",
                "-12-31 23:59:59</end_date>"
              ),
              "</input>"
            ),
            collapse = "\n"
          )
        }
        else{
          "Please check the agreement. "
        }
        
      })
      
      output$xmltext <- renderText({
        selectedsite()
      })
      
      output$downloadXML <- downloadHandler(
        filename = function() {
          "example.xml"
        },
        content = function(file) {
          if (is.null(input$agreement) || input$agreement) {
            writeLines(
              c(
                "<input>",
                paste0("  <type>", input$type, "</type>"),
                paste0("  <site>", click$id, "</site>"),
                paste0("  <lat>", click$lat, "</lat>"),
                paste0("  <lon>", click$lng, "</lon>"),
                paste0(
                  "  <start_date>",
                  if (input$start_date != "")
                    input$start_date
                  else
                    "2001",
                  "-01-01 00:00:00</start_date>"
                ),
                paste0(
                  "  <end_date>",
                  if (input$end_date != "")
                    input$end_date
                  else
                    "2001",
                  "-12-31 23:59:59</end_date>"
                ),
                "</input>"
              ),
              file
            )
          }
        }
      )
      
      output$downloadData <- downloadHandler(
        filename = function() {
          paste0("example.met.", input$model)
        },
        
        content = function(file) {
          xml_filename <- tempfile("pecan", fileext = ".xml")
          fileConn <- file(xml_filename)
          writeLines(selectedsite(), fileConn)
          
          # download the converted file from bdapi
          bds <- "https://bd-api-dev.ncsa.illinois.edu"
          output_path    <- "/tmp/"
          url <-
            BrownDog::convert_file(
              bds,
              xml_filename,
              paste0("met.", input$model),
              output_path,
              input$token,
              download = FALSE
            )
          BrownDog::download(url, file, input$token)
        }
      )
    })
    
  })
  
})
