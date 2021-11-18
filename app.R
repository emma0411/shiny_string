#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
## Emma Amors Belda 
library(reticulate)

library(shiny)
library(reticulate)
#knitr::knit_engines$set(python = reticulate::eng_python)
library(rsconnect)
library(stringr)
library(ggplot2)
library(dplyr)
library(shinythemes)
library(shinydashboard)
#library(emo) 
library(devtools)
library(fresh)
library(highcharter)
library(shinyWidgets)
library(lubridate)
library(readr)
library(leaflet)

#py_install('pip')
#py_install('numpy')
#py_install('pandas')


# here we generate the shiny app


ui <- fluidPage(
    
    theme = shinytheme('flatly'),
    
    navbarPage(title = 'Max string size', id = 'TabApp',
               
               header = tagList(
                   
                   useShinydashboard()
               ),
               
               tabPanel('Home',
                        fluidRow(
                            column(8,
                                   #h1('String size calculation')
                                   HTML("<h2 class='text-center fit-h2' style='font-size: 4em; margin-bottom: 3%; color:#3B4681; font-family: 'Lato';'>String size calculation</h1>")
                            )
                        ),
                        hr(),
                        br(),
                        br(),
                        br(),
                        includeHTML("home.html")
               ),
               
               tabPanel('Module', 
                        
                        fluidRow(
                            column(8,
                                   h1('Solar Photovoltaic String Length Calculator')
                            ),
                            column(4,
                                   img(src='https://www.elecnor.com/resources/files/1/elecnor-logo2.png', align = "right")
                            )
                        ),
                        br(),
                        hr(),
                        br(),
                        h2('·Provide location of installation'),
                        br(),
                        box(title = 'Location', width = 12, status = "primary", solidHeader = T, collapsible = T,collapsed = F,
                            
                            box(title = 'Coordenadas', width = 3, status = "primary", solidHeader = F, collapsible = T,collapsed = F,
                                
                            numericInput(inputId = 'Lat', 
                                         label = 'Latitud', 
                                         value = 0,
                                         min = -90, 
                                         max = 90, 
                                         step = 0.01), 
                            
                            numericInput(inputId = 'Lon', 
                                         label = 'Longitud', 
                                         value = 0,
                                         min = -90, 
                                         max = 90, 
                                         step = 0.01)
                            ),
                            box(width = 9, status = "primary", solidHeader = F, collapsible = F,collapsed = F,
                            leafletOutput('mymap')
                            )
                        ),
                        
                        
                        br(),
                        br(),
                        h2('·Provide details on module and installation type'),
                        br(),
                        
                        fluidRow(
                            column(4,
                                   
                                   box(title = 'Weather', width = 12, status = "primary", solidHeader = T, collapsible = T,collapsed = F,
                                       awesomeRadio(inputId = 'sourceweather',
                                                    label = 'Source',
                                                    choices = c('PVgis (default)'= 'defaultpvgis',
                                                                'Load my weather' = 'myweather')
                                       ),
                                       
                                       uiOutput('cargalosdatos'),
                                       #fileInput("DatosFichero", paste("Selecciona el fichero de datos"), accept = NULL),
                                       
                                       box(title = 'Time', width = 12, status = "primary", solidHeader = F, collapsible = T,collapsed = T,
                                           
                                           dropdown(style = "unite", icon = icon("info"),
                                                    status = "warning", width = "300px",
                                                    h6('Estadisticos temporales basados en el fichero de datos. Si no se introduce archivo, 
                                                          dejar por defecto.')),
                                           
                                           numericInput(inputId = 'interval_in_hours', 
                                                        label = 'Intervalo horario', 
                                                        value = 1, 
                                                        min = 0, 
                                                        max = 24, 
                                                        step = 0.25), 
                                           
                                           numericInput(inputId = 'timedelta_in_year', 
                                                        label = 'Intervalo anos', 
                                                        value = 1, 
                                                        min = 1, 
                                                        max = 50, 
                                                        step = 0.01)
                                       )
                                        
                                       
                                       
                                   ),
                                   
                                   box(title = 'Max string length', width = 12, status = "primary", solidHeader = T, collapsible = T,collapsed = F,
                                       
                                       numericInput(inputId = 'stringlen', 
                                                    label = 'Max string voltage', 
                                                    value = 1500, 
                                                    min = 0, 
                                                    max = 2000, 
                                                    step = 5)
                                       
                                   ),
                                   
                                   
                                   box(title = 'Termal model', width = 12, status = "primary", solidHeader = T, collapsible = T,collapsed = F,
                                       radioButtons(inputId = 'termalmodel',
                                                    label = 'Choose termal model',
                                                    choices = c('Sandia model'= 'sandia',
                                                                'Fairman model' = 'fairman')
                                       ),
                                       box(title = 'Params', width = 12, status = "primary", solidHeader = F, collapsible = T,collapsed = T,
                                           fluidRow(column(10, 
                                                           h3('Sandia model')),
                                                    column(2, 
                                                           dropdown(style = "unite", icon = icon("info"),
                                                                    status = "success", width = "600px",
                                                                    h6('Model parameters depend both on the module construction and its mounting'),
                                                                    tableOutput('Sandiaparametros')))
                                                    ),
                                           
                                           numericInput(inputId = 'a', 
                                                        label = 'a', 
                                                        value = -3.47, 
                                                        min = -4, 
                                                        max = -1, 
                                                        step = 0.01),
                                           numericInput(inputId = 'b', 
                                                        label = 'b', 
                                                        value = -0.0594, 
                                                        min = -1, 
                                                        max = 0, 
                                                        step = 0.01),
                                           numericInput(inputId = 'deltaT', 
                                                        label = 'Gradiente temperatura [C]', 
                                                        value = 3, 
                                                        min = 0, 
                                                        max = 3, 
                                                        step = 1),
                                           br(),
                                           h3('Fairman model'),
                                           numericInput(inputId = 'u0', 
                                                        label = 'Uo', 
                                                        value = 26, 
                                                        min = 0, 
                                                        max = 50, 
                                                        step = 0.1),
                                           numericInput(inputId = 'u1', 
                                                        label = 'U1', 
                                                        value = 1.4, 
                                                        min = 0, 
                                                        max = 30, 
                                                        step = 0.1),
                                       )
                                   )
                                   
                            ), 
                            column(4, 
                                   
                                   box(title = 'Choose Module Parameters', width = 12, status = "success", solidHeader = T, collapsible = F,collapsed = F,
                                       h4('NCelS'),
                                       numericInput(inputId = 'cellinseries', 
                                                    label = 'Number of scells in series in each module', 
                                                    value = 1, 
                                                    min = 1, 
                                                    max = 200, 
                                                    step = 1),
                                       br(),
                                       h4('Voco'),
                                       numericInput(inputId = 'Voco', 
                                                    label = 'Open circuit voltage at reference conditions, in Volts.', 
                                                    value = 35, 
                                                    min = 1, 
                                                    max = 100, 
                                                    step = 0.01),
                                       br(),
                                       h4('Bvoco'),
                                       numericInput(inputId = 'Bvoco', 
                                                    label = 'Temperature coefficient of Voc, in Volt/C', 
                                                    value = -0.2, 
                                                    min = -2, 
                                                    max = 0.001, 
                                                    step = 0.001),
                                       br(),
                                       h4('Isco'),
                                       numericInput(inputId = 'Isco', 
                                                    label = 'Short circuit current, in Amp', 
                                                    value = 8, 
                                                    min = 1, 
                                                    max = 50, 
                                                    step = 0.01),
                                       br(),
                                       h4('Alpha sc'),
                                       numericInput(inputId = 'alpha_sc', 
                                                    label = 'Short circuit current temperature coefficient, in Amp/C', 
                                                    value = 0.05, 
                                                    min = 0, 
                                                    max = 5, 
                                                    step = 0.01),
                                       br(),
                                       h4('Efficiency'),
                                       numericInput(inputId = 'efficiency', 
                                                    label = 'Module efficiency, unitless', 
                                                    value = 0.207, 
                                                    min = 0, 
                                                    max = 1, 
                                                    step = 0.001),
                                       br(),
                                       h4('N diode'),
                                       numericInput(inputId = 'n_diode', 
                                                    label = 'Diode Ideality Factor, unitless', 
                                                    value = 3, 
                                                    min = 0, 
                                                    max = 50, 
                                                    step = 1),
                                       br(),
                                       h4('FD'),
                                       numericInput(inputId = 'FD', 
                                                    label = 'Fracion of diffuse irradiance used by the module.', 
                                                    value = 1, 
                                                    min = 0, 
                                                    max = 1, 
                                                    step = 0.01),
                                       br(),
                                       h4('Bifaciality Factor'),
                                       numericInput(inputId = 'bifaciality_factor', 
                                                    label = 'Ratio of backside to frontside efficiency for bifacial modules.', 
                                                    value = 0.7, 
                                                    min = 0, 
                                                    max = 1, 
                                                    step = 0.01)
                                   )
                            ),
                            
                            column(4,
                                   box(title = 'Choose Racking Method', width = 12, status = "success", solidHeader = T, collapsible = F,collapsed = F,
                                       
                                       radioButtons(inputId = 'racking',
                                                    label = 'Racking type',
                                                    choices = c('Single axis'= 'single_axis',
                                                                'Fixed tilt' = 'fixed_tilt')
                                       ),
                                       numericInput(inputId = 'albedo', 
                                                    label = 'Ground albedo', 
                                                    value = 0.25, 
                                                    min = 0, 
                                                    max = 1, 
                                                    step = 0.01),
                                       
                                       box(title = 'Single Axis', width = 12, status = "success", solidHeader = F, collapsible = T,collapsed = T,
                                           h4('Axis Tilt (degrees)'),
                                           numericInput(inputId = 'axis_tilt', 
                                                        label = 'The tilt of the axis of rotation with respect to horizontal, in degrees.', 
                                                        value = 0, 
                                                        min = 0, 
                                                        max = 90, 
                                                        step = 1),
                                           br(),
                                           h4('Axis Azimuth (degrees)'),
                                           numericInput(inputId = 'axis_azimuth', 
                                                        label = 'Compass direction along which the axis of rotation lies. Measured in degrees
                                                      East of North.', 
                                                        value = 0, 
                                                        min = 0, 
                                                        max = 90, 
                                                        step = 1),
                                           br(),
                                           h4('Max angle (degrees)'),
                                           numericInput(inputId = 'max_angle', 
                                                        label = 'Maximum rotation angle of the one-axis tracker from its horizontal.
                                                       position, in degrees', 
                                                        value = 50, 
                                                        min = 0, 
                                                        max = 90, 
                                                        step = 1),
                                           br(),
                                           h4('Ground coverage ratio'),
                                           numericInput(inputId = 'gcr', 
                                                        label = 'A value denoting the ground coverage ratio of a tracker system which
                                                        utilizes backtracking; i.e. the ratio between the PV array surface area to total
                                                       ground area.', 
                                                        value = 0.3, 
                                                        min = 0, 
                                                        max = 1, 
                                                        step = 0.001),
                                           br(),
                                           h4('Back side'),
                                           numericInput(inputId = 'backside',
                                                        label = 'Proportionality factor determining the backside irradiance as a fraction
                                                        of the frontside irradiance.', 
                                                        value = 0.2, 
                                                        min = 0, 
                                                        max = 1, 
                                                        step =0.1)
                                           
                                       ),
                                       box(title = 'Fixed tilt', width = 12, status = "success", solidHeader = F, collapsible = T,collapsed = T,
                                           h4('Surface Tilt (degrees)'),
                                           numericInput(inputId = 'surface_tilt', 
                                                        label = 'Tilt of modules from horizontal', 
                                                        value = 0, 
                                                        min = 0, 
                                                        max = 90, 
                                                        step = 1),
                                           br(),
                                           h4('Surface azimuth (degrees)'),
                                           numericInput(inputId = 'surface_azimuth', 
                                                        label = 'Azimuth. 180 degrees orients the modules towards the South', 
                                                        value = 180, 
                                                        min = 0, 
                                                        max = 360, 
                                                        step = 1)
                                       )
                                   ),
                                   
                                   box(title = 'Safety params', width = 12, status = "warning", solidHeader = T, collapsible = F,collapsed = F,
                                       h5('Provide safety factor'),
                                       numericInput(inputId = 'Voco_security', 
                                                    label = 'Voco security (Voco+S*Voco)', 
                                                    value = 0.02, 
                                                    min = 0, 
                                                    max = 1, 
                                                    step = 0.01),
                                       numericInput(inputId = 'Bvoco_security', 
                                                    label = 'Bvoco security (Bvoco+S*Bvoco)', 
                                                    value = 0.02, 
                                                    min = 0, 
                                                    max = 1, 
                                                    step = 0.01),
                                       numericInput(inputId = 'temp_security', 
                                                    label = 'Temperature security (Temp-S)', 
                                                    value = 1.5, 
                                                    min = 0, 
                                                    max = 50, 
                                                    step = 0.1),
                                       numericInput(inputId = 'wind_security', 
                                                    label = 'Wind security (wind*S)', 
                                                    value = 2.5, 
                                                    min = 1, 
                                                    max = 20, 
                                                    step = 0.1)
                                       
                                   )
                            )
                            
                            
                            
                        )
                        
               ),
               
               tabPanel(title = 'Results', 
                        
                        fluidRow(
                            column(8,
                                   h1('Voc results')
                            ),
                            column(4,
                                   img(src='https://www.elecnor.com/resources/files/1/elecnor-logo2.png', align = "right")
                            )
                        ),
                        br(),
                        hr(),
                        br(),
                        br(),
                        box(width = 3, status = 'warning', solidHeader = F, collapsible = F, collapsed = F,
                            textOutput('Location11'),
                            textOutput('Location12'),
                            textOutput('ThermalModel')
                        ),
                        
                        
                        downloadButton('download', 'Download the results'),
                        downloadButton('download3', 'Download the csv'),
                        
                        box(title = 'Resultados', width = 12, status = 'primary', solidHeader = T, collapsible = F, collapsed = F, 
                            
                            dataTableOutput('resultadosvoc')
                            
                        ),
                        box(title = 'Figure 1. Histogram of Voc values over the simulation time', width = 8, offset = 2, status = 'primary', solidHeader = T, collapsible = F, collapsed = F,
                            highchartOutput('figure11')
                        )
                        
               ),
               
               tabPanel(title = 'Weather',
                        
                        fluidRow(
                            column(8,
                                   h1('Weather data')
                            ),
                        ),
                        br(),
                        hr(),
                        br(),
                        br(),
                        fluidRow(
                        box(width = 3, status = 'danger', solidHeader = F, collapsible = F, collapsed = F,
                            textOutput('Locationn'),
                            textOutput('decirdedonde')
                        ),
                        
                        downloadButton('download2', 'Download the data')
                        ),
                        br(),
                        br(),
                        
                        box(title = 'Resultados', width = 6, status = 'danger', solidHeader = T, collapsible = F, collapsed = F, 
                            dataTableOutput('weatherdata')
                            
                        ),
                        box(title = 'Data Source: PVgis', width = 4, status = 'danger', solidHeader = T, collapsible = F, collapsed = F,
                        tableOutput('weatherdata2')
                        )
               )
              #tabPanel(title = '', 
              #         
              #         
              #         box(title = 'Figure 1. Histogram of Voc values over the simulation time', width = 8, offset = 2, status = 'primary', solidHeader = T, collapsible = F, collapsed = F,
              #         highchartOutput('figure11')
              #         )
              #)
               
    )
    
)



server <- function(input,output){
    
    # ------------------ App virtualenv setup (Do not edit) ------------------- #
    
    virtualenv_dir = Sys.getenv('VIRTUALENV_NAME')
    python_path = Sys.getenv('PYTHON_PATH')
    
    # Create virtual env and install dependencies
    reticulate::virtualenv_create(envname = virtualenv_dir, python = python_path)
    #reticulate::virtualenv_install(virtualenv_dir, packages = PYTHON_DEPENDENCIES, ignore_installed=TRUE)
    reticulate::use_virtualenv(virtualenv_dir, required = T)
    
    py_install('pvlib', pip = TRUE)
    py_install('vocmax', pip = TRUE)
    
    np <- import('numpy')
    pvlib <- import('pvlib', convert = F)
    pd <- import('pandas')
    vocmax <- import('vocmax') 
    source_python('simulate_system.py')
    source_python('simulate_system2.py')
    source_python('figure1.py')
    source_python('calculos.py')
    
    
    output$Sandiaparametros <- renderTable({
        df <- data.frame(Module = c('glass/glass', 'glass/glass', 'glass/polymer', 'glass/polymer'),
                         Mounting = c('open rack', 'close roof', 'open rack', 'insulated back'),
                         a = c(-3.47, -2.98, -3.56, -2.81), 
                         b = c(-0.0594, -0.0471, -0.075, -0.0455), 
                         AT = c(3, 1, 3, 0))
        df
        
    })
    
    output$cargalosdatos <- renderUI({
        if(input$sourceweather == 'myweather'){
        fileInput("DatosFichero", paste("Selecciona el fichero de datos"), accept = NULL)
        }       
    })
    
    output$mymap <- renderLeaflet({
        leaflet() %>%
            addProviderTiles(#providers$Stamen.TonerLite,
                             #options = providerTileOptions(noWrap = TRUE)
                                #"Esri.WorldImagery"
                "Esri.WorldTopoMap") %>%
            addMarkers(input$Lon, input$Lat) %>%
            setView(lng = input$Lon, lat = input$Lat, zoom =3.5) 
    })
    
    output$Location11 <- renderText(
        paste('Your latitude: ', input$Lat)
        
    )
    
    output$Location12 <- renderText(
        paste('Your longitude: ', input$Lon)
        
    )
    
    output$ThermalModel <- renderText(
        paste('Thermal Model: ', input$termalmodel )
    )
    
    
    mydatosweather <- reactive({
        req(input$DatosFichero)
        a <- input$DatosFichero
        req(a) # evita el error que se produce cuando aún no se ha cargado el fichero
        #nombre_variable <- load(a$datapath) # nombre del dataframe dentro del fichero
        #vars <- eval(parse(text=nombre_variable)) # evalua 'names' del dataframe
        vars <- read_delim(a$datapath, delim = ";", escape_double = FALSE, trim_ws = TRUE, show_col_types = FALSE)
        return(vars)
        print(a$datapath)
    })
    
    thedata <- reactive(
        
        if(input$sourceweather == 'defaultpvgis'){
            simulate_system(
                latitude = input$Lat, 
                longitude = input$Lon, 
                racking = input$racking,
                surface_tilt = input$surface_tilt, 
                surface_azimuth = input$surface_azimuth , 
                axis_tilt = input$axis_tilt, 
                axis_azimuth = input$axis_azimuth,
                max_angle = input$max_angle,
                gcr = input$gcr,
                albedo = input$albedo,
                a = input$a,
                b = input$b, 
                deltaT = input$deltaT,
                FD = input$FD,
                cells_in_series = input$cellinseries, 
                Voco = input$Voco + input$Voco_security*input$Voco,
                Bvoco = input$Bvoco - input$Bvoco_security*input$Bvoco,
                Isco = input$Isco,
                alpha_sc = input$alpha_sc,
                efficiency = input$efficiency, 
                n_diode = input$n_diode,
                bifaciality_factor = input$bifaciality_factor,
                max_string_voltage = input$stringlen,
                interval_in_hours = input$interval_in_hours , 
                timedelta_in_year = input$timedelta_in_year,
                termalmodel = input$termalmodel, 
                u1 = input$u1 ,
                u0 = input$u0,
                tempsec = input$temp_security,
                windsec = input$wind_security
            )
        }else{
            simulate_system2(
                path = input$DatosFichero$datapath,
                latitude = input$Lat, 
                longitude = input$Lon, 
                racking = input$racking,
                surface_tilt = input$surface_tilt, 
                surface_azimuth = input$surface_azimuth , 
                axis_tilt = input$axis_tilt, 
                axis_azimuth = input$axis_azimuth,
                max_angle = input$max_angle,
                gcr = input$gcr,
                albedo = input$albedo,
                a = input$a,
                b = input$b, 
                deltaT = input$deltaT,
                FD = input$FD,
                cells_in_series = input$cellinseries, 
                Voco = input$Voco + input$Voco_security*input$Voco,
                Bvoco = input$Bvoco - input$Bvoco_security*input$Bvoco,
                Isco = input$Isco,
                alpha_sc = input$alpha_sc,
                efficiency = input$efficiency, 
                n_diode = input$n_diode,
                bifaciality_factor = input$bifaciality_factor,
                max_string_voltage = input$stringlen,
                interval_in_hours = input$interval_in_hours , 
                timedelta_in_year = input$timedelta_in_year,
                termalmodel = input$termalmodel, 
                u1 = input$u1 ,
                u0 = input$u0,
                tempsec = input$temp_security,
                windsec = input$wind_security
                
            )
        }
    )
    
    output$resultadosvoc <- renderDataTable({
        thedata()
    })
    
    
    
    output$download <- downloadHandler(
        #filename = function(){'summary.pdf'},
        "summary.html",
        content = function(file){
            #write.csv(thedata(), fname)
            rmarkdown::render(
                input = "report.Rmd",
                output_file = "report.html",
                params = list(table = thedata(),
                              n = input$Lat, 
                              m = input$Lon,
                              model = input$termalmodel, 
                              figure = m()))
            readBin(con = "report.html", 
                    what = "raw",
                    n = file.info("report.html")[, "size"]) %>%
                writeBin(con = file)
        }
        
            
        )
    
    
    
    output$Locationn <- renderText(
        paste('Latitude:', input$Lat, '   Longitude:', input$Lon)
        
    )
    
    output$decirdedonde <- renderText(
        paste('Source:', input$sourceweather)
    )
    
    thedata2 <- reactive(
        if(input$sourceweather == 'defaultpvgis'){
         #py_to_r(pvlib$iotools$get_pvgis_tmy(lat = input$Lat, lon =  input$Lon, outputformat = 'csv')[0L])
         locationpvlib(lat = input$Lat, lon =  input$Lon)
        }else{
         mydatosweather() 
        }
        
    )
    
    output$download2 <- downloadHandler(
        filename = function(){'weather.csv'},
        content = function(fname){
            write.csv(thedata2(), fname)
    })
    
    output$weatherdata <- renderDataTable({
        data <- thedata2()
        #df <- data[0L]
        #df1 <- py_to_r(df)
        df1 <- data
        df1$time <- as_datetime(rownames(df1))
        df1
        ## generate weather dataframe
        #weather <- data.frame(year = rep(c(2010), times = dim(df)[1]))
        #rownames(weather) <- rownames(df1)
        #weather['month'] = month(df1$time)
        #weather['day'] = day(df1$time)
        #weather['hour'] = hour(df1$time)
        #weather['minute'] = minute(df1$time)
        #weather['DNI'] = df1[['Gb(n)']]
        #weather['GHI'] = df1[['G(h)']]
        #weather['DHI'] = df1[['Gd(h)']]
        #weather['Temperature'] = df1$T2m - 1.5
        #weather['Wind Speed'] = df1$WS10m*3
        #weather
    }) 
    
    output$weatherdata2 <- renderTable({
        data.frame(Variable = c('T2m', 'RH', 'G(h)', 'Gb(n)', 'Gd(h)', 'IR(h)', 'WS10m', 'WD10m', 'SP'), 
                   Describe = c('2-m temperature (degree Celsius)', 
                                'Relative humidity(%)',
                                'Global irradiance on the horizontal plane (W/m2)',
                                'Beam/direct irradiance on a plane always normal to sun rays (W/m2)',
                                'Diffuse irradiance on the horizontal plane (W/m2)',
                                'Surface infrared (thermal) irradiance on a horizontal plane (W/m2)',
                                '10-m total wind speed (m/s)',
                                '10-m wind direction (0 = N, 90 = E) (degree)',
                                'Surface (air) pressure (Pa)'
                                )
                   )
    }) 
    
    # gricos
    
    output$download3 <- downloadHandler(
        filename = function(){'calculosvoc.csv'},
        content = function(fname){
            write.csv(calculitos(), fname)
        })
    
    calculitos <-  reactive(
       calculos(
            latitude = input$Lat, 
            longitude = input$Lon, 
            racking = input$racking,
            surface_tilt = input$surface_tilt, 
            surface_azimuth = input$surface_azimuth , 
            axis_tilt = input$axis_tilt, 
            axis_azimuth = input$axis_azimuth,
            max_angle = input$max_angle,
            gcr = input$gcr,
            albedo = input$albedo,
            a = input$a,
            b = input$b, 
            deltaT = input$deltaT,
            FD = input$FD,
            cells_in_series = input$cellinseries, 
            Voco = input$Voco + input$Voco_security*input$Voco,
            Bvoco = input$Bvoco - input$Bvoco_security*input$Bvoco,
            Isco = input$Isco,
            alpha_sc = input$alpha_sc,
            efficiency = input$efficiency, 
            n_diode = input$n_diode,
            bifaciality_factor = input$bifaciality_factor,
            max_string_voltage = input$stringlen,
            interval_in_hours = input$interval_in_hours , 
            timedelta_in_year = input$timedelta_in_year,
            termalmodel = input$termalmodel, 
            u1 = input$u1 ,
            u0 = input$u0,
            tempsec = input$temp_security,
            windsec = input$wind_security
        )
        
    )
    
    
    m <-  reactive(
        figure1(
            latitude = input$Lat, 
            longitude = input$Lon, 
            racking = input$racking,
            surface_tilt = input$surface_tilt, 
            surface_azimuth = input$surface_azimuth , 
            axis_tilt = input$axis_tilt, 
            axis_azimuth = input$axis_azimuth,
            max_angle = input$max_angle,
            gcr = input$gcr,
            albedo = input$albedo,
            a = input$a,
            b = input$b, 
            deltaT = input$deltaT,
            FD = input$FD,
            cells_in_series = input$cellinseries, 
            Voco = input$Voco + input$Voco_security*input$Voco,
            Bvoco = input$Bvoco - input$Bvoco_security*input$Bvoco,
            Isco = input$Isco,
            alpha_sc = input$alpha_sc,
            efficiency = input$efficiency, 
            n_diode = input$n_diode,
            bifaciality_factor = input$bifaciality_factor,
            max_string_voltage = input$stringlen,
            interval_in_hours = input$interval_in_hours , 
            timedelta_in_year = input$timedelta_in_year,
            termalmodel = input$termalmodel, 
            u1 = input$u1 ,
            u0 = input$u0,
            tempsec = input$temp_security,
            windsec = input$wind_security
        )
        
    )
    
    output$figure11 <- renderHighchart({
        
        
        datafigure1 <- data.frame(Voc = m()[[1]], hoursyears = m()[[2]])
        
        datafigure1 %>% hchart('column', hcaes(x =Voc, y = hoursyears)) %>% 
            hc_title(text = 'Histogram') %>%
            #hc_subtitle(text = paste(input$termalmodel)) %>%
            hc_xAxis(title = list(text = 'P99.5'),
                     plotLines = list(
                         list(
                            value = thedata()[[2]][1],
                            color = '#ff0000',
                            width = 3,
                            label = list(text = paste('P99.5: ', round(thedata()[[2]][1], digits = 2 )))),
                         list(
                             value = thedata()[[2]][2],
                             color = '#2AE06E',
                             width = 3,
                             label = list(text = paste('Hist: ', round(thedata()[[2]][2], digits = 2 )))),
                         list(
                             value = thedata()[[2]][3],
                             color = '#D9D843',
                             width = 3,
                             label = list(text = paste('Trad: ', round(thedata()[[2]][3], digits = 2 )))),
                         list(
                             value = thedata()[[2]][4],
                             color = '#0412E4',
                             width = 3,
                             label = list(text = paste('Trad daytime: ', round(thedata()[[2]][4], digits = 2 ))))
                         )) %>%
            hc_legend(enabled = TRUE)
        
    })
    
} 

shinyApp(ui = ui, server = server)

