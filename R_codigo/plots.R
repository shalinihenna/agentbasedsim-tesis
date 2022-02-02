library(dplyr)
library(tidyr)
library(ggplot2)

#Lectura del csv
mercadoMayoristaTotal <- read.csv('C:/Users/shali/OneDrive/Escritorio/GAMA_1.8.1/tesis/gama_codigo/models/Mercado_Mayorista_total_prueba.csv', sep=";")

#División de unidades y kilos para generar dos graficos
unidades <- c("Ajo", "Alcachofa","Apio","BrÃ³coli","Brócoli","Choclo","Coliflor","Lechuga","MelÃ³n","Melón","Pepino ensalada","Repollo","Sandia","Zapallo italiano")
kilos <- c("Arveja Verde","Cebolla","Espinaca","Haba","Poroto granado","Poroto verde","Tomate","Zanahoria","Frutilla")

products_unidades <- subset(mercadoMayoristaTotal, mercadoMayoristaTotal$Producto %in% unidades)
products_kilos <- subset(mercadoMayoristaTotal, mercadoMayoristaTotal$Producto %in% kilos)

#Plot del geombar (grafico de barras)
ggplot(products_unidades, aes(x=Producto, y=Volumen)) + geom_bar(stat = "identity")
ggplot(products_kilos, aes(x=Producto, y=Volumen)) + geom_bar(stat = "identity")