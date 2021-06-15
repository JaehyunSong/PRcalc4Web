Input_Pane <- sidebarPanel(
  textInput('NewParty', '新しい政党を入力 (コンマ区切り)', 
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
  actionButton("Calculate", "計算")
)

Main_Pane <- mainPanel(
  h2("データ入力"),
  rHandsontableOutput("InputTable"),
  hr(),
  h2("要約"),
  p("Forthcoming"),
  p("(Effective Number of Parties, Gallagher Index, etc.)"),
  hr(),
  h2("配分結果 (得票数+議席数)"),
  tableOutput("Result"),
  hr(),
  h2("配分結果 (得票率+議席率)"),
  p("Forthcoming"),
  hr(),
  h2("図"),
  p("Plot Area (forthcoming)"),
  plotOutput("Plot"),
)

Help_Page <- tabPanel(
  "使い方",
  "作成中",
  hr(),
  "今後、",
  a(href = "https://github.com/JaehyunSong/PRcalc",
    "{PRcalc}"),
  "を大幅に修正する予定です。"
)

About_Author <- tabPanel(
  "作成者について", 
  tags$img(src = "Song.png", width = 250),
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