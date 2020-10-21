library(tfdeploy)
library(glue)


DIR_BASE <- Sys.getenv("MARVINJUD_DIR_BASE")
lista_modelos = list.files(path = glue("{DIR_BASE}/models/tf/"), pattern='pb', recursive=TRUE)


# Para cada arquivo do diretorio de modelos
sess <- tensorflow::tf$Session()
for(nome_arquivo in lista_modelos){
  print(glue("Carregando o modelo {nome_arquivo} "))
  nome_modelo <- tools::file_path_sans_ext(glue("{nome_arquivo}"))
  !!nome_modelo <- tfdeploy::load_savedmodel(
    sess,
    system.file(glue("{DIR_BASE}/models/tf/{nome_arquivo}"), package = "tfdeploy")
  )
} 

tf.predict <- function(modelo,dados) {
  result <-  tfdeploy::predict_savedmodel(
    dados,
    !!modelo
  )
  return(result)
}
plugins.tf.predict <- Vectorize(tf.predict)