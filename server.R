i18n <- Translator$new(translation_json_path = "translations/translations.json")
i18n$set_translation_language('ja')
shiny.i18n::usei18n(i18n)

shinyServer(function(input, output, session) {
  
  observeEvent(input$selected_language, {
    update_lang(session, input$selected_language)
  })
  
  Add_Table_Var   <- FALSE
  Load_Sample_Var <- FALSE
  
  mydata <- data.frame()
  
  output$InputTable = renderRHandsontable(df())
  
  observeEvent(input$Add_Table, {
    Add_Table_Var <<- TRUE
  }, priority = 1)
  
  observeEvent(input$Load_Sample, {
    Load_Sample_Var <<- TRUE
  }, priority = 2)
  
  df <- eventReactive(c(input$Add_Table, input$Load_Sample), {
    
    if(Add_Table_Var == TRUE){
      
      Party_Name <- unlist(strsplit(input$NewParty, ",|、"))
      Party_Name <- gsub("[[:space:]]", "", Party_Name)
      Party_Name <- c(i18n$t("定数"), Party_Name)
      
      Region_Name <- unlist(strsplit(input$NewRegion, ",|、"))
      Region_Name <- gsub("[[:space:]]", "", Region_Name)
      
      Temp_Mat <- matrix(rep(NA_integer_, 
                             length(Party_Name) * length(Region_Name)),
                         nrow = length(Party_Name))
      Temp_Mat <- as.data.frame(Temp_Mat)
      
      names(Temp_Mat)    <- Region_Name
      rownames(Temp_Mat) <- Party_Name
      
      mydata <<- Temp_Mat
      
      Add_Table_Var <<- FALSE
      
    } else if (Load_Sample_Var == TRUE) {
      
      sample_file_path <- paste0("Sample_Data/", input$Sample, ".csv")
      
      mydata <<- read.csv(sample_file_path, row.names = 1)
      
      Load_Sample_Var <<- FALSE
    }
    rhandsontable(mydata, stretchH = "all", 
                  digits = 0, rowHeaderWidth = 75)
  }, ignoreNULL = FALSE, ignoreInit = TRUE)

  
  observeEvent(input$Calculate, {
    
    Region_Name     <- names(mydata)
    N_Party         <- nrow(mydata) - 1
    
    Temp_df    <- mydata
    Temp_Party <- data.frame(Party = rownames(Temp_df))
    Temp_df    <- cbind(Temp_Party, Temp_df)
    
    Temp_Result <- PRcalc(x         = Temp_df, 
                          threshold = input$Threshold,
                          method    = input$method)
    
    print(Temp_Result)
    
    if(length(Region_Name) > 1) {
      tbl_col <- c(i18n$t("政党"), rep(c(Region_Name, i18n$t("計")), 2))
      tbl_width <- length(Region_Name) + 1
      summary_col <- c(i18n$t("指標"), Region_Name, i18n$t("計"))
    } else {
      tbl_col <- c(i18n$t("政党"), rep(Region_Name, 2))
      tbl_width <- length(Region_Name)
      summary_col <- c(i18n$t("指標"), Region_Name)
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
      SL        <- colSums((VS_df - SS_df)^2 / VS_df, na.rm  = TRUE)
      Dhondt    <- map_dbl(SS_df/VS_df, max, na.rm = TRUE)
      Dhondt5   <- map_dbl(Dhondt_S/Dhondt_V, max, na.rm = TRUE)
      
      index_df <- bind_rows(list("得票" = ENP_Vote,
                                 "議席" = ENP_Seat,
                                 "Gallagher" = Gallagher,
                                 "Loosemore–Hanby" = Rose,
                                 "Rae" = Rae,
                                 "Sainte-Laguë" = SL,
                                 "D'Hondt" = Dhondt,
                                 "D'Hondt (5%)" = Dhondt5),
                            .id = "Index")
      
      index_df$Index <- c(i18n$t("得票"), i18n$t("議席"), index_df$Index[-(1:2)])
      
      index_df %>%
        mutate_if(is.numeric, format, digits = 2, nsmall = 2) %>%
        kable("html", col.names = summary_col) %>%
        kable_styling(bootstrap_options = c("striped", "hover", 
                                            "condensed", "responsive"), 
                      full_width = F) %>%
        pack_rows(i18n$t("有効政党数"), 1, 2) %>%
        pack_rows(i18n$t("非比例性指数"), 3, 8)
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
    output$Plot  <- renderPlotly({
      ggplotly(plot(Temp_Result))
    })
    
    # 表ダウンロード（数）
    output$Download1 <- downloadHandler(
      filename = function() {
        method <- case_when(input$method == "dt" ~ "DHondt",
                            input$method == "sl" ~ "SainteLague",
                            input$method == "msl" ~ "ModifiedSaintLague",
                            input$method == "danish" ~ "Danish",
                            input$method == "imperiali" ~ "Imperiali",
                            input$method == "hh" ~ "Hill",
                            input$method == "dean" ~ "Dean",
                            input$method == "adams" ~ "Adams",
                            input$method == "hare" ~ "Hare",
                            input$method == "droop" ~ "Droop",
                            input$method == "imperialiQ" ~ "ImperialiQ")
        paste0("PRcalc_",
               method, "_",
               str_replace(str_replace_all(Sys.time(), ":", "-"), " ", "_"),
               ".csv")
      },
      content = function(filename) {
        temp_data1 <- as_tibble(Temp_Result$Vote) %>%
          rename_with(~paste0("得票数_", .x), .cols = -1) %>%
          rename_with(~"得票数_計", .cols = ends_with("Total"))
        temp_data2 <- as_tibble(Temp_Result$Seat) %>%
          rename_with(~paste0("議席数_", .x), .cols = -1) %>%
          rename_with(~"議席数_計", .cols = ends_with("Total"))
        temp_data3 <- as_tibble(Temp_Result$VoteShare) %>%
          rename_with(~paste0("得票率_", .x), .cols = -1) %>%
          rename_with(~"得票率_計", .cols = ends_with("Total"))
        temp_data4 <- as_tibble(Temp_Result$SeatShare) %>%
          rename_with(~paste0("議席率_", .x), .cols = -1) %>%
          rename_with(~"議席率_計", .cols = ends_with("Total"))
        
        temp_data <- left_join(temp_data1, temp_data2, by = "Party") %>%
          left_join(temp_data3, by = "Party") %>% 
          left_join(temp_data4, by = "Party") %>%
          rename("政党" = "Party") %>%
          mutate(across(where(is.numeric), round, 3))
        write.csv(temp_data, filename, row.names = FALSE, 
                  fileEncoding = "UTF-8")
      }
    )
    output$Download2 <- downloadHandler(
      filename = function() {
        method <- case_when(input$method == "dt" ~ "DHondt",
                            input$method == "sl" ~ "SainteLague",
                            input$method == "msl" ~ "ModifiedSaintLague",
                            input$method == "danish" ~ "Danish",
                            input$method == "imperiali" ~ "Imperiali",
                            input$method == "hh" ~ "Hill",
                            input$method == "dean" ~ "Dean",
                            input$method == "adams" ~ "Adams",
                            input$method == "hare" ~ "Hare",
                            input$method == "droop" ~ "Droop",
                            input$method == "imperialiQ" ~ "ImperialiQ")
        paste0("PRcalc_",
               method, "_",
               str_replace(str_replace_all(Sys.time(), ":", "-"), " ", "_"),
               ".csv")
      },
      content = function(filename) {
        temp_data1 <- as_tibble(Temp_Result$Vote) %>%
          rename_with(~paste0("得票数_", .x), .cols = -1) %>%
          rename_with(~"得票数_計", .cols = ends_with("Total"))
        temp_data2 <- as_tibble(Temp_Result$Seat) %>%
          rename_with(~paste0("議席数_", .x), .cols = -1) %>%
          rename_with(~"議席数_計", .cols = ends_with("Total"))
        temp_data3 <- as_tibble(Temp_Result$VoteShare) %>%
          rename_with(~paste0("得票率_", .x), .cols = -1) %>%
          rename_with(~"得票率_計", .cols = ends_with("Total"))
        temp_data4 <- as_tibble(Temp_Result$SeatShare) %>%
          rename_with(~paste0("議席率_", .x), .cols = -1) %>%
          rename_with(~"議席率_計", .cols = ends_with("Total"))
        
        temp_data <- left_join(temp_data1, temp_data2, by = "Party") %>%
          left_join(temp_data3, by = "Party") %>% 
          left_join(temp_data4, by = "Party") %>%
          rename("政党" = "Party") %>%
          mutate(across(where(is.numeric), round, 3))
        write.csv(temp_data, filename, row.names = FALSE, 
                  fileEncoding = "CP932")
      }
    )
  })
  
  observe(
    {
      if (!is.null(input$InputTable)) {
        mydata <<- hot_to_r(input$InputTable)
      }
    }
  )
})