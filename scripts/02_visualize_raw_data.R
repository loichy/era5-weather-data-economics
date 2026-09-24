#===============================================================================
# 02_visualize_raw_data.R
# Checks on the raw download: a map of one day/hour, and a time series
# at a few sample cities, for each raw variable.
# Reads: the 3 NetCDF files from data/source/. Writes: PNGs to figures/.
#===============================================================================

source("scripts/00_preamble.R")

# Put in a data frame lon et lat of 4 european cities
cities <- data.frame(
  city = c("Paris", "Berlin", "Madrid", "Rome"),
  lon  = c(2.35, 13.40, -3.70, 12.50),
  lat  = c(48.85, 52.52, 40.42, 41.90)
)
# Put this data frame in a spatial object using terra::vect 
city_pts <- terra::vect(cities, geom = c("lon", "lat"), crs = "EPSG:4326")

# Function which open downloaded data, and map data and give some time series
check_raster <- function(file, varname, unit_label) {
  
  # file <- "era5_temp_minimum.nc"
  # varname <- "temp_min"  
  # unit_label <- "K"
  
  r <- terra::rast(file.path(dir$source, file))

  # Map: first time step, in its native (Kelvin/meters) units.
  png(file.path(dir$figures, paste0("raw_map_", varname, ".png")),
      width = 7, height = 5, units = "in", res = 150)
  plot(r[[1]], main = paste("Raw", varname), col = hcl.colors(50, "viridis"))
  plot(nuts3_bnd, add = TRUE, border = "black", lwd = 0.3) # overlay NUTS3 boundaries for reference
  dev.off()

  # Time series at the sample cities, across every time step in the file.
  ts <- terra::extract(r, city_pts) |> # Extract raster cells in r closest to points in city_points 
    mutate(city = cities$city) |>
    tidyr::pivot_longer(-c(ID, city), names_to = "step", values_to = "value") |> # Put data in long format to ease plotting as time series
    mutate(step = as.integer(factor(step, levels = unique(step)))) # step variable: gives the day

  p_ts <- ggplot(ts, aes(step, value, color = city)) +
    geom_line() +
    labs(title = paste("Raw", varname, "- sample cities"), x = "time step", y = unit_label) +
    theme_minimal()
  ggsave(file.path(dir$figures, paste0("raw_timeseries_", varname, ".png")), p_ts,
         width = 7, height = 5)
}

check_raster("era5_temp_minimum.nc",  "temp_min",  "K")
check_raster("era5_temp_maximum.nc",  "temp_max",  "K")
check_raster("era5_precip_hourly.nc", "precip_hourly", "m")
