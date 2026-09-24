#===============================================================================
# 04_spatial_aggreg.R
# Spatial aggregation of the cell-level monthly weather grid onto NUTS3 regions
# using a area-weighted mean
# Reads: the per-variable .tif files in data/intermediary/, the NUTS3 shapefile.
# Writes: nuts3_weather.rds to data/intermediary/, check PNGs to figures/.
#===============================================================================

source("scripts/00_preamble.R")

# Load monthly raster
monthly_files <- list.files(dir$intermediary, pattern = "\\.tif$", full.names = TRUE)
monthly <- rast(monthly_files)

# Load nuts3 shapefile
nuts3 <- st_read(file.path(dir$source, "NUTS_RG_20M_2024_3035.shp"), quiet = TRUE) |>
  filter(LEVL_CODE == 3) |>
  st_transform(crs(monthly))  # match the raster's lon/lat CRS

# Area-weighted mean of every cell-level variable within each NUTS3 polygon.
weather_nuts3 <- lapply(names(monthly), function(v) {
  exact_extract(monthly[[v]], nuts3, fun = "mean", progress = FALSE) # Extract cells within boundaries of each geo-unit of nuts 3 and compute the weighted-area mean of cells values
}) |> 
  setNames(names(monthly)) |> 
  as.data.frame()

# Add the nuts3 variables (names, and boundaries)
nuts3_weather <- nuts3 |>
  st_drop_geometry() |>
  select(NUTS_ID, CNTR_CODE, NAME_LATN) |>
  bind_cols(weather_nuts3)

# Save data
saveRDS(nuts3_weather, file.path(dir$intermediary, "nuts3_weather.rds"))

# Check: choropleth maps of the NUTS3-level variables, zoomed to the raster's
# own extent - NUTS3 also covers overseas territories (French Guiana, Canary
# Islands, ...) far outside the Europe bounding box we downloaded, which would
# otherwise shrink the mainland down to a speck.
nuts3_map <- nuts3 |> left_join(nuts3_weather, by = c("NUTS_ID", "CNTR_CODE", "NAME_LATN"))
monthly_ext <- ext(monthly)
for (v in names(monthly)) {
  p_map <- ggplot(nuts3_map) +
    geom_sf(aes(fill = .data[[v]]), color = NA) +
    scale_fill_viridis_c(name = v, na.value = "grey90") +
    coord_sf(xlim = c(monthly_ext$xmin, monthly_ext$xmax),
             ylim = c(monthly_ext$ymin, monthly_ext$ymax), expand = FALSE) +
    labs(title = paste("NUTS3", v)) +
    theme_minimal()
  ggsave(file.path(dir$figures, paste0("nuts3_map_", v, ".png")), p_map, width = 7, height = 6)
}
