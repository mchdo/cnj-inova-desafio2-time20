library(shiny)
library(DT)
library(DBI)
library(shinyjs)
library(shinycssloaders)
library(lubridate)
library(shinyFeedback)
library(RPostgreSQL)
library(dplyr)
library(dbplyr)
library(pool)

DEV <- TRUE

if(DEV)  {
  Sys.setenv(MARVINJUD_DB_HOST="localhost")
  Sys.setenv(MARVINJUD_DB_PORT="5432")
  Sys.setenv(MARVINJUD_DB_NAME="bd_marvinjud")
  Sys.setenv(MARVINJUD_DB_USER="postgres")
  Sys.setenv(MARVINJUD_DB_PASS="postgres")
  Sys.setenv(MARVINJUD_ADMIN_USER="usuario@dominio.com")
  Sys.setenv(MARVINJUD_LOGGED_USER="usuario@dominio.com")
}

db_host <- Sys.getenv("MARVINJUD_DB_HOST")
db_port <- Sys.getenv("MARVINJUD_DB_PORT")
db_name <- Sys.getenv("MARVINJUD_DB_NAME")
db_user <- Sys.getenv("MARVINJUD_DB_USER")
db_pass <- Sys.getenv("MARVINJUD_DB_PASS")

# Cria a conexão com o banco de dados
conn <- dbPool(PostgreSQL(),
                  dbname = db_name, #nome do database a ser acessado
                  host = db_host, #IP do server que hospeda o database
                  port = db_port, #porta de entrada do server
                  user = db_user, #nome do usuário
                  password =  db_pass) # senha concedida ao usuário apontado acima

options(scipen = 999)
options(spinner.type = 8)

onStop(function() {
  poolClose(conn)
})

names_map <- data.frame(
  names = c('nome_regra','detalhe_regra', 'escopo', 'condicao', 'script', 'tipo', 'ativa', 'criada_em', 'criada_por', 'modificada_em',
            'modificada_por', 'excluida'),
  display_names = c('Identicador da Validação','Detalhe da Validação', 'Escopo', 'Condição', 'Script',
                    'Tipo', 'Ativa','Criado em',
                    'Criado por', 'Modificado em', 'Modificado por','Excluída'),
  stringsAsFactors = FALSE
)