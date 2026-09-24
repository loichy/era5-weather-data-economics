#===============================================================================
# 06_main_regression.R
# A basic regression of income on temperature, in the spirit of Deschenes &
# Greenstone (2007) / Burke & Emerick (2016): log GDP per capita on mean
# temperature, allowing a non-linear (quadratic) response.
# Reads: panel_nuts3.rds. Writes: nothing
#===============================================================================

source("scripts/00_preamble.R")

# Load and prepare panel data for regression
panel_nuts3 <- readRDS(file.path(dir$final, "panel_nuts3.rds")) |>
  filter(gdp_pc > 0) |> 
  mutate(
    temp_mean_daily_max_sq = temp_mean_daily_max^2,
    precip_total_sq = precip_total^2,
  )

# temp_mean_daily_max: the monthly mean of daily maximum temperature - one of
# the 6 temperature variables 03_time_aggreg.R computes; the others are
# available in panel_nuts3 for robustness checks.
fit <- lm(log(gdp_pc) ~ temp_mean_daily_max + temp_mean_daily_max_sq + precip_total + precip_total_sq,
          data = panel_nuts3)

print(summary(fit))

# NOTE: panel_nuts3 has ONE time period (cfg$year), so this is a cross-section,
# not a panel regression - there is no within-region variation left to identify
# a location fixed effect, and a single year cannot separate weather shocks from
# a region's permanent climate. 
# This regression does not show the effect of weather on the economy, only the
# correlation on year 2022 between the weather and the economy.
# The intention is to  demonstrate the merge and the functional form.
# The next step is to run a panel of this.
