library(shiny)
library(PRcalc) # remotes::install_github("JaehyunSong/PRcalc")
library(tidyverse)
library(rhandsontable)
source("components.R")

# 日本語表示用（ローカルでテスト時はコメントアウト）
# 起動のたびにフォントダウンロードを行うため、初期起動が重い
# https://github.com/ltl-manabi/shinyapps.io_japanese_font
download.file("https://raw.githubusercontent.com/ltl-manabi/shinyapps.io_japanese_font/master/use_ipaex_font.sh", destfile = "use_ipaex_font.sh")
system("bash ./use_ipaex_font.sh")

navbarPage(
  "PRcalc for Web", 
  selected = "比例代表配分計算", 
  collapsible = TRUE, 
  inverse = TRUE, 
  theme = shinythemes::shinytheme("cosmo"),
  
  # メインページ
  tabPanel("比例代表配分計算", 
           fluidPage(sidebarLayout(Input_Pane, Main_Pane))),
  Help_Page,   # 使い方
  About_Author # 作成者について
)