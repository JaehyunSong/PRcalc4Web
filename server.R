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
      
      Temp_Mat <- matrix(rep(NA_integer_, 
                             length(Party_Name) * length(Region_Name)),
                         nrow = length(Party_Name))
      Temp_Mat <- as.data.frame(Temp_Mat)
      
      names(Temp_Mat)    <- Region_Name
      rownames(Temp_Mat) <- Party_Name
      
      mydata <<- Temp_Mat
    }
    rhandsontable(mydata, stretchH = "all", digits = 0)
  }, ignoreNULL = FALSE)
  
  
  
  observeEvent(input$Calculate, {
    
    Region_Name     <- names(mydata)
    N_Party         <- nrow(mydata) - 1
    
    Temp_df    <- mydata
    Temp_Party <- data.frame(Party = rownames(Temp_df))
    Temp_df    <- cbind(Temp_Party, Temp_df)
    
    Temp_Result <- PRcalc(x         = Temp_df, 
                          threshold = input$Threshold,
                          method    = input$method)
    
    if(length(Region_Name) > 1) {
      tbl_col <- c("政党", rep(c(Region_Name, "計"), 2))
      tbl_width <- length(Region_Name) + 1
      summary_col <- c("指標", Region_Name, "計")
    } else {
      tbl_col <- c("政党", rep(Region_Name, 2))
      tbl_width <- length(Region_Name)
      summary_col <- c("指標", Region_Name)
    }
    
    output$Summary <- renderText({
      VS_df <- Rae_V <- Dhondt_V <- as_tibble(Temp_Result$VoteShare)[, -1]
      SS_df <- Rae_S <- Dhondt_S <- as_tibble(Temp_Result$SeatShare)[, -1]
      
      Rae_V[Rae_V < 0.5] <- NA
      Rae_S[Rae_S < 0.5] <- NA
      
      Dhondt_V[Dhondt_V < 0.5] <- NA
      Dhondt_S[Dhondt_S < 0.5] <- NA
      
      ENP_Vote  <- 1 / colSums((as_tibble(Temp_Result$VoteShare)[, -1] / 100)^2)
      ENP_Seat  <- 1 / colSums((as_tibble(Temp_Result$SeatShare)[, -1] / 100)^2)
      Gallagher <- sqrt(0.5 * colSums((VS_df - SS_df)^2))
      Rose      <- colSums(abs(VS_df - SS_df)) * 0.5
      Rae       <- colMeans(abs(Rae_V - Rae_S), na.rm = TRUE)
      SL        <- colSums((VS_df - SS_df)^2 / VS_df)
      Dhondt    <- map_dbl(SS_df/VS_df, max)
      Dhondt5   <- map_dbl(Dhondt_S/Dhondt_V, max, na.rm = TRUE)
      
      bind_rows(list("得票" = ENP_Vote,
                     "議席" = ENP_Seat,
                     "Gallagher" = Gallagher,
                     "Loosemore–Hanby" = Rose,
                     "Rae" = Rae,
                     "Sainte-Laguë" = SL,
                     "D'Hondt" = Dhondt,
                     "D'Hondt (5%)" = Dhondt5),
                .id = "Index") %>%
        mutate_if(is.numeric, format, digits = 2, nsmall = 2) %>%
        kable("html", col.names = summary_col) %>%
        kable_styling(bootstrap_options = c("striped", "hover", 
                                            "condensed", "responsive"), 
                      full_width = F) %>%
        pack_rows("有効政党数", 1, 2) %>%
        pack_rows("非比例性指数", 3, 8) %>%
        footnote(general = "有効政党数はLaakso and Taagepera (1979)、<br/>非比例性指数はGallagher (1991)を参照",
                 general_title = "注:",
                 escape = FALSE)
    })
    
    output$Result1 <- renderText({
      left_join(Temp_Result$Vote, Temp_Result$Seat, by = "Party") %>%
        kable("html", col.names = tbl_col) %>%
        kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), 
                      full_width = F) %>%
        add_header_above(c("", "得票数" = tbl_width, "議席数" = tbl_width))
    })
    output$Result2 <- renderText({
      left_join(Temp_Result$VoteShare, Temp_Result$SeatShare, by = "Party") %>%
        mutate_if(is.numeric, format, digits = 2, nsmall = 2) %>%
        kable("html", col.names = tbl_col) %>%
        kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), 
                      full_width = F) %>%
        add_header_above(c("", "得票率 (%)" = tbl_width, "議席率 (%)" = tbl_width))
    })
    output$Plot  <- renderPlot({
      plot(Temp_Result) + theme_gray(base_family = "IPAexGothic", base_size = 14)
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