suppressMessages(library(DBI))
suppressMessages(library(RSQLite))
suppressMessages(library(validate))
suppressMessages(library(dplyr))
suppressMessages(library(pool))
suppressMessages(library(dbplyr))
suppressMessages(library(glue))
suppressMessages(library(RPostgreSQL))
R.utils::sourceDirectory(glue("plugins/*.R"))
DEV <- TRUE
if(DEV) {
  Sys.setenv(MARVINJUD_DB_HOST="localhost")
  Sys.setenv(MARVINJUD_DB_PORT="5432")
  Sys.setenv(MARVINJUD_DB_NAME="bd_marvinjud")
  Sys.setenv(MARVINJUD_DB_USER="postgres")
  Sys.setenv(MARVINJUD_DB_PASS="postgres")
  Sys.setenv(MARVINJUD_DIR_BASE="F:/ProjetosPessoais/CNJ/cnj-inova-desafio2-time20")
  
}
db_host <- Sys.getenv("MARVINJUD_DB_HOST")
db_port <- Sys.getenv("MARVINJUD_DB_PORT")
db_name <- Sys.getenv("MARVINJUD_DB_NAME")
db_user <- Sys.getenv("MARVINJUD_DB_USER")
db_pass <- Sys.getenv("MARVINJUD_DB_PASS")
Sys.setenv(PGCLIENTENCODING="LATIN1")

# Cria a conexão com o Postgres
connRegras <- dbPool(PostgreSQL(),
                  dbname = db_name, #nome do database a ser acessado
                  host = db_host, #IP do server que hospeda o database
                  port = db_port, #porta de entrada do server
                  user = db_user, #nome do usuário
                  password =  db_pass) # senha concedida ao usuário apontado acima

# Cria a conexão com o SQLite
connSGT <- dbPool(
    RSQLite::SQLite(),
    dbname = '../../dados/sgt_serventias.sqlite'
)
