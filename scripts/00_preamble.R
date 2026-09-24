#===============================================================================
# 00_preamble.R
# Packages, folder paths, and the pipeline's configuration (cfg).
# Every other script in scripts/ starts with source("scripts/00_preamble.R").
#===============================================================================

# If package is absent, download, if already installed, only load package 
if (!require("pacman")) install.packages("pacman")
pacman::p_load(here, ecmwfr, terra, sf, exactextractr, eurostat, dplyr, tidyr, ggplot2,
                broom, lubridate)

# dir$root: prefer ERA5_PROJECT_ROOT if set (needed on a checkout with no .Rproj/.git
# marker, e.g. a bare copy on a remote server), otherwise fall back to here::here().
dir <- list()
dir$root <- here::here()
dir$source       <- file.path(dir$root, "data", "source")
dir$intermediary <- file.path(dir$root, "data", "intermediary")
dir$final        <- file.path(dir$root, "data", "final")
dir$figures      <- file.path(dir$root, "figures")
dir$tables       <- file.path(dir$root, "tables")

for (d in dir[c("source", "intermediary", "final", "figures", "tables")]) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

# NUTS3 boundaries (outline only), in lon/lat so they overlay directly on the
# ERA5 cell-level maps in 02_visualize_raw_data.R and 03_time_aggreg.R.
nuts3_bnd <- st_read(file.path(dir$source, "NUTS_RG_20M_2024_3035.shp"), quiet = TRUE) |>
  filter(LEVL_CODE == 3) |>
  st_transform(4326) |>
  vect()

# cfg: Adjust this configuration to download data corresponding to your choics.
# Here: One month only, low spatial resolution -> the whole pipeline runs in minutes.
cfg <- list(
  year  = 2022,  # good Eurostat NUTS3-GDP coverage (see 05_prepare_panel.R)
  month = 9,     # set this to YOUR birth month
  area  = c(72, -25, 34, 45),  # bounding box for Europe: North, West, South, East
  grid  = "1.0/1.0"            # coarse regridding (native ERA5 is 0.25 deg), precip only
)
# Add in the list cfg the days in the month
cfg$days <- sprintf("%02d", seq_len(lubridate::days_in_month(cfg$month)))
# Later: adjust the pipeline for more frequent data

# CDS personal access token, gitignored (see code/ERA5_APIKey.R) - never print `key`.
source(file.path(dir$root, "code", "ERA5_APIKey_2.R"))
ecmwfr::wf_set_key(key = key_loic)
