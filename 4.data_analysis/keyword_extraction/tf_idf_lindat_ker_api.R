library(httr)
library(jsonlite)
library(dplyr)

article <- "Rakousko, plným názvem Rakouská republika, je vnitrozemská spolková republika ležící ve střední Evropě. Skládá se z devíti spolkových zemí.
Hraničí s Lichtenštejnskem a Švýcarskem na západě, s Itálií a Slovinskem na jihu, s Maďarskem a Slovenskem na východě a s Českem a Německem na severu.
Jejím hlavním městem je Vídeň. Dalšími velkými městy jsou Štýrský Hradec, Linec, Salcburk a Innsbruck. Rakousko je značně hornatou zemí, horská území zaujímají 60 procent jeho plochy. Nížiny se nacházejí zejména kolem Dunaje, největší rakouské řeky."

response <- httr::RETRY(
  verb = "POST",
  url = "http://lindat.mff.cuni.cz/services/ker",
  query = list(
    language = "cs",
    treshold = 0.2,
    `maximum-words` = 15
  ),
  config = httr::add_headers(
    Connection = "keep-alive",
    `Accept-Encoding` = "gzip, deflate, br"
  ),
  accept("application/json"),
  content_type("multipart/form-data; boundary=----RawText"),
  body = paste0(
    "------RawText\rContent-Disposition: form-data; name=\"data\"\r\r", article,
    "\r------RawText--"
  )
) %>%
  content(as = "text") %>%
  fromJSON()

#' @misc{11234/1-1650,
#'   title = {{KER} - Keyword Extractor},
#'   author = {Libovick{\'y}, Jind{\v r}ich},
#'  url = {http://hdl.handle.net/11234/1-1650},
#'  note = {{LINDAT}/{CLARIAH}-{CZ} digital library at the Institute of Formal and Applied Linguistics ({{\'U}FAL}), Faculty of Mathematics and Physics, Charles University},
#'  copyright = {Apache License 2.0},
#'  year = {2016} }
