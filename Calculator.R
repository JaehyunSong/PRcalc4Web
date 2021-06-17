i18n <- Translator$new(translation_json_path = "translations/translations.json")
i18n$set_translation_language('ja')

PRcalc <- function (x, method, threshold) {
  
  seat_vec <- as.numeric(unlist(x[1, -1]))
  temp_df  <- x[-1, ]
  
  PRcalc_Result <- MultiRegion(x = temp_df, seat = seat_vec,
                               method = method, threshold = threshold)
  
  VS_df <- PRcalc_Result$Vote
  SS_df <- PRcalc_Result$Seat
  
  if (ncol(VS_df) > 2 & ncol(SS_df) > 2) {
    PRcalc_Result$Vote$Total <- rowSums(PRcalc_Result$Vote[, -1])
    PRcalc_Result$Seat$Total <- rowSums(PRcalc_Result$Seat[, -1])
    VS_df$Total <- rowSums(VS_df[, -1])
    SS_df$Total <- rowSums(SS_df[, -1])  
  }
  
  if (ncol(VS_df) == 2 & ncol(SS_df) == 2) {
    VS_df[, -1] <- VS_df[, -1] / sum(VS_df[, -1]) * 100
    SS_df[, -1] <- SS_df[, -1] / sum(SS_df[, -1]) * 100
  } else if (ncol(VS_df) > 2 & ncol(SS_df) > 2) {
    VS_df[, -1] <- as.data.frame(map_df(VS_df[, -1], ~(.x / sum(.x) * 100)))
    SS_df[, -1] <- as.data.frame(map_df(SS_df[, -1], ~(.x / sum(.x) * 100)))
  }
  
  names(PRcalc_Result$Vote) <- str_replace(names(PRcalc_Result$Vote), ":Vote", "")
  names(PRcalc_Result$Seat) <- str_replace(names(PRcalc_Result$Seat), ":Seat", "")
  names(VS_df) <- str_replace(names(VS_df), ":Vote", "")
  names(SS_df) <- str_replace(names(SS_df), ":Seat", "")
  
  Method_full_name <- case_when(method == "hare" ~ "Hare–Niemeyer",
                                method == "droop" ~ "Droop",
                                method == "imperialiQ" ~ "Imperiali Quota",
                                method == "dt" ~ "D’Hondt (Jefferson)",
                                method == "sl" ~ "Sainte-Laguë (Webster)",
                                method == "msl" ~ "Modified Sainte-Laguë",
                                method == "hh" ~ "Huntington–Hill",
                                method == "danish" ~ "Danish",
                                method == "adams" ~ "Adams's",
                                method == "imperiali" ~ "Imperiali",
                                method == "dean" ~ "Dean")
  
  PRcalc_Result <- list(Vote = PRcalc_Result$Vote,
                        Seat = PRcalc_Result$Seat,
                        VoteShare = VS_df,
                        SeatShare = SS_df,
                        Method    = Method_full_name)
  
  class(PRcalc_Result) <- c("PRcalc", "list")
  
  PRcalc_Result
}


MultiRegion <- function(x, seat, method, threshold) {
  multi_result <- list()
  region_list <- names(x)[-1]
  
  LRM_methods <- c("hare", "droop", "imperialiQ")
  HAE_methods <- c("dt", "sl", "msl", "adams", "danish",
                   "hh", "dean", "imperiali")
  
  if (method %in% LRM_methods) {
    for (i in 1:length(region_list)) {
      temp_df <- x[, c(1, i+1)]
      multi_result[[i]] <- LRM(temp_df, seat[i], method, 
                               threshold, region = region_list[i])
    }
  } else if (method %in% HAE_methods) {
    for (i in 1:length(region_list)) {
      temp_df <- x[, c(1, i+1)]
      multi_result[[i]] <- HAE(temp_df, seat[i], method, 
                               threshold, region = region_list[i])
    }
  }
  
  multi_result <- bind_cols(data.frame(Party = x$Party),
                            bind_cols(multi_result))
  
  multi_result1 <- select(multi_result, Party, ends_with("Vote"))
  multi_result2 <- select(multi_result, Party, ends_with("Seat"))
  
  multi_result <- list(Vote = multi_result1, Seat = multi_result2)
  
  multi_result
}

LRM <- function(x, seat, method, threshold, region) {
  temp_x        <- x
  names(temp_x) <- c("Party", "Vote")
  
  result <- temp_x %>%
    mutate(
      Share = Vote / sum(Vote),
      Vote2 = ifelse(Share < threshold, NA, Vote),
      Total = sum(Vote2, na.rm = TRUE),
      Q     = case_when(method == "hare" ~ Total / seat,
                        method == "droop" ~ floor(1 + (Total / (1 + seat))),
                        method == "imperialiQ" ~ Total / (2 + seat)),
      Seat1 = floor(Vote2 / Q),
      Seat2 = 1 - ((Vote2 / Q) - floor(Vote2 / Q)),
      Seat3 = rank(Seat2),
      Seat4 = if_else(Seat3 <= (seat - sum(Seat1, na.rm = TRUE)), 1, 0),
      Seat  = Seat1 + Seat4
    ) %>%
    select(Vote, Seat) %>%
    mutate(Seat = ifelse(is.na(Seat), 0, Seat))
  
  names(result) <- c(paste0(region, ":Vote"),
                     paste0(region, ":Seat"))
  
  result
}

HAE <- function(x, seat, method, threshold, region) {
  
  hae_df <- x
  
  names(hae_df) <- c("Party", "Vote")
  
  hae_df <- hae_df %>%
    mutate(Share = Vote / sum(Vote),
           Vote  = ifelse(Share < threshold, 0, Vote))
  
  hae_df <- hae_df[rep(1:nrow(hae_df), seat), ]
  
  R_n <- 0:(seat - 1)
  
  if (method == "dt") {
    # D'Hondt method
    R_n_vec <- R_n + 1
  } else if (method == "sl") {
    # Sainte-Laguë method
    R_n_vec <- seq(1, by = 2, length.out = seat)
  } else if (method == "msl") {
    # Modified Sainte-Laguë method
    R_n_vec <- seq(1, by = 2, length.out = seat)
    R_n_vec[1] <- 1.4
  } else if (method == "adams") {
    # Adams's method
    R_n_vec <- R_n
  } else if (method == "danish") {
    # Danish method
    R_n_vec <- seq(1, 3 * seat, by = 3)
  } else if (method == "hh") {
    # Huntington–Hill method
    R_n_vec <- sqrt(R_n * (R_n + 1))
  } else if (method == "dean") {
    # Dean method
    R_n_vec <- (2 * R_n * (R_n + 1)) / (2 * R_n + 1)
  } else if (method == "imperiali") {
    # Imperiali
    R_n_vec <- seq(1, by = 0.5, length.out = seat)
  }
  
  seat_df <- hae_df %>% 
    mutate(R_n = rep(R_n_vec, each = nrow(x)),
           Q   = Vote / R_n) %>%
    arrange(desc(Q)) %>%
    head(n = seat) %>%
    group_by(Party) %>%
    summarise(Seat    = n(),
              .groups = "drop") %>%
    as.data.frame()
  
  hae_result <- left_join(x, seat_df, by = "Party") %>%
    select(-Party) %>%
    mutate(Seat = ifelse(is.na(Seat), 0, Seat))
  
  names(hae_result) <- c(paste0(region, ":Vote"),
                         paste0(region, ":Seat"))
  
  hae_result
}

plot.PRcalc <- function(obj){
  temp_fig <- bind_rows(obj[3:4], .id = "Type") %>%
    pivot_longer(cols = -c(Type, Party),
                 names_to = "Region",
                 values_to = "Prop") %>%
    mutate(Type = ifelse(Type == "VoteShare", "得票率", "議席率"),
           across(Type:Region, fct_inorder)) %>%
    ggplot() +
    geom_bar(aes(x = Party, y = Prop, fill = Type),
             stat = "identity", position = "dodge") +
    labs(x = "政党", y = "割合 (%)", fill = "") +
    ggtitle(paste("Method:", obj$Method)) +
    facet_wrap(~Region, ncol = 3) +
    theme(legend.position = "bottom")
    
    temp_fig
}
