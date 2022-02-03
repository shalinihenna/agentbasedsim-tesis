library(dplyr)
library(tidyr)
library(ggplot2)

#División de unidades y kilos para generar dos graficos
unidades <- c("Ajo", "Alcachofa","Apio","BrÃ³coli","Brócoli","Choclo","Coliflor","Lechuga","MelÃ³n","Melón","Pepino ensalada","Repollo","Sandia","Zapallo italiano")
kilos <- c("Arveja Verde","Cebolla","Espinaca","Haba","Poroto granado","Poroto verde","Tomate","Zanahoria","Frutilla")

for (expe in c(1,2,3,4)){
  #PARTE 1: Plots mercado mayorista
  #Lectura del csv
  mercadoMayoristaTotal <- read.csv(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/Mercado_Mayorista_total_Mayo2021.csv'), sep=";")
  
  mm_unidades <- subset(mercadoMayoristaTotal, mercadoMayoristaTotal$Producto %in% unidades)
  mm_kilos <- subset(mercadoMayoristaTotal, mercadoMayoristaTotal$Producto %in% kilos)
  
  #Plot del geombar (grafico de barras)
  ggplot(mm_unidades, aes(x=Producto, y=mercadoMayoristaVolumenTotal)) + geom_bar(stat = "identity", fill = "yellow") + ylab("Volumen [un.]")
  ggsave(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/plotMayoristaUnidades.png'), width = 9, height = 7)
  ggplot(mm_kilos, aes(x=Producto, y=mercadoMayoristaVolumenTotal)) + geom_bar(stat = "identity", fill = "yellow") + ylab("Volumen [kg.]")
  ggsave(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/plotMayoristaKilos.png'), width = 9, height = 7)
  
  #-----------------------------------------------
  
  #PARTE 2: Plots feriante
  #Lectura del csv
  ferianteTotal <- read.csv(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/Feriantes_total_Mayo2021.csv'), sep=";")
  
  fer_unidades <- subset(ferianteTotal, ferianteTotal$Producto %in% unidades)
  fer_kilos <- subset(ferianteTotal, ferianteTotal$Producto %in% kilos)
  
  #Plot del geombar (grafico de barras)
  ggplot(fer_unidades, aes(x=Producto, y=feriantesVolumenTotal)) + geom_bar(stat = "identity", fill = "green") + ylab("Volumen [un.]")
  ggsave(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/plotFerianteUnidades.png'), width = 9, height = 7)
  ggplot(fer_kilos, aes(x=Producto, y=feriantesVolumenTotal)) + geom_bar(stat = "identity", fill = "green") + ylab("Volumen [kg.]")
  ggsave(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/plotFerianteKilos.png'), width = 9, height = 7)
  
  #-----------------------------------------------
  
  #PARTE 3: Plots consumidor
  consumerTotal <- read.csv(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/Consumidores_total_Mayo2021.csv'), sep=";")
  
  con_unidades <- subset(consumerTotal, consumerTotal$Producto %in% unidades)
  con_kilos <- subset(consumerTotal, consumerTotal$Producto %in% kilos)
  
  #Plot del geombar (grafico de barras)
  ggplot(con_unidades, aes(x=Producto, y=consumersVolumenTotal)) + geom_bar(stat = "identity", fill = "blue") + ylab("Volumen [un.]")
  ggsave(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/plotConsumerUnidades.png'), width = 9, height = 7)
  ggplot(con_kilos, aes(x=Producto, y=consumersVolumenTotal)) + geom_bar(stat = "identity", fill = "blue") + ylab("Volumen [kg.]")
  ggsave(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/plotConsumerKilos.png'), width = 9, height = 7)
  
}


for (expe in c(1,2,3,4)){
  avg_fer <- read.csv(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/Avg_ganancias_Feriante_Mayo2021.csv'), sep=";")
  prices <- read.csv(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/Subida_precios_Abril2021.csv'), sep=";")
  
  prices$Mes <- factor(prices$Mes, levels=prices$Mes)
  avg_fer$Mes <- factor(avg_fer$Mes, levels=avg_fer$Mes)
  
  ggplot(prices, aes(x=Mes,y=percentPrices, group = 1)) + geom_line(color="red") + geom_point() + xlab("Mes") + ylab("Porcentaje de subida de precios [%]")
  ggsave(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/prices.png'), width = 9, height = 7)
  ggplot(avg_fer, aes(x=Mes, y=avg_feriantes, group = 1)) + geom_line(color="blue") + geom_point() + xlab("Mes") + ylab("Precios [CLP]")
  ggsave(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/avg_ganancias_feriantes.png'), width = 9, height = 7)
}





