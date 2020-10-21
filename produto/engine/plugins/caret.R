library(caret)
library(glue)

DIR_BASE <- Sys.getenv("MARVINJUD_DIR_BASE")
lista_modelos = list.files(path = glue("{DIR_BASE}/models/caret/"), pattern='.rds', recursive=TRUE)

# Para cada arquivo do diretorio de modelos
for(nome_arquivo in lista_modelos){
  print(glue("Carregando o modelo {nome_arquivo} "))
  nome_modelo <- tools::file_path_sans_ext(glue("{nome_arquivo}"))
  !!nome_modelo <- readRDS(glue("models/caret/{modelo}.rds"))
} 

# Função de predição de um modelo Caret
caret.predict <- function(modelo,dados,type) {
  result <- predict(!!modelo, newdata = dados, type = type)
  return(result)
}  
plugins.caret.predict <- Vectorize(caret.predict)