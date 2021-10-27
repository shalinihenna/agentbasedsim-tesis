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
temp_ts <- window(temp_ts, start =c(1980,1))

#Plot time series 
autoplot(temp_ts) + ylab("Temperature °C") + xlab("Year") + ggtitle("Daily Max Temperature RM 1980-2020") #+ scale_x_date(date_labels = '%b\n%Y', breaks = '1 year', minor_breaks = '1 month') 

# Decomposition of the time series in 3 components: Seasonality, Trend and Remainder (Estacionalidad, Tendencia y Resto)
temp_decomp <- stl(temp_ts[,1], s.window = 'periodic', na.action = na.remove)
#print(temp_ts, calendar = TRUE)
#temp_ts3 <- na.remove(temp_ts) 

autoplot(temp_decomp)+ theme_bw() + ggtitle("Decomposition (Seasonal, Trend and Remainder)")

# Tt <- trendcycle(temp_decomp)
# St <- seasonal(temp_decomp)
# Rt <- remainder(temp_decomp)
# 
# #Trend Strength Calculation
# Ft <- round(max(0,1 - (var(Rt)/var(Tt + Rt))),1)
# 
# #Seasonal Strength Calculation
# Fs <- round(max(0,1 - (var(Rt)/var(St + Rt))),1)
# 
# data.frame('Trend Strength' = Ft , 'Seasonal Strength' = Fs)
### Ft and Fs = 0, that means no trend or seasonal strength.
temp_ts2 <- na.remove(temp_ts) 
temp_train <- window(temp_ts2, start= c(2005,1), end = c(2019,0))
temp_test <- window(temp_ts2, start = c(2019,1))

# #Stationery test
# summary(ur.kpss(temp_train))
# summary(ur.df(temp_train))
# kpss.test(temp_train)
# adf.test(temp_train)
# 
# #ACF/PACF plot to obtain the order for AR and MA
# acf2(temp_train, max.lag = 365.2)

######## ARIMA ########
#autoarima <- auto.arima(temp_train, d=0, D=0, stepwise = FALSE, approximation = FALSE)
autoarima <- auto.arima(temp_train, stepwise = FALSE, approximation = FALSE, trace = TRUE)
#autoarima2 <- autoarima
autoarima <- Arima(temp_train, order = c(5,0,0), seasonal = c(0,1,0))
checkresiduals(autoarima) #ARIMA(5,0,0) with non-zero mean <-- ambos recomiendan este.
print(summary(autoarima)) # Residual SD (Sigma) = 3.46987

######## ETS ########
fit_ets <- ets(temp_train) 
checkresiduals(fit_ets)
print(summary(fit_ets)) # Residual SD (Sigma) = 3.6407

#######################################################
# Test set

model_arima <- forecast(autoarima, h=731)
model_ets <- forecast(fit_ets, h=731)

model_arima <- as.data.frame(model_arima$mean)
model_ets <- as.data.frame(model_ets$mean)

colnames(model_arima) <- "temperature"
colnames(model_ets) <- "temperature"

temp_train_df <- as.data.frame(temp_train)

model_arima_plot <- rbind(temp_train_df, model_arima)
model_ets_plot <- rbind(temp_train_df, model_ets)

model_arima_plot <- model_arima_plot %>% mutate('Date' = seq(from = as.Date("2005-01-01", '%Y-%m-%d'), to = as.Date("2020-12-31",'%Y-%m-%d'),by = 'day'))
model_ets_plot <- model_ets_plot %>% mutate('Date' = seq(from = as.Date("2005-01-01", '%Y-%m-%d'), to = as.Date("2020-12-31",'%Y-%m-%d'),by = 'day'))

temp_ts_df <- as.data.frame(temp_ts2)
temp_ts_df <- temp_ts_df %>% mutate('Date' = seq(from = as.Date("1980-01-01", '%Y-%m-%d'), to = as.Date("2020-12-31",'%Y-%m-%d'),by = 'day'))

temp_train_df <- temp_train_df %>% mutate('Date' = seq(from = as.Date("2005-01-01", '%Y-%m-%d'), to = as.Date("2018-12-31",'%Y-%m-%d'),by = 'day'))

colors <- c("ARIMA Model Forecast 2018" = "blue", "ETS Model Forecast 2018" = "red", "Actual Data" = "grey")

## Creating forecast plot
ggplot() +
  geom_line(temp_ts_df,mapping = aes(x=Date, y=temperature, 
                                      color= "Actual Data"), lty = 1, show.legend = TRUE) +
  geom_line(model_arima_plot,
            mapping = aes(x=Date, y=temperature, 
                          color= "ARIMA Model Forecast 2018"),lty = 2) +
  #geom_line(model_ets_plot,
  #          mapping = aes(x=Date, y=temperature, 
  #                        color= "ETS Model Forecast 2018"),lty= 2) +
  ylab("Temperature (°C)") + xlab("Datetime") + 
  scale_x_date(date_labels = '%b\n%Y', breaks = '1 year') +
  theme_bw() + ggtitle("Max temp 1980-2020") + 
  scale_color_manual(values=colors)

accuracy(forecast(autoarima, h=731), temp_test)
accuracy(forecast(fit_ets, h=731), temp_test)