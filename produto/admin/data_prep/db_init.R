library(RPostgreSQL)
library(DBI)
library(dplyr)

Sys.setenv(MARVINJUD_DB_HOST="localhost")
Sys.setenv(MARVINJUD_DB_PORT="5432")
Sys.setenv(MARVINJUD_DB_NAME="bd_marvinjud")
Sys.setenv(MARVINJUD_DB_USER="postgres")
Sys.setenv(MARVINJUD_DB_PASS="postgres")

db_host <- Sys.getenv("MARVINJUD_DB_HOST")
db_port <- Sys.getenv("MARVINJUD_DB_PORT")
db_name <- Sys.getenv("MARVINJUD_DB_NAME")
db_user <- Sys.getenv("MARVINJUD_DB_USER")
db_pass <- Sys.getenv("MARVINJUD_DB_PASS")

# Cria a conexão com o banco
conn <- dbConnect(PostgreSQL(),
                 dbname = db_name, #nome do database a ser acessado
                 host = db_host, #IP do server que hospeda o database
                 port = db_port, #porta de entrada do server
                 user = db_user, #nome do usuário
                 password =  db_pass) # senha concedida ao usuário apontado acima


# Cria a tabela de regras
create_regras_query = "CREATE TABLE regras (
  uid                             TEXT PRIMARY KEY,
  id_                             TEXT NOT NULL,
  nome_atributo                   TEXT NOT NULL  DEFAULT '',
  atributo_obrigatorio            BOOLEAN DEFAULT FALSE,
  nome_regra                      TEXT NOT NULL  DEFAULT '',
  detalhe_regra                   TEXT  NOT NULL DEFAULT '',
  escopo                          TEXT NOT NULL DEFAULT 'processo',
  condicao                        TEXT  NOT NULL DEFAULT '',
  script                          TEXT NOT NULL DEFAULT '',
  script_sugestao                 TEXT NOT NULL DEFAULT '',
  tipo                            TEXT NOT NULL DEFAULT 'warning',
  ativa                           BOOLEAN DEFAULT FALSE,
  criada_em                       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  criada_por                      TEXT NOT NULL DEFAULT '',
  modificada_em                   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modificada_por                  TEXT NOT NULL DEFAULT '',
  excluida                        BOOLEAN DEFAULT FALSE
)"

dbExecute(conn, "DROP TABLE IF EXISTS regras")

# Executa query de criacao de regras
dbExecute(conn, create_regras_query)

dbListTables(conn)

# MUST disconnect from SQLite before continuing
dbDisconnect(conn)