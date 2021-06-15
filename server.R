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
    
    Number_of_Seats <- unlist(mydata[1, ])
    Region_Name     <- names(mydata)
    N_Party         <- nrow(mydata) - 1
    
    print(Region_Name)
    
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
    
    output$Result <- renderTable({
      Temp_Result
      })
    output$Plot  <- renderPlot({
      if(ncol(Temp_df) == 2) {
        
      } else {
        Plot_df1 <- Temp_Result %>%
          pivot_longer(cols = starts_with("Vote"),
                       names_to = "Region",
                       values_to = "Vote") %>%
          mutate(Region = rep(c(Region_Name, "合計"),
                              N_Party),
                 Region = fct_inorder(Region)) %>%
          group_by(Region) %>%
          mutate(Vote_Sum = sum(Vote),
                 Vote = Vote / Vote_Sum * 100) %>%
          select(-starts_with("Seat"), -Vote_Sum)
        
        Plot_df2 <- Temp_Result %>%
          pivot_longer(cols = starts_with("Seat"),
                       names_to = "Region",
                       values_to = "Seat") %>%
          mutate(Region = rep(c(Region_Name, "合計"),
                              N_Party),
                 Region = fct_inorder(Region)) %>%
          group_by(Region) %>%
          mutate(Seat_Sum = sum(Seat),
                 Seat = Seat / Seat_Sum * 100) %>%
          ungroup() %>%
          select(-starts_with("Vote"), -Seat_Sum)
        
        Plot_df <- left_join(Plot_df1, Plot_df2, 
                             by = c("Party", "Region")) %>%
          pivot_longer(cols = Vote:Seat,
                       names_to = "Type",
                       values_to = "Count") %>%
          ungroup() %>%
          mutate(Type  = if_else(Type == "Vote", "得票", "議席"),
                 Type  = factor(Type, levels = c("得票", "議席")),
                 Party = fct_inorder(Party))

        Plot <- Plot_df %>%
          ggplot() +
          geom_bar(aes(x = Party, y = Count, fill = Type), 
                   position = position_dodge2(),
                   stat = "identity") +
          labs(x = "政党", y = "割合 (%)", fill = "") +
          facet_wrap(~Region, ncol = 3) +
          #theme_gray(base_family = "HiraKakuProN-W3",
          theme_gray(base_family = "IPAexGothic",
                     base_size   = 14) +
          theme(legend.position = "bottom")
      }
      
      Plot
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