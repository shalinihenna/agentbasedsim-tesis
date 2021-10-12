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

# Data imports and converting data to time series
rainfall <- read_excel("C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_Precipitaciones/datos_lluvia_forecasting.xlsx", sheet = 'Hoja2', col_types = "numeric")
rainfall <- rainfall %>% gather(key = "year", value="Point.Forecast", -Anio)
rainfall_ts <- ts(data = rainfall[,3], frequency = 12, start = c(1969,1)) 
rainfall_ts <- window(rainfall_ts, start=c(1969, 1))

fit_arima <- Arima(rainfall_ts, order = c(1,0,2), seasonal = c(1,0,2))
print(summary(fit_arima))
checkresiduals(fit_arima)

fit_ets <- ets(rainfall_ts, damped = TRUE) #Exponential smoothing state
print(summary(fit_ets))
checkresiduals(fit_ets)

fit_autoarima <- auto.arima(rainfall_ts, d=0, D=0, stepwise = FALSE, approximation = FALSE)
print(summary(fit_autoarima))
checkresiduals(fit_autoarima)

# El mejor modelo es ARIMA, asi que el forecasting contempla el fit arima
forecast_arima <- forecast(fit_arima, h=24, level=c(20, 40, 80)) ########################### Se cambia el h en caso de querer extender fecha de proyeccion y las fechas en mutate (forecast_df)
autoplot(forecast_arima)

# Save forecast data in a csv and adding rainfall from 2020
forecast_df <- as.data.frame(forecast_arima)
forecast_df <- forecast_df %>% mutate('Date' = str_to_title(format(seq(from = as.Date("2021-01-01", '%Y-%m-%d'), to = as.Date("2022-12-01", '%Y-%m-%d'), by = 'month'), "%B %Y")))
forecast_df <- cbind.data.frame(do.call(rbind, strsplit(forecast_df$Date, ' ')), data.frame(forecast_df, row.names = NULL))
forecast_df <- forecast_df %>% rename(month = 1, year = 2)
forecast_df$Date <- NULL;
data_2020 <- window(rainfall_ts, start = c(2020,1), end = c(2020, 12))
data_2020 <- as.data.frame(data_2020)
data_2020 <- data_2020 %>% mutate('Date' = str_to_title(format(seq(from = as.Date("2020-01-01", '%Y-%m-%d'), to = as.Date("2020-12-01", '%Y-%m-%d'), by = 'month'), "%B %Y")))
data_2020 <- cbind.data.frame(do.call(rbind, strsplit(data_2020$Date, ' ')), data.frame(data_2020, row.names = NULL))
data_2020 <- data_2020 %>% rename(month = 1, year = 2)
data_2020$Date <- NULL;
final_data <- smartbind(data_2020, forecast_df)

write.csv(final_data, "C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_Precipitaciones/forecast.csv", row.names = FALSE )

