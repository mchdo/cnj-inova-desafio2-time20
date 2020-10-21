suppressMessages(library(DBI))
suppressMessages(library(RSQLite))
suppressMessages(library(dplyr))
suppressMessages(library(dbplyr))
suppressMessages(library(glue))
suppressMessages(library(jsonlite))
suppressMessages(library(httr))
suppressMessages(library(stringr))

# Conexao no banco de serventia
if (!exists("connSGT") || !dbIsValid(connSGT)) {
  connSGT <- DBI::dbConnect(
    RSQLite::SQLite(),
    dbname = '../../../../dados/sgt_serventias.sqlite'
  )
}
DIR_ARQUIVOS_GEO <- "./dados_geo"

# Pesquisa atraves da API do Google a geolocalizacao da serventia
consulta_geo_api <- function (endereco_pesquisa,seq_orgao,seq_orgao_pai){
  print(glue("Pesquisando endereço: {endereco_pesquisa}"))
  chave_gmaps <- "INSERIR-A-CHAVE-AQUI"
  api_gmaps <- "https://maps.googleapis.com/maps/api/geocode/json" 
  r <- content(GET(api_gmaps, query = list(address=endereco_pesquisa, key=chave_gmaps)))
  ret <- ifelse(is.null(r$results),NULL,r$results)
  resultado_consulta <- list(seq_orgao=seq_orgao,seq_orgao_pai=seq_orgao_pai, geo_result=ret)
  jsonData <- toJSON(resultado_consulta, auto_unbox = TRUE, pretty = TRUE,  dataframe ="rows")
  arquivoSaida <- glue("./{DIR_ARQUIVOS_GEO}/{seq_orgao}.json")
  writeLines(jsonData,arquivoSaida , useBytes=T)
  return(ret)
  
}

serventias <- connSGT %>%  tbl('mpm_serventias')  %>%  
              select(SEQ_ORGAO,SEQ_ORGAO_PAI, NOMEDAVARA,DSC_CIDADE, SIG_UF, COD_IBGE, TIP_ESFERA_JUSTICA, endereco_serventia) %>% 
              arrange(as.numeric(SEQ_ORGAO)) %>%
              collect() %>%   
              rowwise %>%
              mutate(endereco_pesquisa = as.character(str_replace_all(glue("{NOMEDAVARA}, {endereco_serventia}, 
                                                                           {DSC_CIDADE}, {SIG_UF}"),"[.]","")))

mapply(consulta_geo_api, serventias$endereco_pesquisa,serventias$SEQ_ORGAO,serventias$SEQ_ORGAO_PAI)

# Recupera a lista de arquivos processados
lista_arquivos = list.files(path = DIR_ARQUIVOS_GEO, pattern='.json', recursive=TRUE, full.names = TRUE)
geo_serventias <-  data.frame(seq_orgao=character(),
                              seq_orgao_pai=character(), 
                              latitude=double(), 
                              longitude=double(),
                              placeId=character(),
                              stringsAsFactors=FALSE)

for(arquivo_entrada in lista_arquivos){
  # Abre o arquivo e insere as informacoes no dataframe
  dados <- jsonlite::fromJSON(arquivo_entrada, flatten = TRUE, simplifyDataFrame = TRUE)
  if(length(dados$geo_result)>0){
    geo_serventias <- geo_serventias %>% add_row(
      seq_orgao = dados$seq_orgao,
      seq_orgao_pai = dados$seq_orgao_pai,
      latitude = dados$geo_result$geometry.location.lat,
      longitude = dados$geo_result$geometry.location.lng,
      placeId = dados$geo_result$place_id
    )  
  }
  
}
# Grava a tabela de resultado
write.csv(geo_serventias,"../../../../dados/geo_serventias.csv")