server <- function(input, output, session) {
  # Informacoes da sessao do usuario
  session$userData$email <- Sys.getenv("MARVINJUD_LOGGED_USER")
  session$userData$db_trigger <- reactiveVal(0)

  callModule(
    regras_table_module,
    "regras_table"
  )
}
