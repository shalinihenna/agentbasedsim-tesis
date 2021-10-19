#### DEFINICION DE OLA DE CALOR ####
#### Se define como un evento de Ola de Calor (diurna), el periodo de tiempo en el cual las temperaturas maximas diarias superan un umbral diario considerado extremo, por tres dias consecutivos o mas.

# Library imports
library(readxl)
library(tidyr)
library(ggplot2)
library(ggfortify)
library(forecast)
library(urca)
library(tseries)
library(astsa)
library(dplyr)

# Data imports and converting data to time series
temp <- read_excel("C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_OlasCalor/Tmax-daily2.xlsx", col_types = "numeric")
temp <- temp %>% gather(key = "year", value="temperature", -date) 
temp_ts <- ts(data = temp[,3], frequency = 366, start = c(1980,1))
temp_ts <- window(temp_ts, start = c(1980,1))

#Plot time series 
autoplot(temp_ts) + ylab("Temperature °C") + xlab("Year") + ggtitle("Daily Max Temperature RM 1980-2020") #+ scale_x_date(date_labels = '%b\n%Y', breaks = '1 year', minor_breaks = '1 month') 

# Decomposition of the time series in 3 components: Seasonality, Trend and Remainder (Estacionalidad, Tendencia y Resto)
temp_decomp <- stl(temp_ts[,1], s.window = 'periodic', na.action = na.pass)
autoplot(temp_decomp) + ggtitle("Decomposition (Seasonal, Trend and Remainder)")