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
rainfall <- read_excel("C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_Precipitaciones/datos_lluvia_forecasting.xlsx", sheet = 'Hoja2', col_types = "numeric")
rainfall <- rainfall %>% gather(key = "year", value="precipitaciones", -Anio)
rainfall_ts <- ts(data = rainfall[,3], frequency = 12, start = c(1969,1)) 
rainfall_ts <- window(rainfall_ts, start=c(1969, 1))

# Plot time series
#autoplot(rainfall_ts) + ylab("Rainfall(mm2)") + xlab("Month-Year") + scale_x_date(date_labels = '%b\n%Y', breaks = '1 year', minor_breaks = '1 month') + ggtitle("Rainfall RM 1969-2020")


####################### ANALISIS DE LA SERIE TEMPORAL ####################### 
# # Decomposition of the time series in 3 components: seasonality (Estacionalidad), trend (Tendencia), remainder (Resto)
# rainfall_decomp <- stl(rainfall_ts[,1], s.window = 'periodic')
# #autoplot(rainfall_decomp) + scale_x_date(date_labels = '%b\n%Y', breaks = '1 year', minor_breaks = '1 month') + ggtitle("Decomposition")
# 
# # Calculating the strength of the trend and seasonal --> 1 means very strong. Value goes between 0 and 1.
# Tt <- trendcycle(rainfall_decomp)
# St <- seasonal(rainfall_decomp)
# Rt <- remainder(rainfall_decomp)
# # Trend Strength Calculation
# Ft <- round(max(0,1 - (var(Rt)/var(Tt + Rt))),1)
# # Seasonal Strength Calculation
# Fs <- round(max(0,1 - (var(Rt)/var(St + Rt))),1)
# data.frame('Trend Strength' = Ft , 'Seasonal Strength' = Fs)
# # Season Strength (Fs) --> 0.4
# # Trend Strength (Ft) --> 0.2
####################### ANALISIS DE LA SERIE TEMPORAL ####################### 


# Forecasting
# Splitting train and test set
rainfall_train <- window(rainfall_ts, end = c(1995, 12))
rainfall_test <- window(rainfall_ts, start = c(1996, 1))

# Stationary Test
summary(ur.kpss(rainfall_train))
summary(ur.df(rainfall_train))
kpss.test(rainfall_train)
adf.test(rainfall_train)

# ACF/PACF plot to obtain the order for AR and MA
acf2(rainfall_train, max.lag = 20)

# Trying models --> which model to use is yet to be defined (Good options between ets and fit2_arima)
fit_ets <- ets(rainfall_train, damped = TRUE)
fit1_arima <- auto.arima(rainfall_train)
fit2_arima <- Arima(rainfall_train, order = c(1,0,2), seasonal = c(1,0,2))

# PACF shows a spike in lag 1
# ACF don't know still :(

# Testing both models on the Test Set
# Arima Model
forecast_arima_1 <- forecast(fit2_arima, h=300)
forecast_ets_1 <- forecast(fit_ets, h=300)

forecast_arima <- as.data.frame(forecast_arima_1$mean)
forecast_ets <- as.data.frame(forecast_ets_1$mean)

colnames(forecast_arima) <- "precipitaciones"
colnames(forecast_ets) <- "precipitaciones"

rainfall_train_df <- as.data.frame(rainfall_train)

forecast_arima_plot <- rbind(rainfall_train_df, forecast_arima)
forecast_ets_plot <- rbind(rainfall_train_df, forecast_ets)

forecast_arima_plot <- forecast_arima_plot %>% mutate('Date' = seq(from = as.Date("1969-01-01", '%Y-%m-%d'), to = as.Date("2020-12-31", '%Y-%m-%d'), by = 'month'))
forecast_ets_plot <- forecast_ets_plot %>%  mutate('Date' = seq(from = as.Date("1969-01-01", '%Y-%m-%d'), to = as.Date("2020-12-31", '%Y-%m-%d'), by = 'month'))

rainfall_ts_df <- as.data.frame(rainfall_ts)
rainfall_ts_df <- rainfall_ts_df %>%  mutate('Date' = seq(from = as.Date("1969-01-01", '%Y-%m-%d'), to = as.Date("2020-12-31", '%Y-%m-%d'), by = 'month'))
rainfall_train_df <- rainfall_train_df %>% mutate('Date' = seq(from = as.Date("1969-01-01", '%Y-%m-%d'), to = as.Date("1995-12-31", '%Y-%m-%d'), by = 'month'))


# Creating plot
colors <- c("ARIMA forecast" = "green", "ETS forecast" = "blue", "Actual Data" = "black")
ggplot() + 
  geom_line(forecast_arima_plot, mapping = aes(x=Date, y=precipitaciones, color="ARIMA forecast"),lty=2) + 
  geom_line(forecast_ets_plot, mapping = aes(x=Date, y=precipitaciones, color="ETS_forecast"), lty=2) + 
  geom_line(rainfall_ts_df, mapping = aes(x=Date, y=precipitaciones, color="Actual Data"), lty=1, show.legend = TRUE) + 
  ylab("Rainfall(mm2)") +
  xlab("Datetime") + 
  scale_x_date(date_labels = '%b\n%Y', breaks = '1 year', minor_breaks = '1 month') + 
  ggtitle("RM Rainfall forecast") +
  scale_color_manual(values=colors)

# Comparing both forecasts by RMSE
accuracy(forecast_arima_1, rainfall_test)
accuracy(forecast_ets_1, rainfall_test)

# Actual forecasting
real_ARIMA <- Arima(rainfall_ts, order = c(1,0,2), seasonal = c(1,0,2))
real_forecast <- forecast(real_ARIMA, h = 24)
autoplot(real_forecast) + 
  theme_bw()+ 
  ylab("Rainfall(mm2)") + 
  xlab("Datetime") + 
  #scale_x_date(date_labels = '%b-%Y', breaks = '1 year', minor_breaks = '1 month') + 
  theme_bw() + 
  ggtitle("Pronostico Lluvia 2021-2022 (Modelo ARIMA)")


# Save forecast data in a csv and adding rainfall from 2020
forecast_df <- as.data.frame(real_forecast)
data_2020 <- window(rainfall_ts, start = c(2020,1), end = c(2020, 12))
data_2020 <- as.data.frame(data_2020)

#forecast_df <- rbind(data_2020, forecast_df)
#write.csv(forecast_df, "C:/Users/shali/OneDrive/Escritorio/Tesis/agentbasedsim-tesis/Datos/threat_Precipitaciones/forecast.csv", row.names = TRUE )



# normalized_mse <- function(a,b){
#   #Se buscan los outliers para el set de datos a y el set de datos b
#   outliers_a <- boxplot(a, plot = FALSE)$out
#   outliers_b <- boxplot(b, plot = FALSE)$out
#   aux_a <- a
#   aux_b <- b
#   
#   #De haber outliers, se eliminan
#   if(length(outliers_a)>0){
#     aux_a <- a[-which(a %in% outliers_a)]
#   }
#   if(length(outliers_b)>0){
#     aux_b <- b[-which(b %in% outliers_b)]
#   }
#   
#   #Se obtiene el máximo y el mínimo valor entre los set de datos a y b sin
#   #considerar outliers
#   max_value <- max(c(aux_a,aux_b))
#   min_value <- min(c(aux_a,aux_b))
#   
#   #Se realiza el proceso de normalización de cada conjunto de datos.
#   norm_a <- 2*((a - min_value)/(max_value-min_value))-1
#   norm_b <- 2*((b - min_value)/(max_value-min_value))-1
#   
#   #Se calcula el mse.
#   mse <- sum((norm_a - norm_b)**2)/length(norm_a)
#   return(mse)
# }
