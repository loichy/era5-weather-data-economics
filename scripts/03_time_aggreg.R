#===============================================================================
# 03_time_aggreg.R
# Basic weather-variable computation at the grid-cell level: sum hourly
# precipitation to daily totals, then collapse the whole month to one value per
# cell (mean/min/max of both the daily-minimum and daily-maximum series, plus
# total precipitation - 7 variables in all).
# Reads: the 3 NetCDF files from data/source/.
# Writes: one .tif per monthly variable to data/intermediary/, check PNGs to figures/.
#===============================================================================

source("scripts/00_preamble.R")

temp_min_daily  <- terra::rast(file.path(dir$source, "era5_temp_minimum.nc"))
temp_max_daily  <- terra::rast(file.path(dir$source, "era5_temp_maximum.nc"))
precip_hourly   <- terra::rast(file.path(dir$source, "era5_precip_hourly.nc"))

# Hourly -> daily: sum every 24 consecutive hourly layers into one daily total.
n_days <- nlyr(temp_min_daily) # Get number of days in the raster
# Apply the sum function to a subset of layers belonging to the same days in the precipitation raster
precip_daily <- terra::tapp(precip_hourly, index = rep(seq_len(n_days), each = 24), fun = "sum")

# Check: the newly-computed daily precipitation series at a few sample cities.
cities <- data.frame(
  city = c("Paris", "Berlin", "Madrid", "Rome"),
  lon  = c(2.35, 13.40, -3.70, 12.50),
  lat  = c(48.85, 52.52, 40.42, 41.90)
)
city_pts <- vect(cities, geom = c("lon", "lat"), crs = "EPSG:4326")

precip_ts <- terra::extract(precip_daily, city_pts) |>
  mutate(city = cities$city) |>
  tidyr::pivot_longer(-c(ID, city), names_to = "day", values_to = "precip_m") |>
  mutate(day = as.integer(factor(day, levels = unique(day))))

p_precip_ts <- ggplot(precip_ts, aes(day, precip_m, color = city)) +
  geom_line() +
  labs(title = "Daily total precipitation - sample cities", x = "day of month", y = "m") +
  theme_minimal()
ggsave(file.path(dir$figures, "daily_precip_timeseries.png"), p_precip_ts, width = 7, height = 5)

# Collapse the month to one value per cell. temp_min_daily and temp_max_daily
# share one grid (ERA5's native 0.25 deg - the derived daily-statistics dataset
# has no `grid` option, see 01_download.R), so these 6 combine into one SpatRaster.
temp_native <- c(
  terra::app(temp_min_daily, fun = "mean"),
  terra::app(temp_min_daily, fun = "min"),
  terra::app(temp_min_daily, fun = "max"),
  terra::app(temp_max_daily, fun = "mean"),
  terra::app(temp_max_daily, fun = "min"),
  terra::app(temp_max_daily, fun = "max")
)
# Temp native is a raster with the 0.25° x 0.25° resolution and 6 layers for 6 temperature monthly statistics

names(temp_native) <- c("temp_mean_daily_min", "temp_min_daily_min", "temp_max_daily_min",
                         "temp_mean_daily_max", "temp_min_daily_max", "temp_max_daily_max")

# Prepare precipitations
precip_total <- terra::app(precip_daily, fun = "sum")
names(precip_total) <- "precip_total"

# Note that precip_total is on a different grid (regridded to cfg$grid, 1 deg, when
# downloaded - see 01_download.R). If you want to put temperature on
# the same grid resolution as precipitations, resample the temperature layers onto
# precip's (coarser) grid first.
temp_resampled <- terra::resample(temp_native, precip_total, method = "bilinear")

# Check resampling
plot(temp_native[[1]], col = hcl.colors(50, "viridis"))
plot(temp_resampled[[1]], col = hcl.colors(50, "viridis"))

# Single Raster object with all layers containing the weather data
monthly <- c(temp_resampled, precip_total)

# Write one raster file per monthly variable in the intermediary data folder.
for (v in names(monthly)) {
  terra::writeRaster(monthly[[v]], file.path(dir$intermediary, paste0(v, ".tif")), overwrite = TRUE)
}

# Check: maps of the final monthly values.
for (v in names(monthly)) {
  png(file.path(dir$figures, paste0("monthly_map_", v, ".png")),
      width = 7, height = 5, units = "in", res = 150)
  plot(monthly[[v]], main = paste("Monthly", v, "- cell level"), col = hcl.colors(50, "viridis"))
  plot(nuts3_bnd, add = TRUE, border = "black", lwd = 0.3) # overlay NUTS3 boundaries for reference
  dev.off()
}
