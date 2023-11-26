library(dplyr)
library(fredr)
library(ncdf)
library(zoo)
library(plotly)
library(forecast)
library(corrplot)
library(ggcorrplot)

Sys.getenv("FRED_API_KEY")

fredr_set_key(FRED_API_KEY)


# https://www.iea.org/account/licence/products?filter=datahttps://www.iea.org/account/licence/products?filter=data
consumtion <- read.csv('MES_0823.csv') %>% 
  rename(country = `The.Monthly.electricity.data.explorer.and.the.main.highlights.are.available.here..https...www.iea.org.reports.monthly.electricity.statistics.overview`) %>% 
  filter(country == "Spain") %>% 
  filter(`X.1` == "Final Consumption (Calculated)") %>% 
  transmute(date = format(as.Date(as.yearmon(X)), "%Y-%m"), consumtion = `X.3`) %>% 
  mutate(consumtion = as.double(consumtion))

# net_gen <- read.csv('net_electricity_gen.csv') %>% 
#   transmute(date = TIME_PERIOD, generation = OBS_VALUE)
# 
# available <- read.csv('available_for_internal_market.csv') %>% 
#   transmute(date = TIME_PERIOD, available = OBS_VALUE)

oil <- fredr(series_id = "DCOILBRENTEU", frequency = "m") %>% 
  mutate(date = format(as.Date(date, "%Y-%m-%d"), "%Y-%m")) %>% 
  select(date, value) %>% 
  rename(oil = value) 

gas <- fredr(series_id = "PNGASEUUSDM", frequency = "m") %>%
  mutate(date = format(as.Date(date, "%Y-%m-%d"), "%Y-%m")) %>% 
  select(date, value) %>% 
  rename(gas = value) 
  
# Harmonized Index of Consumer Prices: Electricity, Gas, and Other Fuels for Spain
prices <- fredr(series_id = "CP0450ESM086NEST", frequency = "m") %>%
  mutate(date = format(as.Date(date, "%Y-%m-%d"), "%Y-%m")) %>% 
  select(date, value) %>% 
  rename(price = value)

df <- oil %>% 
  full_join(gas) %>% 
  full_join(consumtion) %>% 
  full_join(prices) %>% 
  filter(!is.na(consumtion))


# aaaaaaaaaa
df$year <- format(as.Date(df$date, format="%Y-%M"), "%Y") # Extract the year from the date

# Group by year and summarize the data
df_yearly <- df %>%
  group_by(year) %>%
  summarise(oil = mean(oil), # Change the function as needed
            gas = mean(gas),
            consumtion  = mean(consumtion),
            price = mean(price))

# price fluctuation
price_fluct <- fredr(series_id = "CPGREN01ESM657N", frequency = "a") %>% 
  mutate(date = format(as.Date(date, "%Y-%m-%d"), "%Y")) %>% 
  select(date, value) %>% 
  rename(price_fluct = value)

# GDP
gdp <- fredr(series_id = "CLVMNACSCAB1GQES", frequency = "a") %>% 
  mutate(date = format(as.Date(date, "%Y-%m-%d"), "%Y")) %>% 
  select(date, value) %>% 
  rename(gdp = value) 

# Property prices
property <- fredr(series_id = "QESR368BIS", frequency = "a") %>% 
  mutate(date = format(as.Date(date, "%Y-%m-%d"), "%Y")) %>% 
  select(date, value) %>% 
  rename(property = value) 

# unemployment
unempl <- fredr(series_id = "LRUN74TTESQ156S", frequency = "a") %>% 
  mutate(date = format(as.Date(date, "%Y-%m-%d"), "%Y")) %>% 
  select(date, value) %>% 
  rename(unempl = value) 

df_yearly_pres <- df_yearly %>% 
  rename(date = year) %>%
  full_join(price_fluct) %>% 
  full_join(gdp) %>% 
  full_join(property) %>% 
  full_join(unempl) %>% 
  filter(!is.na(consumtion)) %>% 
  filter(!is.na(property))

corr_res = cor(df_yearly_pres %>% select(-(date)))
ggcorrplot(corr_res, hc.order = TRUE, outline.color = "white",ggtheme = ggplot2::theme_gray, colors = c("#6D9EC1", "white", "#E46726"))+ 
  theme(legend.position = "none")

ggcorrplot(corr_res, hc.order = TRUE, type = "lower", outline.color = "white",ggtheme = ggplot2::theme_gray, colors = c("#6D9EC1", "white", "#E46726"))+
  theme(legend.position = "none")


# corr plot
corr_res = cor(df %>% select(-(date)))
ggcorrplot(corr_res, hc.order = TRUE, type = "lower", outline.color = "white",ggtheme = ggplot2::theme_gray, colors = c("#6D9EC1", "white", "#E46726"))

# pred
df_consumtion <- ts(df$consumtion, start=c(2010, 1), frequency=12)


plot_ly(df, x = ~date, y = ~consumtion, type = 'scatter', mode = 'lines')


write.csv(df, "data.csv", row.names=FALSE)

model = auto.arima(df_consumtion, seasonal = TRUE)

forecast <- forecast(model, h = 24)

df$forecast <- c(rep(NA, nrow(df)), forecast$mean)

df_plt <- data.frame(cbind(time(df_consumtion), df_consumtion))
df_plt$time <- time(df_consumtion)
df_plt$time <- time(forecast$mean)


ggplot(df_plt, aes(x = time)) +
  geom_line(aes(y = ts1), color = "blue") +
  geom_line(aes(y = ts2), color = "red")


ggplot(data = forecast$mean, aes(x=x, y=value)) + geom_line(aes(colour=variable))

fig <- plot_ly(forecast$mean)
fig


plot(df$consumtion, main = "Historical and Forecasted Consumption", xlab = "Date", ylab = "Consumption")
lines(forecast, col = "red")

