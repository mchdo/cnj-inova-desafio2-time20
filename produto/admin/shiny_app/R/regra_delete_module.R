# Modulo de exclusão de regras
regra_delete_module <- function(input, output, session, modal_title, regra_to_delete, modal_trigger) {
  ns <- session$ns
  observeEvent(modal_trigger(), {
    
    # Esquema basico de autorizacao para exclusao de regras
    req(session$userData$email == Sys.getenv("MARVINJUD_ADMIN_USER"))
    showModal(
      modalDialog(
        div(
          style = "padding: 30px;",
          class = "text-center",
          h2(
            style = "line-height: 1.75;",
            paste0(
              'Tem certeza que deseja excluir "',
              regra_to_delete()$model,
              '"?'
            )
          )
        ),
        br(),
        title = modal_title,
        size = "m",
        footer = list(
          modalButton("Cancelar"),
          actionButton(
            ns("delete_button"),
            "Excluir validação",
            class = "btn-danger",
            style = "color: #FFF;"
          )
        )
      )
    )
  })



  observeEvent(input$delete_button, {
    req(modal_trigger())
    removeModal()
    regra_out <- regra_to_delete()
    regra_out$criada_em <- as.character(lubridate::with_tz(regra_out$criada_em, tzone = "UTC"))
    regra_out$modificada_em <- as.character(lubridate::with_tz(Sys.time(), tzone = "UTC"))
    regra_out$modificada_por <- session$userData$email
    regra_out$excluida <- 1

    tryCatch({
      uid <- uuid::UUIDgenerate()

      DBI::dbExecute(
        conn,
        "INSERT INTO regras (uid, id_, nome_atributo, atributo_obrigatorio, nome_regra, detalhe_regra, escopo, condicao, script, script_sugestao,  tipo, ativa, criada_em, criada_por, modificada_em, modificada_por,
        excluida) VALUES
        ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,$15,$16, $17)",
        params = c(
          list(uid),
          unname(regra_out)
        )
      )
      session$userData$db_trigger(session$userData$db_trigger() + 1)
      showToast("success", "Regra excluída com sucesso")
    }, error = function(error) {

      showToast("error", "Erro ao excluir regra")

      print(error)
    })
  })
}
