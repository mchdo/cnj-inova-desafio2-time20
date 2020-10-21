library(shinythemes)
ui <- fluidPage(theme = shinytheme("flatly"),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "https://fonts.googleapis.com/css?family=Ubuntu:regular,bold&subset=Latin"),
    
  ),
  tags$img(
    src = "img/fundo_cnj.jpg",
    style = 'position: absolute;  opacity: 0.05;width:100%;height:100%;'
  ),
  shinyFeedback::useShinyFeedback(),
  shinyjs::useShinyjs(),
  # Application Title
  titlePanel(
    title=div(style="border-bottom: solid 1px silver; overflow: hidden;", img(style="float: left", src='img/c.png',height="72px"),
    h1("Gestão das regras de qualidade dos dados", align = 'center'))
    
  ),
  regras_table_module_ui("regras_table")
)