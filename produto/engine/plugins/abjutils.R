library(abjutils)
# 
# Documentação do pacote abjutils disponível em 
# https://cran.r-project.org/web/packages/abjutils/abjutils.pdf
# 
# Calculo dos digitos verificadores do CNJ
plugins.abjutils.calc_dig <- Vectorize(calc_dig, SIMPLIFY = FALSE)
# Verifica o digito verificador de um numero CNJ
plugins.abjutils.check_dig <- Vectorize(check_dig, SIMPLIFY = FALSE)
# Remove todos os caracteress nao numericos
plugins.abjutils.clean_cnj <- Vectorize(clean_cnj, SIMPLIFY = FALSE)
plugins.abjutils.clean_id <- Vectorize(clean_id, SIMPLIFY = FALSE)
# Remove todos os caracteress nao numericos
plugins.abjutils.extract_parts  <- Vectorize(extract_parts, SIMPLIFY = FALSE)
plugins.abjutils.pattern_cnj <- Vectorize(pattern_cnj, SIMPLIFY = FALSE)