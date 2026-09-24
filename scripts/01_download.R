#===============================================================================
# 01_download.R
# Downloads one month of ERA5 data for Europe from the Copernicus Climate Data
# Store (CDS): daily min/max 2m temperature, and hourly total precipitation.
# Writes: 3 NetCDF files to data/source/.
#===============================================================================

source("scripts/00_preamble.R")

# --- Temperature: CDS's derived daily-statistics dataset gives daily min/max/mean
# directly. 
# One request per statistic (the API takes a single `daily_statistic` per call).
for (stat in c("daily_minimum", "daily_maximum")) {

  request <- list(
    dataset_short_name = "derived-era5-single-levels-daily-statistics",
    product_type   = "reanalysis",
    variable       = "2m_temperature",
    year           = as.character(cfg$year),
    month          = sprintf("%02d", cfg$month),
    day            = cfg$days,
    daily_statistic = stat,
    time_zone      = "utc+00:00",
    frequency      = "1_hourly",
    area           = cfg$area,
    data_format    = "netcdf",
    target         = paste0("era5_temp_", sub("daily_", "", stat), ".nc")
  )

  wf_request(request, path = dir$source)
}

# --- Precipitation: total_precipitation is an accumulated variable, and CDS's
# `daily_sum` statistic is known to return nonsense for accumulated variables
# (see Presentation/WeatherPipeline.qmd). So we download the plain hourly product
# instead and sum it to daily/monthly totals ourselves in 03_time_aggreg.R. This
# dataset (unlike the daily-statistics one above) supports `grid` regridding,
# which is what actually keeps the download small and fast.
request_precip <- list(
  dataset_short_name = "reanalysis-era5-single-levels",
  product_type = "reanalysis",
  variable     = "total_precipitation",
  year         = as.character(cfg$year),
  month        = sprintf("%02d", cfg$month),
  day          = cfg$days,
  time         = sprintf("%02d:00", 0:23),
  area         = cfg$area,
  grid         = cfg$grid,
  data_format  = "netcdf",
  target       = "era5_precip_hourly.nc"
)

wf_request(request_precip, path = dir$source)
