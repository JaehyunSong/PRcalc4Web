Input_Pane <- sidebarPanel(
  textInput('NewParty', '新しい政党を入力 (コンマ区切り)', 
            "政党A, 政党B, 政党C"),
  textInput('NewRegion', '新しい地域を入力 (コンマ区切り)', 
            "地域1, 地域2"),
  actionButton("Add_Table", "入力欄生成"),
  selectInput("Sample", 
              "サンプル・データ", 
              list(
                "日本" = c(
                  "参院選 (2019)" = "Japan_Upper_2019",
                  "衆院選 (2017)" = "Japan_Lower_2017",
                  "衆院選 (2014)" = "Japan_Lower_2014",
                  "衆院選 (2012)" = "Japan_Lower_2012",
                  "衆院選 (2009)" = "Japan_Lower_2009"
                ),
                "韓国" = c(
                  "総選挙 (2016)" = "Korea_Lower_2016",
                  "総選挙 (2012)" = "Korea_Lower_2012",
                  "総選挙 (2008)" = "Korea_Lower_2008",
                  "総選挙 (2004)" = "Korea_Lower_2004"
                ),
                "国勢調査" = c(
                  "日本 (2015)" = "Japan_Census_2015",
                  "日本 (1970)" = "Japan_Census_1970",
                  "日本 (1945)" = "Japan_Census_1945",
                  "日本 (1920)" = "Japan_Census_1920",
                  "アメリカ (2020)" = "US_Census_2020"
                )
              )
  ),
  actionButton("Load_Sample", "サンプル・データ読み込み"),
  sliderInput("Threshold", "閾値 (0〜1)",
              value = 0, min = 0, max = 1,
              step = 0.01),
  selectInput("method", 
              "議席配分方式", 
              list(
                "最高平均法" = c(
                  "D’Hondt (Jefferson)" = "dt",
                  "Sainte-Laguë (Webster)" = "sl",
                  "Modified Sainte-Laguë" = "msl", 
                  "Danish" = "danish",
                  "Imperiali" = "imperiali", 
                  "Huntington-Hill" = "hh",
                  "Dean" = "dean",
                  "Adams's" = "adams"
                ),
                "最大余剰法" = c(
                  "Hare–Niemeyer"  = "hare",
                  "Droop" = "droop",
                  "Imperiali Quota" = "imperialiQ"
                )
              )
  ),
  actionButton("Calculate", "計算/再計算")
)

Main_Pane <- mainPanel(
  h2("データ入力"),
  rHandsontableOutput("InputTable"),
  hr(),
  h2("配分結果 (得票数+議席数)"),
  tableOutput("Result1"),
  hr(),
  h2("配分結果 (得票率+議席率)"),
  tableOutput("Result2"),
  hr(),
  h2("非比例性指標など"),
  tableOutput("Summary"),
  hr(),
  h2("図"),
  plotlyOutput("Plot")
)

Help_Page <- tabPanel(
  "使い方",
  h2("PRcalc for Webの使い方"),
  tags$ol(
    tags$li(tags$b("Step1: "), "政党名を入力します。"),
    tags$ul(tags$li("複数の政党を入力する場合、政党名をコンマ（「、」 or 「,」）で区切ってください。")),
    tags$li(tags$b("Step2: "), "地域名を入力します。"),
    tags$ul(
      tags$li("単一ブロックの場合でも地域名を入力してください（「全国」など）。"),
      tags$li("複数の地域を入力する場合、地域名をコンマ（「、」 or 「,」）で区切ってください。")),
    tags$li(tags$b("Step3: "), "「入力欄生成」ボタンをクリックします。"),
    tags$li(tags$b("Step4: "), "各政党の得票数を入力します。最上行は比例区の定数を入力します。"),
    tags$ul(
      tags$li("Excelなどから直接貼り付けることも可能です。"),
      tags$li("Step1~3の過程を省略し、サンプル・データの読み込みも可能です。読み込み後、データの修正も可能です。")
    ),
    tags$li(tags$b("Step5: "), "阻止条項の閾値と議席期配分方式を選択します。"),
    tags$li(tags$b("Step6: "), "「計算/再計算」ボタンをクリックします。"),
    tags$li(tags$b("Step7: "), "データ修正、閾値の修正、議席配分方式を変更した場合、改めて「計算/再計算」ボタンをクリックしてください。")
  ),
  hr(),
  h2("サンプルデータを使う際の注意点"),
  tags$ul(
    tags$li("日本"),
    tags$ul(
      tags$li("参院選 (2019): 得票数が小数点の場合、四捨五入しました。"),
      tags$li("衆院選 (2017): 実際の選挙結果と合わないブロック（東海）があります。これは立憲民主党の配分議席数より名簿上の候補者が少なかったため、自民党に議席が回ったからです。")
    ),
    tags$li("韓国"),
    tags$ul(
      tags$li("総選挙 (2016): 泡沫政党が多いため、得票率10万未満は除外しております（阻止条項: 3%）。")
    ),
    tags$li("国勢調査"),
    tags$ul(
      tags$li("アメリカ (2020): 50州のみ（ワシントンDC、プエルトリコなどは除外）")
    )
  ),
  hr(),
  h2("各種指標について"),
  tags$ul(
    tags$li(tags$b("有効政党数: "), 'Laakso, Markku and Rein Taagepera (1979). ""Effective" Number of Parties: A Measure with Application to West Europe". Comparative Political Studies. 12 (1): 3–27.'),
    tags$li(tags$b("非比例性指数: "), 'Gallagher, Michael (1991). "Proportionality, Disproportionality and Electoral Systems". Electoral Studies. 10: 33–51.'),
  ),
  hr(),
  h2("今後の予定"),
  tags$ul(
    tags$li("サンプル・データの追加"),
    tags$li("{ggplot2}から{plotly}へ移行"),
    tags$li("レイアウトの変更"),
    tags$li("その他")
  )
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