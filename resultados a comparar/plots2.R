library(dplyr)
library(tidyr)
library(ggplot2)

for (expe in c(1,2,3,4)){
  #PARTE 1: Nuevos gráficos de % variación de precios
  prices <- read.csv(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/Subida_precios_Abril2021.csv'), sep=";")
  prices$Mes <- factor(prices$Mes, levels=prices$Mes)
  ggplot(prices, aes(x=Mes,y=percentPrices, group = 1)) + geom_line(color="red") + geom_point() + xlab("Mes") + ylab("Porcentaje de subida de precios [%]")
  ggsave(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',expe,'-finales/pricesNew.png'), width = 9, height = 7)  
}

#PARTE 2; Gráfico de variación de % real
prices_real <- read.csv('C:/Users/shali/OneDrive/Escritorio/resultados a comparar/avg_preciosreales.csv', sep=";", fileEncoding="UTF-8-BOM")
prices_real$mes <- factor(prices_real$mes, levels=prices_real$mes)
ggplot(prices_real, aes(x=mes,y=percentPrices, group = 1)) + geom_line(color="red") + geom_point() + xlab("Mes") + ylab("Porcentaje de subida de precios [%] (datos obtenido de ODEPA) ")
ggsave('C:/Users/shali/OneDrive/Escritorio/resultados a comparar/realPrices.png', width = 9, height = 7)  

#PARTE 3: merma 
for (exper in c(1)){
  mayorista <- read.csv(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',exper,'-finales/Mercado_Mayorista_total_Mayo2021.csv'), sep=";")
  feriante <- read.csv(paste0('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/resultados/finales/exp',exper,'-finales/Feriantes_total_Mayo2021.csv'), sep=";")
  
  for(prod in mayorista$Producto){
    
  }
}
