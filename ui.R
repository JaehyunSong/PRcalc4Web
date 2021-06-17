library(shiny)
library(tidyverse)
library(rhandsontable)
library(knitr)
library(kableExtra)
library(plotly)
library(shiny.i18n)
source("components.R")
source("Calculator.R")

# 日本語表示用（ローカルでテスト時はコメントアウト）
# 起動のたびにフォントダウンロードを行うため、初期起動が重い
# https://github.com/ltl-manabi/shinyapps.io_japanese_font
#download.file("https://raw.githubusercontent.com/ltl-manabi/shinyapps.io_japanese_font/master/use_ipaex_font.sh", destfile = "use_ipaex_font.sh")
#system("bash ./use_ipaex_font.sh")

i18n <- Translator$new(translation_json_path = "translations/translations.json")
i18n$set_translation_language('ja')

navbarPage(
  "PRcalc for Web", 
  selected = "FirstPage", 
  collapsible = TRUE, 
  inverse = TRUE, 
  theme = shinythemes::shinytheme("cosmo"),
  
  tags$div(style='float: right;',
  shiny.i18n::usei18n(i18n),
  selectInput(
    inputId  = "selected_language",
    label    = "Language",
    choices  = c("日本語 (Japanese)" = "ja",
                 "한국어 (Korean)"   = "ko",
                 "English"           = "en"),
    selected = "ja"
  )),
  
  # メインページ
  tabPanel(i18n$t("比例代表配分計算"), value = "FirstPage",
           fluidPage(sidebarLayout(Input_Pane, Main_Pane))),
  Help_Page,   # 使い方
  About_Author # 作成者について
)