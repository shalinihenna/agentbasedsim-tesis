library(haven)
library(tidyverse)
library(dplyr)

datos = read_sav("C:/Users/shali/OneDrive/Escritorio/Casen en Pandemia 2020 SPSS.sav")

total_hogar <- datos %>% count(datos$tot_hog)
total <- count(datos$id_vivienda) 


datos_filtro <- datos %>% filter(datos$tot_hog == 1 )
total_filtro_viviendas <- datos_filtro %>% count(datos_filtro$id_vivienda)

#Desde acá
datos_distinct <- datos %>% distinct(datos$folio, .keep_all = TRUE)

#Histograma de integrantes por hogar
frecuency <- table(datos_distinct$numviv)
percent_frecuency <- NULL
for (val in 1:length(frecuency)){
  percent_frecuency <- rbind(percent_frecuency, data.frame(frecuency[val],(frecuency[val]/62911)*100))
}
