suppressMessages(library(jsonlite))
suppressMessages(library(glue))
suppressMessages(library(fs))
suppressMessages(library(stringi))
suppressMessages(library(elastic))
suppressMessages(library(DBI))
suppressMessages(library(RPostgreSQL ))
suppressMessages(library(validate ))
suppressMessages(library(dplyr ))
suppressMessages(library(pool))
suppressMessages(library(R.utils))
suppressMessages(library(tidyverse))
suppressMessages(library(caret))


apps <- new.env(parent = baseenv()) 
apps$dir_app <- getwd()
setwd("../../produto/engine/")
source("engine.R")
setwd(apps$dir_app)

DEV <- TRUE
if(DEV) {
	  # Conexao PostgreSQL
	  Sys.setenv(MARVINJUD_DB_HOST="localhost")
	  Sys.setenv(MARVINJUD_DB_PORT="5432")
	  Sys.setenv(MARVINJUD_DB_NAME="bd_marvinjud")
	  Sys.setenv(MARVINJUD_DB_USER="postgres")
	  Sys.setenv(MARVINJUD_DB_PASS="postgres")	  
	  
	  # Conexao elastic
	  Sys.setenv(MARVINJUD_ELK_ENDPOINT="localhost")	  
	  Sys.setenv(MARVINJUD_ELK_PATH="")
	  Sys.setenv(MARVINJUD_ELK_PORT="9200")
	  Sys.setenv(MARVINJUD_ELK_USER="elastic")
	  Sys.setenv(MARVINJUD_ELK_PASS="changeme")
	  Sys.setenv(MARVINJUD_ELK_TRANSPORT="http")  
	  
	  # Parametros de execucao do script
	  Sys.setenv(GERA_LOG_PROCESSAMENTO="TRUE")
	  Sys.setenv(GERA_DADOS_ANALITICOS="FALSE")
	  Sys.setenv(ENVIA_LOG_ELASTIC="TRUE")
	  # Diretorio onde devem ser descompactados os arquivos de dados do desafio. 
	  # Vai processar todos os arquivos JSON que estiver abaixo desse diretorio
	  Sys.setenv(DIR_ARQUIVOS_DADOS="F:/ProjetosPessoais/CNJ/base-teste/entrada/")
	  # Diretorio onde seram gravados os logs de processamento em formato JSON
	  Sys.setenv(DIR_LOGS="F:/ProjetosPessoais/CNJ/base-teste/saida/")
}

# Parametros de conexao ao PostgreSQL
db_host <- Sys.getenv("MARVINJUD_DB_HOST")
db_port <- Sys.getenv("MARVINJUD_DB_PORT")
db_name <- Sys.getenv("MARVINJUD_DB_NAME")
db_user <- Sys.getenv("MARVINJUD_DB_USER")
# Parametros de conexao ao Elastic
elk_endpoint  <- Sys.getenv("MARVINJUD_ELK_ENDPOINT")
elk_path      <- Sys.getenv("MARVINJUD_ELK_PATH")
elk_port      <- Sys.getenv("MARVINJUD_ELK_PORT")
elk_user      <- Sys.getenv("MARVINJUD_ELK_USER")
elk_pass      <- Sys.getenv("MARVINJUD_ELK_PASS")
elk_transport <- Sys.getenv("MARVINJUD_ELK_TRANSPORT")

# Cria a conexão com o Postgres
connDB <- dbPool(PostgreSQL(),
                     dbname = db_name, #nome do database a ser acessado
                     host = db_host, #IP do server que hospeda o database
                     port = db_port, #porta de entrada do server
                     user = db_user, #nome do usuário
                     password =  db_pass) # senha concedida ao usuário apontado acima

# Cria a conexao ao Elastic
connELK <- elastic::connect(host = elk_endpoint, path = elk_path, port = elk_port, transport_schema  = elk_transport)

# Formatacao do log de processamento
msg_processamento <- function(msg) {
  horario <- Sys.time()
  print(glue("[{horario}] {msg}"))
}

# Carrega as informacoes de serventias que serao utilizadas para a montagem do Painel de qualidade
# Le os arquivos com as coordenadas das serventias, extraidas a partir da API de GeoCoding do Google Maps
geo_serventias <- read_csv("../../dados/geo_serventias.csv",
                            col_types = cols(seq_orgao = col_character(),
                                             seq_orgao_pai=col_character(), 
                                            latitude=col_double(),
                                            longitude=col_double(),
                                            placeId=col_character(),
                                            .default = col_character()))

# Le as informacoes de serventias, fazendo join com as informacoes de localizacao
serventias  <- connSGT %>% tbl("mpm_serventias") %>% select (SEQ_ORGAO, SEQ_ORGAO_PAI,NOMEDAVARA, TIP_ESFERA_JUSTICA, DSC_CIDADE,SIG_UF )   %>% 
                      collect %>% left_join(geo_serventias,by=c("SEQ_ORGAO"="seq_orgao"))


# Processa os arquivos JSON  do desafio
processa_arquivos_desafio <- function() {
  DIR_ARQUIVOS_DADOS <- Sys.getenv("DIR_ARQUIVOS_DADOS")
  DIR_LOGS <- Sys.getenv("DIR_LOGS")
  GERA_LOG_PROCESSAMENTO <- Sys.getenv("GERA_LOG_PROCESSAMENTO")
  GERA_DADOS_ANALITICOS <- Sys.getenv("GERA_DADOS_ANALITICOS")
  ENVIA_LOG_ELASTIC <- Sys.getenv("ENVIA_LOG_ELASTIC")
  
  lista_arquivos = list.files(path = glue("{DIR_ARQUIVOS_DADOS}"), pattern='.json', recursive=TRUE, full.names = TRUE)
  
  for(arquivo_entrada in lista_arquivos){
    msg_processamento(glue("Processando arquivo {arquivo_entrada}"))
    dados <- jsonlite::fromJSON(arquivo_entrada, flatten = TRUE, simplifyDataFrame = TRUE) 
    qtd_proc <- nrow(dados)
    msg_processamento(glue("Processos encontrados {qtd_proc}"))
    erros <- engine.processa_validacao(dados,"")
    
    if(tolower(GERA_LOG_PROCESSAMENTO)!="false"){
      nome_arquivo <- tools::file_path_sans_ext(path_file(arquivo_entrada))
      arquivo_log = glue("{DIR_LOGS}/{nome_arquivo}.log.json")
      msg_processamento(glue("Gravando o log do processamento em  {arquivo_log}"))
      gera_logs_json(erros,arquivo_log) 
    }
    
    if(tolower(GERA_DADOS_ANALITICOS)!="false"){
      msg_processamento(glue("Gerando os dados analiticos para o processamento"))
      gera_dados_analitico(dados,erros)
    }
    
    if(tolower(ENVIA_LOG_ELASTIC)!="false"){
      msg_processamento(glue("Enviando o processamento para o elastic"))
      envia_log_elastic(erros)
    }
    
    msg_processamento(glue("Terminou o processamento do arquivo {arquivo_entrada}"))
  }
  
  # Atualiza as views materalizadas utilizadas pelo Dashboard
  if(tolower(GERA_DADOS_ANALITICOS)!="false"){
    dbExecute(conn = connDB, statement = "REFRESH MATERIALIZED VIEW public.vwm_validacao_ano");
    dbExecute(conn = connDB, statement = "REFRESH MATERIALIZED VIEW public.vwm_validacao_orgao");
    # Fecha a conexao com o banco
    poolClose(connDB);
  }
  
}


# Envia  todos os registros de processamento para o Elastic
envia_log_elastic <- function(dados, erros){
  docs_bulk(connELK, erros, index="validacoesMarvinJud")
}

# Grava os logs de processamento em arquivos JSON
gera_logs_json <- function(registro_erros, nome_arquivo) {
  jsonData <- toJSON(registro_erros, auto_unbox = TRUE, pretty = TRUE,  dataframe ="rows")
  writeLines(jsonData, nome_arquivo, useBytes=T)
  
}

# Gera os dados analiticos que serao lidos pelo Dashboad "Painel de Qualidade dos Dados"
gera_dados_analitico <- function(dados, erros){
  # Pega os dados do processo
  #browser()
  resumo_processo <- dados %>%  select( millisInsercao,
           dadosBasicos.numero,
           siglaTribunal,
           grau,
           contains("dadosBasicos.procEl"),
           contains("dadosBasicos.dscSistema"),
           contains("dadosBasicos.orgaoJulgador.nomeOrgao"),
           contains("dadosBasicos.orgaoJulgador.codigoMunicipioIBGE"),
           contains("dadosBasicos.orgaoJulgador.codigoOrgao"),
           contains("dadosBasicos.classeProcessual"),
           contains("movimento"),
           contains("dadosBasicos.assunto"),
           contains("polo")) %>%
    group_by(dadosBasicos.numero) %>%
    mutate(anoProcesso= substr(dadosBasicos.numero,10,13))  %>%
    mutate(qtdMovimentos = ifelse("movimento" %in% colnames(.), map_dbl(movimento, length),0)) %>%
    mutate(qtdAssuntos = ifelse("dadosBasicos.assunto" %in% colnames(.),map_dbl(dadosBasicos.assunto, length),0))%>%
    mutate(qtdPolos = ifelse("polo" %in% colnames(.),map_dbl(polo, length),0 ))
    
    # Computa as estatistica de processamento (Esta considerando as informacoes de polo que nao estao presentes nos arquivos do desafio, mas sao obrigatorias,
    # gerando sempre ao menos 1 falha para cada registros)
    qtdRegras <- ifelse(is.null(nrow(erros$processo.resumo)),0,nrow(erros$processo.resumo)) + ifelse(is.null(nrow(erros$movimento.resumo)),0,nrow(erros$movimento.resumo)) + ifelse(is.null(nrow(erros$assunto.resumo)),0,nrow(erros$assunto.resumo))  + ifelse(is.null(nrow(erros$polo.resumo)),0,nrow(erros$polo.resumo))
    
    dfRegrasFalhaEscopoProcesso       <- erros$processo.erros %>% select(millisInsercao, dadosBasicos.numero, siglaTribunal, nomeRegra) %>%  group_by(millisInsercao, dadosBasicos.numero, siglaTribunal)  %>%  summarise(qtdRegrasFalhaEscopoProcesso = n_distinct(nomeRegra))
    dfRegrasFalhaEscopoMovimento      <- erros$movimento.erros %>% select(millisInsercao, dadosBasicos.numero, siglaTribunal,nomeRegra) %>%  group_by(millisInsercao, dadosBasicos.numero, siglaTribunal)  %>%  summarise(qtdRegrasFalhaEscopoMovimento = n_distinct(nomeRegra))
    dfRegrasFalhaEscopoAssunto        <- erros$assunto.erros %>% select(millisInsercao, dadosBasicos.numero, siglaTribunal,nomeRegra) %>%  group_by(millisInsercao, dadosBasicos.numero, siglaTribunal)  %>%  summarise(qtdRegrasFalhaEscopoAssunto = n_distinct(nomeRegra))
    dfRegrasFalhaEscopoPolo           <- erros$polo.erros %>% select(millisInsercao, dadosBasicos.numero, siglaTribunal,nomeRegra) %>%  group_by(millisInsercao, dadosBasicos.numero, siglaTribunal)  %>%  summarise(qtdRegrasFalhaEscopoPolo = n_distinct(nomeRegra))
    dfMovimentosFalhaEscopoMovimento  <- erros$movimento.erros %>% select(millisInsercao, dadosBasicos.numero, siglaTribunal) %>%  group_by(millisInsercao, dadosBasicos.numero, siglaTribunal)  %>%  summarise(qtdMovimentosFalha = n())
    dfAssuntoFalhaEscopoAssunto       <- erros$assunto.erros %>% select(millisInsercao, dadosBasicos.numero, siglaTribunal) %>%  group_by(millisInsercao, dadosBasicos.numero, siglaTribunal)  %>%  summarise(qtdAssuntosFalha = n())
    dfAssuntoFalhaEscopoPolo          <- erros$polo.erros %>% select(millisInsercao, dadosBasicos.numero, siglaTribunal) %>%  group_by(millisInsercao, dadosBasicos.numero, siglaTribunal)  %>%  summarise(qtdPolosFalha = n())
    
    # Converte todos o codigos do orgao para string
    resumo_processo <- resumo_processo %>% mutate(dadosBasicos.orgaoJulgador.codigoOrgao=as.character(dadosBasicos.orgaoJulgador.codigoOrgao))
    
    # Join com as informacoes geograficas dos orgaos julgadores
    resumo_processo <- resumo_processo  %>% left_join(serventias,by=c("dadosBasicos.orgaoJulgador.codigoOrgao"="SEQ_ORGAO"))
    
    # Join com as estaticas
    resumo_processo <- resumo_processo  %>% left_join(dfRegrasFalhaEscopoProcesso)
    resumo_processo <- resumo_processo  %>% left_join(dfRegrasFalhaEscopoMovimento)
    resumo_processo <- resumo_processo  %>% left_join(dfRegrasFalhaEscopoAssunto)
    resumo_processo <- resumo_processo  %>% left_join(dfRegrasFalhaEscopoPolo)
    resumo_processo <- resumo_processo  %>% left_join(dfMovimentosFalhaEscopoMovimento)
    resumo_processo <- resumo_processo  %>% left_join(dfAssuntoFalhaEscopoAssunto)
    resumo_processo <- resumo_processo  %>% left_join(dfAssuntoFalhaEscopoPolo)
    
    # Adiciona a coluna de quantidade de regras e quantidade de regras que falharam
    resumo_processo <- resumo_processo  %>%  mutate(qtdRegras=qtdRegras)
    resumo_processo$qtdRegrasFalha <- rowSums(resumo_processo[,c("qtdRegrasFalhaEscopoProcesso","qtdRegrasFalhaEscopoMovimento","qtdRegrasFalhaEscopoAssunto", "qtdRegrasFalhaEscopoPolo")], na.rm=TRUE) 

    # Ajustes nos nomes e informações de algumas colunas
    dados_analitico <-  resumo_processo %>% mutate(geoUF=SIG_UF) %>% 
                                            mutate(geoNomeMunicipio=DSC_CIDADE)%>% 
                                            mutate(geoLatitudeOrgao=latitude) %>% 
                                            mutate(geoLongitudeOrgao=longitude) %>% 
                                            mutate(esferaJustica = case_when(TIP_ESFERA_JUSTICA == "E" ~ "Justiça Estadual",
                                                                             TIP_ESFERA_JUSTICA == "F" ~ "Justiça Federal",
                                                                             TIP_ESFERA_JUSTICA == "L" ~ "Justiça Eleitoral",
                                                                             TIP_ESFERA_JUSTICA == "M" ~ "Justiça Militar",
                                                                             TIP_ESFERA_JUSTICA == "S" ~ "Tribunais Superiores",
                                                                             TIP_ESFERA_JUSTICA == "T" ~ "Justiça do Trabalho"))
    # Prepara os dados para gravacao no banco
    dados_analitico <-  dados_analitico %>% select(millisInsercao,
                                                  dadosBasicos.numero,
                                                  siglaTribunal,
                                                  grau,
                                                  anoProcesso,
                                                  contains("dadosBasicos.orgaoJulgador.nomeOrgao"),
                                                  contains("dadosBasicos.orgaoJulgador.codigoOrgao"),
                                                  contains("dadosBasicos.classeProcessual"),
                                                  qtdRegras,
                                                  qtdRegrasFalha,
                                                  qtdMovimentos,
                                                  qtdMovimentosFalha,
                                                  qtdAssuntos,
                                                  qtdAssuntosFalha,
                                                  geoUF,
                                                  geoNomeMunicipio,
                                                  geoLatitudeOrgao,
                                                  geoLongitudeOrgao,
                                                  esferaJustica
                                                  ) 
    # Remove todos os acentos e deixa apenas os caracteres ASCII (Para evitar problemas com encoding)    
    # TODO Produção: Verificar as configuraçoes de R/SO/PostgreSQL que geram as diferenças de encoding
    dados_analitico <- dados_analitico %>% mutate_all(funs(stri_trans_general(.,"Latin-ASCII"))) %>% mutate_all(funs(gsub('[^\x01-\xFF]+',"",.)))
    
    # Persiste as informacoes no banco
    dbWriteTable(connDB, "registro_validacao", dados_analitico, row.names=FALSE, append=TRUE)
    
}

processa_arquivos_desafio()