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
library(fpp2)

# Data imports and converting data to time series
temp <- read_excel("C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_OlasCalor/Tmax-daily2.xlsx", col_types = "numeric")
temp <- temp %>% gather(key = "year", value="temperature", -date) 
temp_ts <- ts(data = temp[,3], frequency = 366, start = c(1980,1))
temp_ts <- window(temp_ts, start =c(1980,1))

#Plot time series 
autoplot(temp_ts) + ylab("Temperature °C") + xlab("Year") + ggtitle("Daily Max Temperature RM 1980-2020") #+ scale_x_date(date_labels = '%b\n%Y', breaks = '1 year', minor_breaks = '1 month') 

# Decomposition of the time series in 3 components: Seasonality, Trend and Remainder (Estacionalidad, Tendencia y Resto)
temp_decomp <- stl(temp_ts[,1], s.window = 'periodic', na.action = na.remove)
#print(temp_ts, calendar = TRUE)
#temp_ts3 <- na.remove(temp_ts) 

autoplot(temp_decomp)+ theme_bw() + ggtitle("Decomposition (Seasonal, Trend and Remainder)")

Tt <- trendcycle(temp_decomp)
St <- seasonal(temp_decomp)
Rt <- remainder(temp_decomp)

#Trend Strength Calculation
Ft <- round(max(0,1 - (var(Rt)/var(Tt + Rt))),1)

#Seasonal Strength Calculation
Fs <- round(max(0,1 - (var(Rt)/var(St + Rt))),1)

data.frame('Trend Strength' = Ft , 'Seasonal Strength' = Fs)
### Ft and Fs = 0, that means no trend or seasonal strength.
temp_ts2 <- na.remove(temp_ts) 
temp_train <- window(temp_ts2, end = c(2018,12))
temp_test <- window(temp_ts2, start = c(2019,1))

#Stationery test
summary(ur.kpss(temp_train))
summary(ur.df(temp_train))
kpss.test(temp_train)
adf.test(temp_train)

#ACF/PACF plot to obtain the order for AR and MA
acf2(temp_train, max.lag = 365.2)

auto.arima()
