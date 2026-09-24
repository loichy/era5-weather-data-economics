#===============================================================================
# 05_prepare_panel.R
# Loads NUTS3 GDP per capita from Eurostat and merges it with our NUTS3 weather
# table for the single reference year (cfg$year).
# Reads: nuts3_weather.rds. Writes: panel_nuts3.rds to data/final/.
#===============================================================================

source("scripts/00_preamble.R")

weather <- readRDS(file.path(dir$intermediary, "nuts3_weather.rds"))

# nama_10r_3gdp: annual regional GDP: EUR_HAB = GDP per capita, in euros.
gdp <- get_eurostat("nama_10r_3gdp") |>
  filter(unit == "EUR_HAB", format(TIME_PERIOD, "%Y") == as.character(cfg$year)) |>
  transmute(NUTS_ID = geo, gdp_pc = values) # Rename variables ot match variable names in our weather data

panel_nuts3 <- weather |>
  inner_join(gdp, by = "NUTS_ID") |>
  mutate(year = cfg$year)

saveRDS(panel_nuts3, file.path(dir$final, "panel_nuts3.rds"))

# How to turn this into a REAL panel: loop 01_download.R / 03_time_aggreg.R /
# 04_spatial_aggreg.R over several years, stack the resulting nuts3_weather
# tables (adding a `year` column each time), and inner_join them here against
# every matching Eurostat year instead of just year.
