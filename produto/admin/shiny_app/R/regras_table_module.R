#' Tabela de edição de regras
regras_table_module_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(
        width = 2,
        actionButton(
          ns("add_regra"),
          "Adicionar regra",
          class = "btn-success",
          style = "color: #fff;",
          icon = icon('plus'),
          width = '100%'
        ),
        tags$br(),
        tags$br()
      )
    ),
    fluidRow(
      column(
        width = 12,
        title = "Validações de dados",
        DTOutput(ns('regras_table')) %>%
          withSpinner(),
        tags$br(),
        tags$br()
      )
    ),
    tags$script(src = "regras_table_module.js"),
    tags$script(paste0("regras_table_module_js('", ns(''), "')"))
  )
}

regras_table_module <- function(input, output, session) {

  # Le as regras do banco de dados
  regras <- reactive({
    session$userData$db_trigger()
    
    out <- NULL
    tryCatch({
      out <- conn %>%
        tbl('regras') %>%
        select(-uid) %>%
        collect() %>%
        mutate(
          criada_em = as.POSIXct(criada_em, tz = "UTC"),
          modificada_em = as.POSIXct(modificada_em, tz = "UTC")
        ) %>%
        # Encontra as regras mais recentes
        group_by(id_) %>%
          filter(modificada_em == max(modificada_em)) %>%
          ungroup() %>%
        # Exclui as regras excluidas
        filter(excluida == 0) %>%
        arrange(desc(modificada_em))  %>%
        mutate(l_ativa = case_when(ativa == 1 ~ "Sim",ativa == 0 ~ "Não"))
      

    }, error = function(err) {

      print(err)
      showToast("error", "Erro de conexão ao banco de dados")

    })

    out
  })


  regras_table_prep <- reactiveVal(NULL)

  observeEvent(regras(), {
    out <- regras()

    ids <- out$id_

    # Botoes de acoes nos registros
    actions <- purrr::map_chr(ids, function(id_) {
      paste0(
        '<div class="btn-group" style="width: 75px;" role="group" aria-label="Basic example">
          <button class="btn btn-primary btn-sm edit_btn" data-toggle="tooltip" data-placement="top" title="Edit" id = ', id_, ' style="margin: 0"><i class="fa fa-pencil-square-o"></i></button>
          <button class="btn btn-danger btn-sm delete_btn" data-toggle="tooltip" data-placement="top" title="Delete" id = ', id_, ' style="margin: 0"><i class="fa fa-trash-o"></i></button>
        </div>'
      )
    })

    
    out <- out %>%
      select(-id_, -excluida)
    
    out <- cbind(
      tibble(" " = actions),
      out
    )

    if (is.null(regras_table_prep())) {
      regras_table_prep(out)

    } else {

      replaceData(regras_table_proxy, out, resetPaging = FALSE, rownames = FALSE)

    }
  })

  output$regras_table <- renderDT({
    req(regras_table_prep())
    out <- regras_table_prep()

    datatable(
      out,
      rownames = FALSE,
      filter = "top",
      
      colnames = c('_','Atributo','Identificador', 'Descrição', 'Escopo', 'Tipo', 'Última modificação','Modificada por','Ativa'),
      selection = "none",
      class = "compact stripe row-border nowrap",
      escape = -1,
      extensions = c("Buttons"),
      options = list(
        language = list(url = 'Portuguese-Brasil.json'),
        pageLength = 20,
        lengthMenu = c(20, 40, 60, 80, 100),
        scrollX = TRUE,
        dom = 'Bftip',
        buttons = list(
          list(
            extend = "excel",
            text = "Planilha de regras",
            title = paste0("validacoes-", Sys.Date()),
            exportOptions = list(
              columns = 1:(length(out) - 1)
            )
          )
        ),
            columnDefs = list(
            list(targets = 0, orderable = FALSE),
            list(
              targets = 1,
              title = "Atributo",
              width = "15%"
            ),
            list(targets = 2, visible = FALSE),
            list(
              targets = 3,
              title = "Identificador",
              width = "15%"
            ),
            list(
              targets = 4,
              orderable = FALSE,
              title = "Descrição",
              width = "45%"
            ),
            list(
              targets = 5,
              title = "Escopo",
              className = 'dt-center'
            ),
            list(targets = 6, visible = FALSE),
            list(targets = 7, visible = FALSE),
            list(targets = 8, visible = FALSE),
            
            list(
              targets = 9,
              title = "Tipo",
              className = 'dt-center'
            ),
            list(targets = 10, visible = FALSE),
            list(targets = 11, visible = FALSE),
            list(targets = 12, visible = FALSE),
            list(
              targets = 15,
              title = "Ativa",
              className = 'dt-center'
            ),
            
            list(
              targets = 13,
              title = "Última modificação",
              className = 'dt-center'
            ),
            list(
              targets = 14,
              title = "Modificada por",
              className = 'dt-center'
            )
            
        ),
        drawCallback = JS("function(settings) {
          // removes any lingering tooltips
          $('.tooltip').remove()
        }")
      )
    ) %>%
      formatDate(
        columns = c("criada_em", "modificada_em"),
        method = 'toLocaleString'
      )

  })

  regras_table_proxy <- DT::dataTableProxy('regras_table')

  callModule(
    regra_edit_module,
    "add_regra",
    modal_title = "Adicionar regra de qualidade dos dados",
    regra_to_edit = function() NULL,
    modal_trigger = reactive({input$add_regra})
  )

  regra_to_edit <- eventReactive(input$regra_id_to_edit, {

    regras() %>%
      filter(id_ == input$regra_id_to_edit)
  })

  callModule(
    regra_edit_module,
    "edit_regra",
    modal_title = "Editar validação",
    regra_to_edit = regra_to_edit,
    modal_trigger = reactive({input$regra_id_to_edit})
  )

  regra_to_delete <- eventReactive(input$regra_id_to_delete, {
    regras() %>%
      filter(id_ == input$regra_id_to_delete) %>%
      as.list()
  })

  callModule(
    regra_delete_module,
    "delete_regra",
    modal_title = "Excluir Validação",
    regra_to_delete = input$regra_id_to_delete,
    modal_trigger = reactive({input$regra_id_to_delete})
  )

}
