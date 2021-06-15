shinyServer(function(input, output, session) {
  
  mydata <- data.frame()
  
  output$InputTable = renderRHandsontable(df())
  
  df <- eventReactive(input$Add_Table, {
    
    if(input$NewParty != "" && 
       !is.null(input$NewParty) && 
       input$NewRegion != "" && 
       !is.null(input$NewRegion) && 
       input$Add_Table > 0){
      
      Party_Name <- unlist(strsplit(input$NewParty, ",|、"))
      Party_Name <- gsub("[[:space:]]", "", Party_Name)
      Party_Name <- c("定数", Party_Name)
      
      Region_Name <- unlist(strsplit(input$NewRegion, ",|、"))
      Region_Name <- gsub("[[:space:]]", "", Region_Name)
      
      Temp_Mat <- matrix(rep(0, length(Party_Name) * length(Region_Name)),
                         nrow = length(Party_Name))
      Temp_Mat <- as.data.frame(Temp_Mat)
      
      names(Temp_Mat)    <- Region_Name
      rownames(Temp_Mat) <- Party_Name
      
      mydata <<- Temp_Mat
    }
    rhandsontable(mydata, stretchH = "all")
  }, ignoreNULL = FALSE)
  
  
  
  observeEvent(input$Calculate, {
    
    output$Result <- renderTable({
      
      Number_of_Seats <- unlist(mydata[1, ])
      
      if(length(Number_of_Seats) == 1) {
        Temp_df    <- data.frame(Vote = mydata[-1, ])
      } else {
        Temp_df    <- mydata[-1, ]
      }
      
      Temp_Party <- data.frame(Party = rownames(Temp_df))
      
      Temp_df    <- cbind(Temp_Party, Temp_df)
      
      Temp_Result <- PRcalc(nseat     = Number_of_Seats, 
                            vote      = Temp_df, 
                            threshold = input$Threshold,
                            method    = input$method, 
                            viewer    = FALSE)
      
      if(ncol(Temp_df) == 2) Temp_Result <- Temp_Result$df
      
      Temp_Result
      })
    output$msg  <- renderText({
      "Plot Area (forthcoming)"
      })
  })
  
  observe(
    {
      if (!is.null(input$InputTable)) {
        mydata <<- hot_to_r(input$InputTable)
      }
    }
  )
})