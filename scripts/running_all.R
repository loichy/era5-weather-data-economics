#===============================================================================
# running_all.R
# Runs the whole pipeline end to end, in order. Run this from the
# WeatherData_111/ project root (e.g. open WeatherData_111.Rproj first).
#===============================================================================

source("scripts/00_preamble.R")         # packages, folders, cfg (edit cfg$month here)
source("scripts/01_download.R")         # download one month of ERA5 data for Europe
source("scripts/02_visualize_raw_data.R") # check maps + time series of the raw download
source("scripts/03_time_aggreg.R")      # daily precip totals, then collapse to monthly
source("scripts/04_spatial_aggreg.R")   # cell grid -> NUTS3 regions
source("scripts/05_prepare_panel.R")    # merge with Eurostat NUTS3 GDP
source("scripts/06_main_regression.R")  # income-temperature regression
