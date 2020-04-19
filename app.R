library(shiny)
library(RColorBrewer)
library(markdown)
#### Source functions ####
source("Optimize_bed_partitionFunction.R")
error.bar <- function(x, y, upper, lower=upper, length=0.05,...){
  arrows(x,y+upper, x, y-lower, angle=90, code=3, length=length, ...)}
load("defaultplotdata.Rdata")
#### User Interface ####

  # Add tool to see the location of mouse
ui <- fluidPage(
  titlePanel("ICU Capacity Simulation Tool"),
  h4("By Andres Alban",tags$sup("1"),", Stephen E. Chick",tags$sup("1,2"),", Dave A. Dongelmans",tags$sup("3"),", Alexander F. van der Sluijs",tags$sup("3"),", W. Joost Wiersinga",tags$sup("3,4"),", Alexander P.J. Vlaar",tags$sup("2,3"),", and Danielle Sent",tags$sup("5")),
  p("Affiliations:",tags$sup("1"),"INSEAD Technology and Operations Management;",
                    tags$sup("2"),"INSEAD Healthcare Management Initiative;",
                    tags$sup("3"),"Amsterdam UMC, location AMC, Department of Intensive Care Medicine;",
                    tags$sup("4"),"Amsterdam UMC, location AMC, Department of Medicine, Division of Infectious Diseases;",
                    tags$sup("5"),"Amsterdam UMC, location AMC, Department of Medical Informatics, Amsterdam Public Health Research Institute;"),
  hr(),
  p("This ICU simulation tool assists in the ICU capacity decision-making during the COVID-19 pandemic. See the manual tab for more information"),
  p(strong("TO USE:")," First, fill in parameter values. Second, click 'Simulate' button. Third, go to the 'Plots' tab and scroll down to see results (may take a minute)."),
  p("Parameters for COVID-19 and non-COVID-19 patients:"),
  tags$ul(
    tags$li("Arrival rate to the ICU"),
    tags$li("Length of stay (LOS) distribution specified with median and interquartile range (IQR) or mean and standard deviation (sd)"),
    tags$li("Number of ICU beds allocated to COVID-19 and non-COVID-19 patients")
  ),
  strong("This is online supplemental material for 'ICU capacity management during the COVID-19 pandemic using a process simulation', accepted (18 april 2020) to appear as a Letter in Intensive Care Medicine (",a("https://www.springer.com/journal/134/",href="https://www.springer.com/journal/134/"),")."),
  br(),
  strong("See also ",a("https://github.com/sechick/icu-covid-sim/",href="https://github.com/sechick/icu-covid-sim/"),"for source code and additional information about the conceptual model, and predecessor work ",a("here",href = "https://papers.ssrn.com/abstract_id=3565826")," (invited for 2020 Winter Simulation Conference)"),
  p('Software provided "as is". Support not provided, feedback to', a("icucovidcap@gmail.com",href = "mailto:icucovidcap@gmail.com"),"(please also let us know if it helped)."),
  
  sidebarLayout(
    sidebarPanel(
      #Press Simulate after all settings are set correctly, can be done from every tab
      actionButton("Simulate", label = "Simulate"),
      h3("Input parameters"),
      ## First COVID patient parameters
      h4("COVID-19 patients"),
      sliderInput(inputId =  "arr_rate_COVID",label = "Arrival rate (patients per day)",min = 0.1,max = 10,value = c(1,5)),
      radioButtons(inputId =  "LOS_COVID",label = "LOS input type",choiceNames = c("Median (IQR) - assumes loglogistic distributed LOS", "Mean (sd) - assumes lognormal distributed LOS"), choiceValues = c(1,2), selected = 1),
      uiOutput("LOS_COVID_input1"),
      uiOutput("LOS_COVID_input2"),
      sliderInput(inputId = "COVID_beds",label = "Beds allocated to COVID-19 patients",min = 1, max = 150,value = c(20,35)),
      hr(),hr(),
      ## Now the parameters for the rest of the patients
      h4("Non-COVID-19 patients"),
      "If several streams of patients, enter the values for each separated by a comma (see the 'Manual' tab)",
      textInput(inputId = "arr_rate_Rest",label = "Arrival rate (patients per day)", value = 2),
      radioButtons(inputId =  "LOS_Rest",label = "LOS input type",choiceNames = c("Median (IQR)", "Mean (sd)"), choiceValues = c(1,2), selected = 2),
      uiOutput("LOS_Rest_input1"),
      uiOutput("LOS_Rest_input2"),
      sliderInput(inputId = "Rest_beds",label = "Beds allocated to non-COVID-19 patients",min = 1, max = 50,value = c(8,15)),
      h4("Additional settings"),
      p("(For an explanation of the following see the 'Manual' tab.)"),
      sliderInput(inputId = "K",label = "Period length in simulation days (The error bars evaluate the standard deviation of the performance measures in a period of this length)",min = 7,max = 60,value = 14),
      sliderInput(inputId = "N",label = "Number of periods (Number of periods simulated to estimate the standard deviation. Large values are more accurate but take longer to compute)",min = 2,max = 20,value = 10),
      sliderInput(inputId = "Bed_points",label = 'Number of values of "beds" to evaluate',min = 2, max = 4,value=2),
      sliderInput(inputId = "Arr_points",label = 'Number of values of "COVID-19 arrival rate" to evaluate',min = 2, max = 8,value=5)
    ),
    
    #mainframe to choose which variables to show and to plot the figures
    mainPanel(
      tabsetPanel(type = "tabs",id = "tabs",
                  tabPanel("Plots",
      textOutput("test"),
      # verbatimTextOutput("test"),
      conditionalPanel(condition="$('html').hasClass('shiny-busy')",
                                                  tags$div("Loading... (This may take a few minutes)",id="loadmessage")),
      h3("Throughput rate of COVID-19 patients: the number of patients per day that can go through the system:"),
      plotOutput("rej_COVID", click = "rej_COVID_click"),
      verbatimTextOutput("rej_COVID_info"),
      
      h3("The fraction of beds occupied on average for COVID-19 patients"),
      plotOutput("occ_COVID", click = "occ_COVID_click"),
      verbatimTextOutput("occ_COVID_info"),
      
      h3("The fraction of patients who need to be referred to another hospital due to capacity issues for Non-COVID-19 patients"),
      plotOutput("rej_Rest", click = "rej_Rest_click"),
      verbatimTextOutput("rej_Rest_info"),
      
      h3("The fraction of beds occupied on average for Non-COVID-19 patients"),
      plotOutput("occ_Rest", click = "occ_Rest_click"),
      verbatimTextOutput("occ_Rest_info")
    ),
    tabPanel("Manual",
             includeMarkdown("AppManual.md"))
      )
    )
  )
)

#### Server functions ####
server = function(input,output,session){
  ## Interactive inputs
  output$LOS_COVID_input1 = renderUI({numericInput(inputId =  "LOS_COVID_mean", label = paste0(ifelse(input$LOS_COVID == 1,"Median","Mean")," (days)"), value = 8)})
  output$LOS_COVID_input2 = renderUI({numericInput(inputId =  "LOS_COVID_sd", label = paste0(ifelse(input$LOS_COVID == 1,"IQR","Std. deviation")," (days)",ifelse(input$LOS_COVID == 1,": 75% quantile - 25% quantile of LOS","")), value = 8)})
  output$LOS_Rest_input1 = renderUI({textInput(inputId =  "LOS_Rest_mean", label = paste0(ifelse(input$LOS_Rest == 1,"Median","Mean")," (days)"), value = "4.4")})
  output$LOS_Rest_input2 = renderUI({textInput(inputId =  "LOS_Rest_sd", label = paste0(ifelse(input$LOS_Rest == 1,"IQR","Std. deviation")," (days)",ifelse(input$LOS_Rest == 1,": 75% quantile - 25% quantile of LOS","")), value = "9")})
  
  # output$COVID_beds_input = renderUI({sliderInput(inputId = "COVID_beds",label = )})
  
  ## Reactive variables
  rv = reactiveValues()
  
  #### Default plots ####
  
  output$rej_COVID = renderPlot({
    par(bty="l")
    plot(0,type="l",xlim = arr_rate_COVID[c(1,length(arr_rate_COVID))],ylim = c(0,max(arr_rate_COVID)+0.1),xlab = "Arrival rate (Patients per day)",ylab = "Throughput rate (Patients per day)",main = "COVID-19 patients")
    abline(a=0,b=1,col = "black",lty=3)
    for (i in 1:nrow(rej_rate_COVID)){
      # lines(arr_rate_COVID,(1 - rej_rate_COVID[i,])*arr_rate_COVID,col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[i+1], type = "o",lty = 1,pch = 19)
      lines(arr_rate_COVID,(1 - rej_rate_COVID_true[i,])*arr_rate_COVID, col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[i+1], type = "o",lty = 1,pch = 19)
      error.bar(arr_rate_COVID,(1 - rej_rate_COVID_true[i,])*arr_rate_COVID,arr_rate_COVID*rej_rate_COVID_SD[i,],col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[i+1])
    }
    legend("topleft",legend = paste0(c_specs[,1]," beds"), col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[2:(nrow(rej_rate_COVID)+1)],lty = 1,pch = 19,bty = "n",title = "ICU capacity: COVID-19")
  })
  
  output$rej_COVID_info <- renderText({
    if (is.null(input$rej_COVID_click)){
      "Click on a point on the figure to see the coordinates."
    }else{
      paste0("Arrival rate=", round(input$rej_COVID_click$x,2), "\nThroughput rate=", round(input$rej_COVID_click$y,2))
    }
  })
  
  output$occ_COVID = renderPlot({
    par(bty="l")
    plot(0,type="l",xlim = arr_rate_COVID[c(1,length(arr_rate_COVID))]*c(1,1.2),ylim = c(0,max(occ_rate_COVID)+0.1),xlab = "Arrival rate (Patients per day)",ylab = "Fraction of occupied beds",main = "COVID-19 patients")
    for (i in 1:nrow(rej_rate_COVID)){
      # lines(arr_rate_COVID,occ_rate_COVID[i,],col = brewer.pal(nrow(occ_rate_COVID)+1,"Blues")[i+1], type = "o",lty = 1,pch = 19)
      lines(arr_rate_COVID,occ_rate_COVID_true[i,], col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[i+1], type = "o",lty = 1,pch = 19)
      error.bar(arr_rate_COVID,occ_rate_COVID_true[i,],occ_rate_COVID_SD[i,], col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[i+1])
    }
    legend("topright",legend = paste0(c_specs[,1]," beds"), col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[2:(nrow(rej_rate_COVID)+1)],lty = 1,pch = 19,bty = "n",title = "ICU capacity: COVID-19")
  })
  
  output$occ_COVID_info <- renderText({
    if (is.null(input$occ_COVID_click)){
      "Click on a point on the figure to see the coordinates."
    }else{
      paste0("Arrival rate=", round(input$occ_COVID_click$x,2), "\nFraction of occupied beds=", round(input$occ_COVID_click$y,2))
    }
  })
  
  output$rej_Rest = renderPlot({
    par(bty="l")
    plot(c_specs[,2],rej_rate_Rest_true,col = brewer.pal(4,"Set1")[1],xlab = "ICU capacity: Non-COVID-19 (Beds)",ylab = "Fraction of referrals",type = "o",pch = 19, ylim = c(0,max(rej_rate_Rest_true)*1.2),xlim = c(min(c_specs[,2]),max(c_specs[,2])),main = "Non-COVID-19")
    # lines(c_specs[,2],rowMeans(rej_rate_Rest), col = brewer.pal(4,"Set1")[4], type = "o", lty = 3, pch = 15)
    error.bar(c_specs[,2],rej_rate_Rest_true,rej_rate_Rest_SD[,1],col = brewer.pal(4,"Set1")[1])
  })
  
  output$rej_Rest_info <- renderText({
    if (is.null(input$rej_Rest_click)){
      "Click on a point on the figure to see the coordinates."
    }else{
      paste0("Beds=", round(input$rej_Rest_click$x,2), "\nFraction of referrals=", round(input$rej_Rest_click$y,2))
    }
  })
  
  output$occ_Rest = renderPlot({
    par(bty="l")
    plot(c_specs[,2],occ_rate_Rest_true,col = brewer.pal(4,"Set1")[1],xlab = "ICU capacity: Non-COVID-19 (Beds)",ylab = "Fraction of occupied beds",type = "o",pch = 19, ylim = c(0,1),xlim = c(min(c_specs[,2]),max(c_specs[,2])),main = "Non-COVID-19")
    # lines(c_specs[,2],rowMeans(occ_rate_Rest), col = brewer.pal(4,"Set1")[3], type = "o", lty = 4, pch = 19)
    error.bar(c_specs[,2],occ_rate_Rest_true,occ_rate_Rest_SD[,1],col = brewer.pal(4,"Set1")[1])
  })
  
  output$occ_Rest_info <- renderText({
    if (is.null(input$occ_Rest_click)){
      "Click on a point on the figure to see the coordinates."
    }else{
      paste0("Beds=", round(input$occ_Rest_click$x,2), "\nFraction of occupied beds=", round(input$occ_Rest_click$y,2))
    }
  })
  
  #### Validate inputs ####
  observeEvent(input$Simulate,{
    arr_rate_Rest = as.numeric(unlist(strsplit(input$arr_rate_Rest,",")))
    LOS_Rest_mean = as.numeric(unlist(strsplit(input$LOS_Rest_mean,",")))
    LOS_Rest_sd = as.numeric(unlist(strsplit(input$LOS_Rest_sd,",")))
    LOS_Rest = as.numeric(unlist(strsplit(input$LOS_Rest,",")))
    specialisms_nr = length(arr_rate_Rest)
    if (length(LOS_Rest) == 1) {LOS_Rest = rep(input$LOS_Rest,specialisms_nr)}
    if (length(LOS_Rest) != specialisms_nr || length(LOS_Rest_mean) != specialisms_nr || length(LOS_Rest_sd) != specialisms_nr){
      output$test = renderText({"I need the same number of entries for the arrival rate and LOS parameters"})
    } else {
      output$rej_COVID = renderPlot({})
      output$occ_COVID = renderPlot({})
      output$rej_Rest = renderPlot({})
      output$occ_Rest = renderPlot({})
      output$test = renderText({})
      rv$trigger_simulation = input$Simulate # trigger the simulation event
    }
  })
  
  #### Run Simulation (if inputs are valid) ####
  observeEvent(rv$trigger_simulation,{
    #### Retrieve user input ####
    start = Sys.time()
    horizon = input$N*input$K # Control how long to run the simulation to reduce time or increase precision
    arr_rate_Rest = as.numeric(unlist(strsplit(input$arr_rate_Rest,",")))
    LOS_Rest = as.numeric(unlist(strsplit(input$LOS_Rest,",")))
    if (length(LOS_Rest) == 1) {LOS_Rest = rep(input$LOS_Rest,length(arr_rate_Rest))}
    arr_rate_Rest = arr_rate_Rest[arr_rate_Rest>0]
    LOS_Rest = LOS_Rest[arr_rate_Rest>0]
    LOS_Rest_mean = as.numeric(unlist(strsplit(input$LOS_Rest_mean,",")))[arr_rate_Rest>0]
    LOS_Rest_sd = as.numeric(unlist(strsplit(input$LOS_Rest_sd,",")))[arr_rate_Rest>0]
    specialisms_nr = length(arr_rate_Rest)
    
    #### Place inputs into the required format for simualtion functions ####
    trim_COVID = 28
    trim_Rest = 200
    Arr_parameters = list()
    LOS_parameters = list()
    if (specialisms_nr > 0){
      for (i in 1:specialisms_nr){
        Arr_parameters[[i]] = list("Poisson",c(1/arr_rate_Rest[i],1/arr_rate_Rest[i]))
        if (LOS_Rest[i]==1){
          shape = LOS_Rest_sd[i]/LOS_Rest_mean[i]
          shape = log(3)/log((shape+sqrt(4+shape^2))/2)
          LOS_parameters[[i]] = list("loglogis",c(shape,1/LOS_Rest_mean[i],trim_Rest))
        }else {
          sigma = sqrt(log(LOS_Rest_sd[i]^2/LOS_Rest_mean[i]^2 +1))
          mu = log(LOS_Rest_mean[i]) - log(sqrt(LOS_Rest_sd[i]^2/LOS_Rest_mean[i]^2 + 1))
          LOS_parameters[[i]] = list("lognorm",c(mu,sigma,trim_Rest))
        }
      }
    }
    if (input$LOS_COVID==1) {
      shape = input$LOS_COVID_sd/input$LOS_COVID_mean
      shape = log(3)/log((shape+sqrt(4+shape^2))/2)
      LOS_parameters[[specialisms_nr+1]] = list("loglogis",c(shape,1/input$LOS_COVID_mean,trim_COVID))
    }else {
      sigma = sqrt(log(input$LOS_COVID_sd^2/input$LOS_COVID_mean^2 +1))
      mu = log(input$LOS_COVID_mean) - log(sqrt(input$LOS_COVID_sd^2/input$LOS_COVID_mean^2 +1))
      LOS_parameters[[specialisms_nr+1]] = list("lognorm",c(mu,sigma,trim_COVID))
    }
    
    arr_rate_COVID = seq(input$arr_rate_COVID[1],input$arr_rate_COVID[2],length.out = 5)
    c_specs = round(cbind(seq(input$COVID_beds[1],input$COVID_beds[2],length.out = input$Bed_points),
                          seq(input$Rest_beds[1],input$Rest_beds[2],length.out = input$Bed_points)),digits = 0)
    
    
    
    #### Run simulations and save output ####
    cum_perf_COVID = list()
    cum_perf_Rest = list()
    cum_perf_COVID_SD = list()
    cum_perf_Rest_SD = list()
    for (i in 1:length(arr_rate_COVID)){
      Arr_parameters[[specialisms_nr+1]] = list("Poisson",c(1/arr_rate_COVID[i],1/arr_rate_COVID[i]))
      perf_lists = OptimizePartition(Arr_parameters=Arr_parameters[specialisms_nr+1],LOS_parameters=LOS_parameters[specialisms_nr+1],c_specs=cbind(c_specs[,1]),N=input$N,K=input$K)
      cum_perf_COVID[[i]] = perf_lists[[1]][[1]]
      cum_perf_COVID_SD[[i]] = perf_lists[[2]][[1]]
      # if (specialisms_nr>0){
      #   cum_perf_Rest[[i]] = perf_lists[[1]][[2]]
      #   cum_perf_Rest_SD[[i]] = perf_lists[[2]][[2]]
      #   }
    }
    if (specialisms_nr>0){
      spec = rep(1,specialisms_nr)
      c_specs_Rest = if(specialisms_nr==1) cbind(c_specs[,1]) else c_specs[,1:specialisms_nr]
      perf_lists = OptimizePartition(Arr_parameters=Arr_parameters[1:specialisms_nr],LOS_parameters=LOS_parameters[1:specialisms_nr],c_specs=cbind(c_specs[,2]),N=input$N,K=input$K,spec=spec)
      cum_perf_Rest[[1]] = perf_lists[[1]][[1]]
      cum_perf_Rest_SD[[1]] = perf_lists[[2]][[1]]
    }
    rej_rate_COVID = sapply(cum_perf_COVID, function(x) x$rej_rate)
    rej_rate_COVID_SD = sapply(cum_perf_COVID_SD, function(x) x$rej_rate)
    rej_rate_Rest = sapply(cum_perf_Rest, function(x) x$rej_rate)
    rej_rate_Rest_SD = sapply(cum_perf_Rest_SD, function(x) x$rej_rate)
    occ_rate_COVID = sapply(cum_perf_COVID, function(x) x$occ_rate)
    occ_rate_COVID_SD = sapply(cum_perf_COVID_SD, function(x) x$occ_rate)
    occ_rate_Rest = sapply(cum_perf_Rest, function(x) x$occ_rate)
    occ_rate_Rest_SD = sapply(cum_perf_Rest_SD, function(x) x$occ_rate)
    
    #### Compute closed-form solutions ####
    
    rej_rate_COVID_true = matrix(0,nrow(c_specs),length(arr_rate_COVID))
    shape = LOS_parameters[[specialisms_nr+1]][[2]][1]
    rate = LOS_parameters[[specialisms_nr+1]][[2]][2]
    LOS_COVID_mean = ifelse(input$LOS_COVID == 1,mean(pmin(rllogis(1e6,shape,rate),trim_COVID)),input$LOS_COVID_mean)
    for (i in 1:nrow(c_specs)){
      for (j in 1:length(arr_rate_COVID)){
        x = arr_rate_COVID[j]
        y = c_specs[i,1]
        rej_rate_COVID_true[i,j] = (x*LOS_COVID_mean)^y/factorial(y)/(sum((x*LOS_COVID_mean)^(0:y)/factorial(0:y)))
        }
    }
    occ_rate_COVID_true = t(outer(arr_rate_COVID,c_specs[,1], "/")) * (1-rej_rate_COVID_true)*LOS_COVID_mean
    
    if (specialisms_nr > 0){
      rej_rate_Rest_true = rep(0,nrow(c_specs))
      for (i in 1:specialisms_nr){
        shape = LOS_parameters[[i]][[2]][1]
        rate = LOS_parameters[[i]][[2]][2]
        LOS_Rest_mean[i] = ifelse(LOS_Rest[i] == 1,mean(pmin(rllogis(1e6,shape,rate),trim_Rest)),LOS_Rest_mean[i])
      }
      for (i in 1:nrow(c_specs)){
        y = c_specs[i,2]
        rej_rate_Rest_true[i] = sum(arr_rate_Rest*LOS_Rest_mean)^y/factorial(y)/(sum(sum(arr_rate_Rest*LOS_Rest_mean)^(0:y)/factorial(0:y)))
      }
      occ_rate_Rest_true = sum(arr_rate_Rest*LOS_Rest_mean)/c_specs[,2] * (1-rej_rate_Rest_true)
    }
    
    #### Output plots ####
    output$rej_COVID = renderPlot({
      par(bty="l")
      plot(0,type="l",xlim = arr_rate_COVID[c(1,length(arr_rate_COVID))],ylim = c(0,max(arr_rate_COVID)+0.1),xlab = "Arrival rate (Patients per day)",ylab = "Throughput rate (Patients per day)",main = "COVID-19 patients")
      abline(a=0,b=1,col = "black",lty=3)
      for (i in 1:nrow(rej_rate_COVID)){
        # lines(arr_rate_COVID,(1 - rej_rate_COVID[i,])*arr_rate_COVID,col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[i+1], type = "o",lty = 1,pch = 19)
        lines(arr_rate_COVID,(1 - rej_rate_COVID_true[i,])*arr_rate_COVID, col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[i+1], type = "o",lty = 1,pch = 19)
        error.bar(arr_rate_COVID,(1 - rej_rate_COVID_true[i,])*arr_rate_COVID,arr_rate_COVID*rej_rate_COVID_SD[i,],col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[i+1])
      }
      legend("topleft",legend = paste0(c_specs[,1]," beds"), col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[2:(nrow(rej_rate_COVID)+1)],lty = 1,pch = 19,bty = "n",title = "ICU capacity: COVID-19")
    })
      
    output$occ_COVID = renderPlot({
      par(bty="l")
      plot(0,type="l",xlim = arr_rate_COVID[c(1,length(arr_rate_COVID))]*c(1,1.2),ylim = c(0,max(occ_rate_COVID)+0.1),xlab = "Arrival rate (Patients per day)",ylab = "Fraction of occupied beds",main = "COVID-19 patients")
      for (i in 1:nrow(rej_rate_COVID)){
        # lines(arr_rate_COVID,occ_rate_COVID[i,],col = brewer.pal(nrow(occ_rate_COVID)+1,"Blues")[i+1], type = "o",lty = 1,pch = 19)
        lines(arr_rate_COVID,occ_rate_COVID_true[i,], col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[i+1], type = "o",lty = 1,pch = 19)
        error.bar(arr_rate_COVID,occ_rate_COVID_true[i,],occ_rate_COVID_SD[i,], col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[i+1])
      }
      legend("topright",legend = paste0(c_specs[,1]," beds"), col = brewer.pal(nrow(rej_rate_COVID)+1,"Blues")[2:(nrow(rej_rate_COVID)+1)],lty = 1,pch = 19,bty = "n",title = "ICU capacity: COVID-19")
    })
    
    output$rej_Rest = renderPlot({
      par(bty="l")
      plot(c_specs[,2],rej_rate_Rest_true,col = brewer.pal(4,"Set1")[1],xlab = "ICU capacity: Non-COVID-19 (Beds)",ylab = "Fraction of referrals",type = "o",pch = 19, ylim = c(0,max(rej_rate_Rest_true)*1.2),xlim = c(min(c_specs[,2]),max(c_specs[,2])),main = "Non-COVID-19")
      # lines(c_specs[,2],rowMeans(rej_rate_Rest), col = brewer.pal(4,"Set1")[4], type = "o", lty = 3, pch = 15)
      error.bar(c_specs[,2],rej_rate_Rest_true,rej_rate_Rest_SD[,1],col = brewer.pal(4,"Set1")[1])
      })
    
    output$occ_Rest = renderPlot({
      par(bty="l")
      plot(c_specs[,2],occ_rate_Rest_true,col = brewer.pal(4,"Set1")[1],xlab = "ICU capacity: Non-COVID-19 (Beds)",ylab = "Fraction of occupied beds",type = "o",pch = 19, ylim = c(0,1),xlim = c(min(c_specs[,2]),max(c_specs[,2])),main = "Non-COVID-19")
      # lines(c_specs[,2],rowMeans(occ_rate_Rest), col = brewer.pal(4,"Set1")[3], type = "o", lty = 4, pch = 19)
      error.bar(c_specs[,2],occ_rate_Rest_true,occ_rate_Rest_SD,col = brewer.pal(4,"Set1")[1])
    })
    
    
    ## Output text
    output$test = renderText({
      paste0("Done in ",round(difftime(Sys.time(),start,units = "secs"),0)," seconds")
    })
    
    ## Switch to Plots tab
    updateTabsetPanel(session, "tabs",selected = "Plots")
    
  })
  
  
  
  
}



#### Run Application ####
shinyApp(ui = ui, server = server)





