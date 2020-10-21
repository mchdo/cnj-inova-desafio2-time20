library(leaflet)
library(shiny)
library(shinydashboard)
library(shinybusy)
library(shinythemes)
library(plotly)


# variáveis para o drop-down
vars <- c(
  "Taxa de conformidade" = "taxaConformidade",
  "Regras não atendidas" = "qtdRegrasFalha",
  "Movimentos não conformes" = "qtdMovimentosFalha",
  "Assuntos não conformes" = "qtdAssuntosFalha")

vars_esfera <- c("Todas"="",
                 "Justiça Estadual" = "Justica Estadual", 
                 "Justiça Federal" = "Justica Federal",
                 "Justiça Militar" = "Justica Militar",
                 "Justiça Eleitoral" = "Justica Eleitoral", 
                 "Justiça do Trabalho" = "Justica do Trabalho",
                 "Tribunais Superiores" = "Tribunais Superiores")

vars_grau <- c("Todos"="","CJF","CSJT","G1","G2","JE","SUP","TEU","TNU","TR","TRU")

vars_est <- c("Todos"="","Acre" = "AC","Alagoas" = "AL","Amapá" = "AP","Amazonas" = "AM","Bahia" = "BA","Ceará" = "CE",
              "Distrito Federal" = "DF","Espírito Santo" = "ES","Goiás" = "GO","Maranhão" = "MA","Mato Grosso" = "MT",
              "Mato Grosso do Sul" = "MS","Minas Gerais" = "MG","Pará" = "PA","Paraíba" = "PB","Paraná" = "PR","Pernambuco" = "PE",
              "Piauí" = "PI","Rio de Janeiro" = "RJ","Rio Grande do Norte" = "RN","Rio Grande do Sul" = "RS",
              "Rondônia" = "RO","Roraima" = "RR","Santa Catarina" = "SC","São Paulo" = "SP","Sergipe" = "SE","Tocantins" = "TO")

# Layout da app
fluidPage(theme = shinytheme("flatly"),
          tags$head(
            includeCSS("styles.css"),
            includeScript("gomap.js")
          ),
          includeCSS(path = "AdminLTE.min.css"),
          includeCSS(path = "shinydashboard.css"),
          
          sidebarLayout(
            sidebarPanel(width=2,  height="100%",
                         img(style="float: left", src='img/c.png',height="72px"),
                         div(style="padding-top: 100px;min-height:500px;",
                             selectInput("esferajus_detal", "Justiça", choices = vars_esfera, multiple=TRUE),
                             selectInput("uf_detal", "Unidade da federação",choices = vars_est , multiple=TRUE),
                             conditionalPanel("input.uf_detal",
                                              selectInput("mun_detal", "Município sede",choices = c("Todos"="") , multiple=TRUE)
                                              
                             ),
                             actionButton("btnConsultar", label = "Consultar..", icon = icon("search")),

                             br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br(),br()
                         )
            ),
            
            mainPanel( width=10,navbarPage("Painel da qualidade dos dados", id="nav",
                                           tabPanel("Mapa Interativo",
                                                    div(class="outer",
                                                        leafletOutput("map", width="100%", height="100%"),
                                                        ),
                                                    absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                                                  draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                                                                  width = 330, height = "auto",
                                                                  
                                                                  h3("Configurações"),
                                                                  selectInput("color", "Cor", vars), 
                                                                  selectInput("size", "Tamanho", vars, selected = "TaxaConformidade"),
                                                                  hr(),
                                                                  plotOutput("histCentile", height = 200),
                                                                  plotOutput("scatterplot", height = 250)
                                                                  )
                                                    ),
                                           
                                           tabPanel("Indicadores", 
                                                    mainPanel(
                                                      valueBoxOutput("totalProcessos", width = 4),
                                                      valueBoxOutput("taxaConformidade", width = 4),
                                                      valueBoxOutput("taxaConformidadeMovimentos", width = 4),
                                                      hr(),hr(),hr(),hr(),hr(),hr(),
                                                      plotlyOutput("ErrosPlot"),
                                                      DT::dataTableOutput("tabelaQtdProcessosPorAno")
                                                      )                                             
                                                    ),
                                           
                                           tabPanel("Ranking de conformidade",
                                                    mainPanel(
                                                      h3("Indicadores de conformidade por orgão julgador"),
                                                      hr(),
                                                      DT::dataTableOutput("tabela")
                                                      )
                                                    ),
                                           conditionalPanel("false", icon("crosshair"))
                                           )
                       )
            )
          )