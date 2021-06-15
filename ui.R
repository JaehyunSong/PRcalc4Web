library(rhandsontable)
library(PRcalc) # remotes::install_github("JaehyunSong/PRcalc")
library(shinythemes)

navbarPage("PRcalc for Web", 
           selected = "比例代表配分計算", 
           collapsible = TRUE, 
           inverse = TRUE, 
           theme = shinytheme("spacelab"),
           
           tabPanel("比例代表配分計算",
                    fluidPage(
                      sidebarLayout(
                        sidebarPanel(textInput('NewParty', '新しい政党を入力 (コンマ区切り)', 
                                               "政党A, 政党B, 政党C"),
                                     textInput('NewRegion', '新しい地域を入力 (コンマ区切り)', 
                                               "地域1, 地域2"),
                                     actionButton("Add_Table", "入力欄生成"),
                                     sliderInput("Threshold", "閾値 (0〜1)",
                                                 value = 0, min = 0, max = 1,
                                                 step = 0.01),
                                     selectInput("method", 
                                                 "議席配分方式", 
                                                 list(
                                                   "最高平均法" = c(
                                                     "d’Hondt" = "dt",
                                                     "Sainte-Laguë" = "sl",
                                                     "Modified Sainte-Laguë" = "msl", 
                                                     "Danish" = "denmark",
                                                     "Imperiali" = "imperiali", 
                                                     "Huntington-Hill" = "hh"
                                                   ),
                                                   "最大余剰法" = c(
                                                     "Hare"  = "hare",
                                                     "Droop" = "droop",
                                                     "Imperiali Quota" = "imperialiQ"
                                                   )
                                                 )
                                     ),
                                     actionButton("Calculate", "計算")),
                        mainPanel(
                          h2("データ入力"),
                          rHandsontableOutput("InputTable"),
                          hr(),
                          h2("配分結果"),
                          tableOutput("Result"),
                          hr(),
                          h2("図"),
                          tableOutput("msg"),
                        )
                      ))),
                    
           tabPanel(
             "使い方",
             "作成中",
             hr(),
             "今後、{PRcalc}を大幅に修正する予定です。"
             ),
           tabPanel(
             "著者について", 
             h3("Jaehyun Song, Ph.D."),
             tags$ul(
               tags$li(tags$b("Affiliation: "), "Faculty of Informatics, Kansai University, Japan"), 
               tags$li(tags$b("Position: "), "Associate Professor")),
             hr(),
             h3("Contact Information"),
             tags$ul(
               tags$li(tags$b("Homepage: "),a(href = "https://www.jaysong.net",
                                              "https://www.jaysong.net")), 
               tags$li(tags$b("E-mail: "), a(href = "mailto:song@kansai-u.ac.jp",
                                             "song@kansai-u.ac.jp")), 
               tags$li(tags$b("Github: "), a(href = "https://github.com/JaehyunSong",
                                             "https://github.com/JaehyunSong"))
             )
           )
)
