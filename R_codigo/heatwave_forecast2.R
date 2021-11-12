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
library(stringr)
library(gtools)
library(lubridate)

# Data imports and converting data to time series
temp <- read_excel("C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_OlasCalor/Tmax-daily2.xlsx", col_types = "numeric")
temp <- temp %>% gather(key = "year", value="temperature", -date) 
temp_ts <- ts(data = temp[,3], frequency = 366, start = c(1980,1))
temp_ts <- na.remove(temp_ts)
temp_ts <- window(temp_ts, start =c(2005,1))

fit_arima <- Arima(temp_ts, order = c(5,0,0), seasonal = c(0,1,0))
print(fit_arima)
checkresiduals(fit_arima)

# fit_ets <- ets(temp_ts, damped = TRUE)
# print(fit_ets)
# checkresiduals(fit_ets)

# Residual SD ARIMA (Sigma) = 4.628 
# Residual SD ETS (Sigma) = 3.6472
# ¿Cual es mejor y porque?
# Si bien es mejor ETS segun el Residual, pero el forecasting que hace es una línea recta, así que nos quedamos con ARIMA model. 

forecast_arima <- forecast(fit_arima, h = 730) #hace forecasting para años 2021 y 2022
autoplot(forecast_arima)

# forecast_ets <- forecast(fit_ets, h = 730)
# autoplot(forecast_ets)

forecast_df <- as.data.frame(forecast_arima)
forecast_df <- forecast_df %>% mutate('Date' = str_to_title(format(seq(from = as.Date("2021-01-01", '%Y-%m-%d'), to = as.Date("2022-12-31", '%Y-%m-%d'), by = 'day'), "%d-%m-%Y")))

n = nrow(forecast_df)
a <- c()
for (i in 1:n) {
  a = c(a,(runif(1, forecast_df$`Point Forecast`[i]*0.95, forecast_df$`Point Forecast`[i]*1.05)))
}
forecast_df$New_Point = a

new_forecast_df <- data.frame(
  temperature = forecast_df$New_Point,
  Date = forecast_df$Date
) 

#Generar archivo
data_2020 <- window(temp_ts, start = c(2020,0))
data_2020 <- as.data.frame(data_2020)
data_2020 <- data_2020 %>% mutate('Date' = str_to_title(format(seq(from = as.Date("2020-01-01", '%Y-%m-%d'), to = as.Date("2020-12-31", '%Y-%m-%d'), by = 'day'), "%d-%m-%Y")))
final_data <- smartbind(data_2020, new_forecast_df)

write.csv(final_data, "C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_OlasCalor/forecastTMax.csv", row.names = FALSE )

## Procesamiento e identificación de olas de calor
umbral <- read_excel("C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_OlasCalor/UmbralOlasdeCalor.xlsx", col_types = "numeric")
total = nrow(final_data)
initial_month <- str_to_title(month(final_data$Date[1], label=TRUE, abbr = FALSE))
meses <- c()
dias <- c()
olascalor <- c()
oc <- 0
anios <- c()
d <- 0
counter <- 0

for(i in 1:total){
  u <- umbral[format(as.Date(final_data$Date[i], format="%d-%m-%Y"), "%d"), str_to_title(month(final_data$Date[i], label=TRUE, abbr = FALSE))]
  
  #cuando el mes cambia, se registran los valores de la ola de calor en la lista principal
  if(str_to_title(month(final_data$Date[i], label=TRUE, abbr = FALSE)) != initial_month){
    olascalor <- c(olascalor, oc)
    oc <- 0
    dias <- c(dias, d)
    d <- 0
    counter <- 0
    meses <- c(meses, initial_month)
    initial_month <- str_to_title(month(final_data$Date[i], label=TRUE, abbr = FALSE))
    anios <- c(anios, format(as.Date(final_data$Date[i-1], format="%d-%m-%Y"), "%Y"))
  }
  
  if(final_data$temperature[i] >= u){
    counter <- counter + 1
  }else{
    if(counter >= 3){
      oc <- oc + 1
      d <- d + counter
    }
    if(counter > 0){
      counter <- 0
    }
  }
}

olascalor <- c(olascalor, oc)
oc <- 0
dias <- c(dias, d)
d <- 0
counter <- 0
meses <- c(meses, initial_month)
initial_month <- str_to_title(month(final_data$Date[i], label=TRUE, abbr = FALSE))
anios <- c(anios, format(as.Date(final_data$Date[i], format="%d-%m-%Y"), "%Y"))

olas_calor <- data.frame(
  year = anios,
  month = meses,
  days = dias,
  heatwave = olascalor
) 

write.csv(olas_calor, "C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_OlasCalor/heatwaves.csv", row.names = FALSE )