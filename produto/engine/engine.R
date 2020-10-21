source("global.R")
suppressMessages(library(tibble))
suppressMessages(library(tidyverse))
suppressMessages(library(dplyr))
suppressMessages(library(uuid))

# Carregando os plugins
source(glue("plugins/abjutils.R"))
source(glue("plugins/caret.R"))
source(glue("plugins/cnj.R"))

## Filtra as regras ativas
engine.regras_db <- connRegras %>%  tbl("regras") %>%  select(-uid) %>%  collect() %>%
  group_by(id_) %>%  filter(modificada_em == max(modificada_em)) %>%  ungroup() %>%
  # Exclui as regras excluidas
  filter(excluida == 0)

# Dataframes utilizado para cruzamentos nas validacoes
classes <- connSGT %>% tbl("classes")
movimentos <- connSGT %>% tbl("movimentos")
assuntos <- connSGT %>% tbl("assuntos")
serventias <- connSGT %>% tbl("mpm_serventias")
tipoOrgao <- connSGT %>% tbl("nivelJustica")
procedimentoComplemento <- connSGT %>% tbl("procedimento_complementos")
itens <- connSGT %>% tbl("itens")
complementoTabelado <- connSGT %>% tbl("complemento_tabelado")
complementoMovimento <- connSGT %>% tbl("complemento_movimento")
complemento <- connSGT %>% tbl("complemento")


engine.roda_validador <- function(dados, escopo_regras) {
  
  dados <- dados %>% bind_rows()
  # Carrega as regras do banco de dados
  regras <- engine.regras_db %>%
    mutate(script = if_else(nchar(condicao) > 1, glue("if({condicao}) {script}"), script)) %>%
    select(nome_atributo, script, nome_regra, detalhe_regra, tipo, criada_em, atributo_obrigatorio, escopo) %>%
    rename(
      name = nome_regra, rule = script, name = nome_regra, description = detalhe_regra,
      meta.severity = tipo, origin = nome_atributo, created = criada_em, meta.required = atributo_obrigatorio
    ) %>%
    filter(str_detect(escopo, escopo_regras))

  if (nrow(regras) == 0) {
    print(glue("Nao existem regras para o escopo {escopo_regras}"))
    return(engine.gera_retorno_vazio())
  }
  
  # Verifica se todos os atributos especificados nas regras estão presentes no dataframe..
  v <- validator(.data = regras)
  Pattern <- paste(names(dados), collapse = "|")
  valida_campos_ok <- grepl(Pattern, as.data.frame(v)$origin)
  atributos_ok <- all(valida_campos_ok)
  
  

  # Se algum atributo nao esta presente.
  regras_validar <- regras
  if (!atributos_ok) {
    # Remove as regras para atributos não presentes no dataframe
    regras_validar <- regras[valida_campos_ok, ]

    # Gera os erros de validação para os campos obrigatórios não presentes
    campos_obrigatorios_faltantes <- regras[regras$meta.required == TRUE & !valida_campos_ok, ]
    if (nrow(campos_obrigatorios_faltantes) > 0) {
      # Cria um campo e uma "regra virtual" para cada um do campos obrigatório não presentes no dataframe
      for (j in 1:nrow(campos_obrigatorios_faltantes))
      {
        row <- campos_obrigatorios_faltantes[j, ]
        nova_coluna <- glue("falta_obrigatorio_{row$origin}")
        dados <- dados %>% add_column(!!nova_coluna := TRUE)
        # Cria a regra para falhar  no campo obrigatorio
        regras_validar <- regras_validar %>% add_row(
          origin = row$origin,
          rule = glue("{nova_coluna}==FALSE"),
          name = glue("{row$origin}_obrigatorio"),
          description = glue("Atributo {row$origin} é obrigatorio"),
          meta.severity = "erro",
          created = Sys.Date(),
          meta.required = TRUE
        )
      }
    }
  }
  
  # Verifa se existem registros no dataframe de regras
  if (nrow(regras_validar) == 0) {
    print(glue("Nao existem regras para o escopo {escopo_regras}"))
    return(engine.gera_retorno_vazio())
  }

  # Cria o objeto do validator com as regras
  v <- validator(.data = regras_validar)
  
  # Verifa se existem registros no validator
  if (length(v) == 0) {
    print(glue("Nao existem regras para o escopo {escopo_regras}"))
    return(engine.gera_retorno_vazio())
  }
  
  # Faz o batimento das regras nos dados
  cf <- confront(dados, v)
  
  ret <- list(resumo = as.data.frame(summary(cf)), erros = engine.gera_tabela_erros(cf, regras_validar, dados))

  return(ret)
}
# Gera tabela de resultados da validação
engine.gera_tabela_erros <- function(cf, regras, dados) {
  tabela_erros <- NULL

  # Dataframe do batimento regras X dados
  conf <- as.data.frame(cf)

  # Para cada regra
  for (j in 1:nrow(regras))
  {
    r <- regras[j, ]
    val <- r$origin
    inicio <- ((j - 1) * nrow(dados)) + 1
    fim <- j * nrow(dados)
    select_cf <- conf[inicio:fim, ]
    # Seleciona as entradas que nao atenderam as regras especificadas
    
    tabela_erros <- bind_rows(tabela_erros, dados[(select_cf$value == FALSE | is.na(select_cf$value)) & select_cf$name == r$name, ] %>%
      select(
        millisInsercao,
        siglaTribunal,
        dadosBasicos.numero,
        contains(val)
      ) %>%
      add_column(dataValidacao = Sys.time()) %>%
      add_column(atributoFalha = r$origin) %>%
      add_column(nomeRegra = r$name) %>%
      add_column(detalheRegra = glue("{r$description}")) %>%
      add_column(tipoFalha = r$meta.severity) %>%
      mutate(valorEncontrado = {
        if (glue("{val}") %in% names(.)) as.character(get(val)) else ""
      }) %>%
      replace(is.na(.), "") %>% collect())
  }


  return(tabela_erros)
}

# Gera um registro de retorno vazio (Utilizado quando nao existem regras para o escopo indicado)
engine.gera_retorno_vazio <- function(){
  
  erros <-  data.frame(millisInsercao=double(),
                       siglaTribunal=character(), 
                       dadosBasicos.numero=character(), 
                       dataValidacao=character(),
                       atributoFalha=character(),
                       nomeRegra=character(),
                       detalheRegra=character(),
                       tipoFalha=character(),
                       valorEncontrado=character(),
                       stringsAsFactors=FALSE)
  # Faz o batimento das regras nos dados
  dados <- data.frame(vazio=c())
  v <- validator(TRUE==FALSE)
  cf <- confront(dados, v)  
  ret <- list(resumo = as.data.frame(summary(cf)), erros = erros)
  return(ret)

  
}
engine.gera_erro_falta_atributo <- function(dados, atributo) {
  nova_coluna <- glue("falta_obrigatorio_{atributo}")
  dados <- dados %>% add_column(!!nova_coluna := TRUE)
  
  # Cria a regra para falhar  no campo obrigatorio
  regras_validar <- data.frame(
    origin = atributo,
    rule = glue("{nova_coluna}==FALSE"),
    name = glue("{atributo}_obrigatorio"),
    description = glue("Atributo {atributo} é obrigatorio"),
    meta.severity = "erro",
    created = Sys.Date(),
    meta.required = TRUE,
    stringsAsFactors = FALSE
  )
  
  
  v <- validator(.data = regras_validar)
  cf <- confront(dados, v)
  
  ret <- list(resumo = as.data.frame(summary(cf)), erros = engine.gera_tabela_erros(cf, regras_validar, dados))
  
  
  return(ret)
}


# Carrega um dataframe com os dados que devem ser validados
# Tenta expandir o elemento de lista aninhado indicado no parametros expande_lista
# Não sendo possível abrir o elemento aninhado, retorna um dataframe sem essa lista expandida.
# considerando assim que o atributo não está presente nos dados. O que irá registros de falta de atributo obrigatório na rotina de processamento
engine.carrega_df_validacao <- function(dados, expande_lista) {
  ret <- dados
  
  if (!is.null(expande_lista)) {
    
    ret <- tryCatch(
      {
        # Tenta expandir a lista sem nenhum tratamento dos dados
        lista_expandida <- dados %>% unnest(!!expande_lista)
        return(lista_expandida)
      },
      error =  function (){
        # Caso não consiga expandir a lista, filtra os itens de lista aninhados com elementos nulos e converte todos os campos para "string" permitindo tratar
        # o problema identificado em alguns arquivos de tribunais com o mesmo atributo sendo informado com tipos de dados diferentes
        retorno_error <-  tryCatch(  {
          lista_expandida <- dados %>%
            filter(!map_lgl(!!as.symbol(expande_lista), is.null)) %>%
            mutate(!!as.symbol(expande_lista) := map(!!as.symbol(expande_lista), ~ mutate_each(.x, funs(as.character(.))))) %>%
            unnest(!!expande_lista)
          return(lista_expandida)
        },
        error =  function (){
          # Caso nao consiga expandir retorna os dados de origem (Vai gerar uma falha de atributo obrigatório não informado para o campo de lista)
          return(dados)
        })
        
        return(retorno_error)
      },
      finally={
        return(dados)
      })
    
  }
  return(ret)
}


engine.processa_validacao <- function(processos, grupo_de_regras) {
  # Gera um protocolo para a validacao
  protocolo_validacao <- uuid::UUIDgenerate()
  proc_dadosProcesso <- engine.carrega_df_validacao(processos, NULL)
  erros <- c(protocolo = protocolo_validacao)
  erros <- append(erros, c(processo = engine.roda_validador(proc_dadosProcesso, "processo")))

  if ("movimento" %in% colnames(processos)) {
    proc_movimentos <- engine.carrega_df_validacao(processos, "movimento")
    erros <- append(erros, c(movimento = engine.roda_validador(proc_movimentos, "movimento")))
  } else {
    # Gera o erro de falta de atributo
    erros <- append(erros, c(movimento = engine.gera_erro_falta_atributo(processos, "movimento")))
  }
 
  if ("dadosBasicos.assunto" %in% colnames(processos)) {
    proc_assuntos <- engine.carrega_df_validacao(processos, "dadosBasicos.assunto")
    erros <- append(erros, c(assunto = engine.roda_validador(proc_assuntos, "assunto")))
  } else {
    # Gera o erro de falta de atributo
    erros <- append(erros, c(assunto = engine.gera_erro_falta_atributo(processos, "dadosBasicos.assunto")))
  }

  if ("polo" %in% colnames(processos)) {
    proc_polos <- engine.carrega_df_validacao(processos, "polo")
    erros <- append(erros, c(polo = engine.roda_validador(proc_polos, "polo")))
  } else {
    # Gera o erro de falta de atributo
    erros <- append(erros, c(polo = engine.gera_erro_falta_atributo(processos, "polo")))
  }

  return(erros)
}