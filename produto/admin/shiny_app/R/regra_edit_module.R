# Modulo de edição de regras
regra_edit_module <- function(input, output, session, modal_title, regra_to_edit, modal_trigger) {
  ns <- session$ns
  observeEvent(modal_trigger(), {
    hold <- regra_to_edit()
    showModal(
      modalDialog(
        fluidRow(
          column(
            width = 6,
            textInput(
              ns("nome_atributo"),width="100%",
              'Atributo',
              value = ifelse(is.null(hold), "", hold$nome_atributo)
            ),
            textInput(
              ns("nome_regra"),width="100%",
              'Identificador da regra',
              value = ifelse(is.null(hold), "", hold$nome_regra)
            ),
            textAreaInput(height="80px",width="560px",
              ns("detalhe_regra"),
              'Descrição',
              value = ifelse(is.null(hold), "", hold$detalhe_regra)
            ),
            textInput(width="100%",
              ns("condicao"),
              'Condição',
              value = ifelse(is.null(hold), "", hold$condicao)
            ),
            textAreaInput(height="80px", width="560px",
              ns("script"),
              'Expressão de validação',
              value = ifelse(is.null(hold), "", hold$script)
            ),
            textAreaInput(height="80px", width="560px",
                          ns("script_sugestao"),
                          'Script de saneamento',
                          value = ifelse(is.null(hold), "", hold$script_sugestao)
            ),
            selectInput(width="100%",
              ns('tipo'),
              'Tipo',
              choices = c('alerta', 'erro'),
              selected = ifelse(is.null(hold), "", hold$tipo)
            ),
            selectInput(width="100%",
                        ns('ativa'),
                        'Ativa',
                        choices = c('Sim'=TRUE, 'Não'=FALSE),
                        selected = ifelse(is.null(hold), "", hold$ativa)
            )
          ),
          column(
            width = 6,
            selectInput(width="100%",
                        ns('atributo_obrigatorio'),
                        'Atributo obrigatório',
                        choices = c('Sim'=TRUE, 'Não'=FALSE),
                        selected = ifelse(is.null(hold), "", hold$atributo_obrigatorio)
            ),
            selectInput(width="100%",
                        ns('escopo'),
                        'Escopo',
                        choices = c('processo', 'polo','assunto','movimento'),
                        selected = ifelse(is.null(hold), "", hold$escopo)
            )
          )
        ),
        title = modal_title,
        size = 'm',
        footer = list(
          modalButton('Cancelar'),
          actionButton(
            ns('submit'),
            'Salvar',
            class = "btn btn-primary",
            style = "color: white"
          )
        )
      )
    )
  })
    
  edit_regra_dat <- reactive({
    hold <- regra_to_edit()

    out <- list(
      "id_" = if (is.null(hold)) uuid::UUIDgenerate() else hold$id_,
      "nome_atributo" = input$nome_atributo,
      "atributo_obrigatorio"  = as.logical(input$atributo_obrigatorio),
      "nome_regra" = input$nome_regra ,
      "detalhe_regra" = input$detalhe_regra ,
      "escopo" = input$escopo,
      "condicao" = input$condicao,
      "script" = input$script,
      "script_sugestao" = input$script_sugestao,
      "tipo" = input$tipo,
      "ativa" =  as.logical(input$ativa),
      "criada_em" = input$criada_em,
      "criada_por" = input$criada_por,
      "modificada_em" = input$modificada_em,
      "modificada_por" = input$modificada_por,
      "excluida" = input$excluida
    )

    time_now <- as.character(lubridate::with_tz(Sys.time(), tzone = "UTC"))

    if (is.null(hold)) {
      # adding a new car

      out$criada_em <- time_now
      out$criada_por <- session$userData$email
    } else {
      # Editing existing car
      out$criada_em <- as.character(hold$criada_em)
      out$criada_por <- hold$criada_por
    }

    out$modificada_em <- time_now
    out$modificada_por <- session$userData$email

    out$excluida  <- FALSE

    out
  })

  validate_edit <- eventReactive(input$submit, {
    dat <- edit_regra_dat()

    # Logic to validate inputs...

    dat
  })

  observeEvent(validate_edit(), {
    removeModal()
    dat <- validate_edit()

    tryCatch({
      # Criando um novo registro
      uid <- uuid::UUIDgenerate()
      print(dat)
      dbExecute(
        conn,
        "INSERT INTO regras (uid, id_, nome_atributo,atributo_obrigatorio,nome_regra, detalhe_regra, escopo, condicao, script, script_sugestao, tipo, ativa, criada_em, criada_por, modificada_em, modificada_por,
        excluida) VALUES
        ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)",
        params = c(
          list(uid),
          unname(dat)
        )
      )

      session$userData$db_trigger(session$userData$db_trigger() + 1)
      showToast("success", paste0(modal_title, " Sucesso"))
    }, error = function(error) {

      showToast("error", paste0(modal_title, " Erro"))

      print(error)
    })
  })

}
