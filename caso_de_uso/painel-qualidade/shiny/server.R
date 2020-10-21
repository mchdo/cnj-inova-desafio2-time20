library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)
library(plotly)
library(DT)


function(input, output, session) {
  
  onStop(function() {
    poolClose(connDB)
  })
  
  # Dataframes para composição dos relatórios
  RV <- reactiveValues(
    validacaoPorAno = vwValidacaoAno,
    validacaoPorOrgao = vwValidacaoOrgao
  )
  
  # Criação do mapa
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles(
        urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        attribution = 'Mapas por <a href="https://www.openstreetmap.org/">OpenStretmap</a>'
        ) %>%
      setView(lng = -47.92, lat = -15.77, zoom = 5)
  })
  
  # Uma expressão reativa que retorna os registros dos municípios que estão em tela
  procInBounds <- reactive({
    
    if (is.null(input$map_bounds))
      return(RV$validacaoPorOrgao[FALSE,])
    bounds <- input$map_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)
    
    subset(RV$validacaoPorOrgao,
           geoLatitudeOrgao >= latRng[1] & geoLatitudeOrgao <= latRng[2] &
             geoLongitudeOrgao >= lngRng[1] & geoLongitudeOrgao <= lngRng[2])
  })
  
  # Calcula o histograma
    output$histCentile <- renderPlot({
    # Se o código IBGE não aparece na visualização, não plota 
    if (nrow(procInBounds()) == 0)
      return(NULL)
    
    hist(procInBounds()$taxaConformidade, 
         breaks = 10, 
         main = "Taxa de conformidade",
         ylab = "Frequência",
         xlab = "Percentual de Conformidade",
         xlim = range(0,1), 
         col = '#00DD00',
         border = 'white')
  })
  
  # Calcula o gráfico de distribuição
  output$scatterplot <- renderPlot({
    if (nrow(procInBounds()) == 0)
      return(NULL)
    
    print(xyplot(taxaConformidade ~ qtdRegrasFalha, data = procInBounds(), 
                 xlim = range(RV$validacaoPorOrgao$qtdRegrasFalha), 
                 ylim = range(0,1),          
                 ylab = "Taxa de Conformidade",
                 xlab = "Regras não atendidas"))
  })

  # Responsável por manter os císculos e as legendas
  # De acordo com as variáveis que o usuário pode selecionar pela cor e tamanho
  observe({
    colorBy <- input$color
    sizeBy <- input$size

    colorData <- RV$validacaoPorOrgao[[colorBy]]
    pal <- colorBin("viridis", colorData, 7, pretty = FALSE)

    if (sizeBy == "taxaConformidade") {
      # altera a configuração do raio de acordo com o item selecionado
      radius <- RV$validacaoPorOrgao[[sizeBy]] / max(RV$validacaoPorOrgao[[sizeBy]]) * 30000
    } else {
      radius <- RV$validacaoPorOrgao[[sizeBy]] * 50
    }
  
  # Adiciona os raios na tela disponível
    leafletProxy("map", data = RV$validacaoPorOrgao) %>%
      clearShapes() %>%
      addCircles(~geoLongitudeOrgao, ~geoLatitudeOrgao, radius=radius, layerId=~geoNomeMunicipio,
                 stroke=FALSE, fillOpacity=0.4, fillColor=pal(colorData)) %>%
      addLegend("bottomleft", pal=pal, values=colorData, title=colorBy,
                layerId="colorLegend")
  })
  
  ## Indicadores ###########################################
  
  output$totalProcessos <- renderValueBox({
    valueBox(paste0(format(sum(RV$validacaoPorOrgao$qtdProcessos, na.rm=TRUE),  big.mark=".", decimal.mark=",")),
             "Quantidade de Processos", icon = icon("book"), color = "olive")
    })
    
  output$taxaConformidade <- renderValueBox({
    valueBox(paste0(100 * round(mean(RV$validacaoPorOrgao$taxaConformidade, na.rm=TRUE),2), " %"),
             "Taxa de Conformidade das Regras", icon = icon("tasks"),  color = "red")
    })
    
  output$taxaConformidadeMovimentos <- renderValueBox({
    valueBox(format(sum(RV$validacaoPorOrgao$qtdRegrasFalha, na.rm=TRUE),  big.mark=".", decimal.mark=","),
             "Regras não atendidas",  icon = icon("folder-open"), color = "yellow")
  })
    
  output$ErrosPlot <- renderPlotly({
    df <- RV$validacaoPorAno %>% 
      group_by("Ano" = anoProcesso) %>% 
      summarise(sumProcessos = sum(qtdProcessos),
                sumRegrasFalha = sum(qtdRegrasFalha),
                sumMovimentos = sum(qtdMovimentos))
    
    fig <- plot_ly() %>% 
      add_lines(x = df$Ano, y = df$sumProcessos,  color = I("black"), name = "Quantidade de processos")%>% 
      add_lines(x = df$Ano, y = df$sumRegrasFalha,  color = I("blue"), name = "Quantidade de Regras não atendidas") %>% 
      add_lines(x = df$Ano, y = df$sumMovimentos,  color = I("red"), name = "Quantidade de Movimentos") %>% 
      layout(xaxis = list(list(autorange = df$Ano)))
    fig
  })
  
  output$tabelaQtdProcessosPorAno  = DT::renderDataTable({
    df <- RV$validacaoPorAno %>% group_by(anoProcesso) %>% summarise("Quantidade de processos" = sum(qtdProcessos),
                                                                     'Taxa de conformidade' = mean(taxaConformidade, na.rm=TRUE),
                                                                     "Regras não atendidas" = sum(qtdRegrasFalha, na.rm=TRUE),
                                                                     "Quantidade de Movimentos" = sum(qtdMovimentos, na.rm=TRUE),
                                                                     "Quantidade de Assuntos" = sum(qtdAssuntos, na.rm=TRUE)
                                                               )
    DT::datatable(df, rownames = FALSE, options = list(language = list(url = 'Portuguese-Brasil.json'), 
                                                       order = list(list(2, 'desc')), 
                                                       pageLength = 5)) %>% 
      formatPercentage(columns = c("Taxa de conformidade"))
  })
  
  ## Ranking de conformidade ###########################################

    output$tabela = DT::renderDataTable({
    df <- RV$validacaoPorOrgao %>% select("Estado" = geoUF, 
                                          "Justiça" = esferaJustica,
                                          "Tribunal" = siglaTribunal, 
                                          "Órgão Julgador" = dadosBasicos.orgaoJulgador.nomeOrgao, 
                                          "Município" = geoNomeMunicipio,
                                          "Quantidade de processos" = qtdProcessos,
                                          "Taxa de conformidade" = taxaConformidade, 
                                          "Regras não atendidas" = qtdRegrasFalha, 
                                          "Movimentos não conformes" = qtdMovimentosFalha, 
                                          "Assuntos não conformes" = qtdAssuntosFalha)
    
    DT::datatable(df, rownames = FALSE, 
                  options = list(language = list(url = 'Portuguese-Brasil.json'), 
                                                       order = list(list(6, 'desc')))) %>% 
      formatPercentage(columns = 'Taxa de conformidade')
  })
  
  ### Funções de validação  ##########################
  
  # Seleciona os Municípios dos estados
  observe({
    mun_detal <- if (is.null(input$uf_detal)) character(0) else {
      filter(vwValidacaoOrgao, geoUF %in% input$uf_detal) %>%
        `$`('geoNomeMunicipio') %>%
        unique() %>%
        sort()
    }
    stillSelected <- isolate(input$mun_detal[input$mun_detal %in% mun_detal])
    updateSelectizeInput(session, "mun_detal", choices = mun_detal,
                         selected = stillSelected, server = TRUE)
  })
  
  # Configuração da funcionalidade do botão consultar
  observeEvent(input$btnConsultar, {
    vwValidacaoOrgao <- vwValidacaoOrgao %>% filter(
      is.null(input$esferajus_detal) | esferaJustica %in% input$esferajus_detal,
      is.null(input$uf_detal) | geoUF %in% input$uf_detal,
      is.null(input$mun_detal) | geoNomeMunicipio %in% input$mun_detal)
    
    vwValidacaoAno <- vwValidacaoAno %>% filter(
      is.null(input$esferajus_detal) | esferaJustica %in% input$esferajus_detal,
      is.null(input$uf_detal) | geoUF %in% input$uf_detal,
      is.null(input$mun_detal) | geoNomeMunicipio %in% input$mun_detal) 
    
    RV$validacaoPorOrgao <- vwValidacaoOrgao
    RV$validacaoPorAno <- vwValidacaoAno
    
  })
  
}