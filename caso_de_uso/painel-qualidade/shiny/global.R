library(shiny)
library(pool)
library(dplyr)
library(RPostgreSQL)
library(pool)
library(glue)


# Cria a conexão com o Postgres
connDB <- dbPool(PostgreSQL(),
                 dbname = "bd_marvinjud", #nome do database a ser acessado
                 host = "localhost", #IP do server que hospeda o database
                 port = 5432, #porta de entrada do server
                 user = "postgres", #nome do usuário
                 password =  "postgres") # senha concedida ao usuário apontado acima

# Views do BD
vwValidacaoAno     <- connDB %>% tbl("vwm_validacao_ano") %>%
  select (anoProcesso, geoNomeMunicipio, geoUF, siglaTribunal, esferaJustica, qtdProcessos, 
          taxaConformidade, qtdRegrasFalha, qtdMovimentos, qtdMovimentosFalha, qtdAssuntos, 
          qtdAssuntosFalha, taxaConformidadeMovimentos, taxaConformidadeAssuntos)  %>% collect()

vwValidacaoOrgao   <- connDB %>% tbl("vwm_validacao_orgao")  %>%
  select( dadosBasicos.orgaoJulgador.codigoOrgao, dadosBasicos.orgaoJulgador.nomeOrgao,
          geoLatitudeOrgao, geoLongitudeOrgao, geoNomeMunicipio, geoUF, siglaTribunal, 
          esferaJustica, qtdProcessos, taxaConformidade, qtdRegrasFalha, qtdMovimentos, 
          qtdMovimentosFalha, qtdAssuntos, 
          qtdAssuntosFalha, taxaConformidadeMovimentos, taxaConformidadeAssuntos) %>% collect()
