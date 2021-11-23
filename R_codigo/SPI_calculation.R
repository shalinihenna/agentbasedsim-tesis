library(readxl)
library(SPEI)
library(dplyr)
library(tidyr)
library(stringr)
library(gtools)

data <- read.csv("C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_Precipitaciones/forecastRainfall.csv")
rainfall <- read_excel("C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_Precipitaciones/datos_lluvia_forecasting.xlsx", sheet = 'Hoja2', col_types = "numeric")
rainfall <- rainfall %>% gather(key = "year", value="Point.Forecast", -Anio)
rainfall_ts <- ts(data = rainfall[,3], frequency = 12, start = c(1969,1)) 
rainfall_ts <- window(rainfall_ts, end=c(2019,12))

rainfall_df <- as.data.frame(rainfall_ts) 
rainfall_df <- rainfall_df %>% mutate('Date' = str_to_title(format(seq(from = as.Date("1969-01-01", '%Y-%m-%d'), to = as.Date("2019-12-01", '%Y-%m-%d'), by = 'month'), "%B %Y")))
rainfall_df <- cbind.data.frame(do.call(rbind, strsplit(rainfall_df$Date, ' ')), data.frame(rainfall_df, row.names = NULL))
rainfall_df <- rainfall_df %>% rename(month = 1, year = 2)
rainfall_df$Date <- NULL;

all_data <- smartbind(rainfall_df, data)

SPI_rainfall <- spi(all_data$Point.Forecast, scale=1, distribution='PearsonIII')

SPI_final <- as.data.frame(SPI_rainfall$fitted)
SPI_final <- SPI_final %>% mutate('Date' = str_to_title(format(seq(from = as.Date("1969-01-01", '%Y-%m-%d'), to = as.Date("2022-12-01", '%Y-%m-%d'), by = 'month'), "%B %Y")))
SPI_final <- cbind.data.frame(do.call(rbind, strsplit(SPI_final$Date, ' ')), data.frame(SPI_final, row.names = NULL))
SPI_final <- SPI_final %>% rename(month = 1, year = 2)
SPI_final$Date <- NULL;

SPI_final2 <- filter(SPI_final, year >= 2020)

write.csv(SPI_final2, "C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_Precipitaciones/SPI.csv", row.names = FALSE )


# hasta2010 <- window(rainfall_ts, end=c(2011,12))
# hasta2010 <- as.data.frame(hasta2010) 
# hasta2010 <- hasta2010 %>% mutate('Date' = str_to_title(format(seq(from = as.Date("1969-01-01", '%Y-%m-%d'), to = as.Date("2011-12-01", '%Y-%m-%d'), by = 'month'), "%B %Y")))
# hasta2010 <- cbind.data.frame(do.call(rbind, strsplit(hasta2010$Date, ' ')), data.frame(hasta2010, row.names = NULL))
# hasta2010 <- hasta2010 %>% rename(month = 1, year = 2)
# hasta2010$Date <- NULL;
# SPI_new <- spi(hasta2010$Point.Forecast, scale=1, distribution='PearsonIII')

##### To-do
#1. Leer datos de 1980 hasta 2019
#2. Convertirlos como en el otro archivo y que queden en el mismo formato que el data
#3. Unir datos de 1980
#5. Calcular SPI