library(haven)
library(tidyverse)
library(readr)
library(dplyr)

dataset = read_sav("C:/Users/shali/OneDrive/Escritorio/ENCA_ETCC_ALIMENTOS_INDIVIDUALES.sav")
dataset_copy <- dataset

products <- c("AJO", "ALCACHOFA", "APIO", "ARVEJAS NATURALES", "BROCOLI", "CEBOLLA", "CHOCLO NATURAL", "COLIFLOR", "ESPINACA COCIDA", "FRUTILLA", "HABAS", "LECHUGA", "MELON", "PEPINO", "POROTOS GRANADOS", "POROTOS VERDES", "REPOLLO", "SANDIA", "TOMATE", "ZANAHORIA", "ZAPALLO ITALIANO")

dataset_rm <- dataset %>% filter(dataset$region == 13 )

total_encuestados <- dataset_rm %>% count(dataset_rm$folio)
total <- count(total_encuestados)
new_df <- NULL
for (p in products){
  hortaliza <- dataset_rm %>% filter(dataset_rm$consumidor == 1, dataset_rm$homologado == p)
  total_producto <- count(hortaliza)
  percent <- (total_producto$n/total$n) * 100
  median_hortaliza <- median(hortaliza$consumo_dia,na.rm = FALSE)  
  median_mes <- median(hortaliza$consumo_mes, na.rm = FALSE)
  new_df <- rbind(new_df, data.frame(p,percent,median_mes))
 # print(paste(p,percent, median_mes))
}

write_csv(x=new_df, path="C:/Users/shali/OneDrive/Escritorio/datos_consumidor.csv")



#Codigo extra
dataset_copy <- dataset_copy %>% filter(dataset_copy$consumidor == 1,dataset$homologado %in% products )

write_csv(x=dataset, path="C:/Users/shali/OneDrive/Escritorio/ENCA_ETCC_ALIMENTOS_INDIVIDUALES.csv")

mediann <- median(tomate$consumo_dia,na.rm = TRUE)

lechuga <- dataset %>% filter(dataset$consumidor == 1, dataset$homologado == "LECHUGA")
tomate <- dataset %>% filter(dataset$consumidor == 1, dataset$homologado == "TOMATE")
zanahoria <- dataset %>% filter(dataset$consumidor == 1, dataset$homologado == "ZANAHORIA")

sum_lechuga <- sum(lechuga$consumo_mes, na.rm=TRUE) #6.581.670
sum_tomate <- sum(tomate$consumo_mes, na.rm=TRUE)   #8.083.178
sum_zanahoria <- sum(zanahoria$consumo_mes, na.rm=TRUE) #3.896.376

total_encuestados <- dataset_rm %>% count(dataset_rm$folio)
total <- count(total_encuestados)
total_lechuga <- count(lechuga)
total_tomate <- count(tomate)
total_zanahoria <- count(zanahoria)

percent_lechuga <- (total_lechuga$n/total$n) * 100  
percent_tomate <- (total_tomate$n/total$n) * 100
percent_zanahoria <- (total_zanahoria$n/total$n) * 100

