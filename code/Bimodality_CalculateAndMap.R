## Bimodality_CalculateAndMap.R

source(file.path("code", "paths+packages.R"))

# load gage info for mapping
gage_info <- read_csv(file.path("data", "gage_info.csv"))
sf_gages <-
  gage_info |> 
  sf::st_as_sf(coords = c("dec_long_va", "dec_lat_va"), crs = 4326) 

# load state map
states <- map_data("state")

# load flow stats
df_mo_all <- read_csv(file.path("data", "HydroSignatures_Monthly.csv"))

# calculate bimodality stats by gage
df_bi <-
  df_mo_all |> 
  group_by(gage_ID) |> 
  summarize(n_mo = sum(is.finite(prc_noflow)),
            prc_lt10 = sum(prc_noflow < 0.1)/n_mo,
            prc_gt90 = sum(prc_noflow > 0.9)/n_mo,
            prc_lt10.gt90 = prc_lt10 + prc_gt90)

# join and pivot to long form for mapping
sf_bi <- left_join(sf_gages, df_bi, by = "gage_ID")
sf_bi_long <- pivot_longer(sf_bi, starts_with("prc_"), 
                           names_to = "signature", values_to = "prc")

# map
ggplot() +
  geom_polygon(data = states, aes(x = long, y = lat, group = group), fill = NA, color = col.gray) +
  geom_sf(data = sf_bi_long, aes(color = prc)) +
  facet_wrap(~signature, nrow = 2, 
             labeller = as_labeller(c("prc_gt90" = ">90% no-flow",
                                      "prc_lt10" = "<10% no-flow",
                                      "prc_lt10.gt90" = "<10% or >90% no-flow"))) +
  scale_color_viridis_c(name = "Percent of Months", limits = c(0, 1)) +
  theme(legend.position = "bottom")
ggsave(file.path("plots", "Bimodality_MapMonthlyPrc.png"),
       width = 190, height = 130, units = "mm")

# map gages that have high prc_lt10 and prc_gt90
both_prc_thres <- 0.25
sf_bi$bimodal <- (sf_bi$prc_lt10 > both_prc_thres) & (sf_bi$prc_gt90 > both_prc_thres)

ggplot() +
  geom_polygon(data = states, aes(x = long, y = lat, group = group), fill = NA, color = col.gray) +
  geom_sf(data = sf_bi, aes(color = bimodal)) +
  scale_color_manual(name = "Bimodal?",
                     values = c("FALSE" = col.cat.blu, "TRUE" = col.cat.red)) +
  theme(legend.position = "bottom")
ggsave(file.path("plots", "Bimodality_MapBimodal.png"),
       width = 150, height = 100, units = "mm")

# plot bimodality distribution as a function of drainage area
ggplot(sf_bi, aes(x = drain_sqkm, color = bimodal)) +
  stat_ecdf() +
  scale_y_continuous(name = "Percent of gages") +
  scale_color_manual(name = "Bimodal?",
                     values = c("FALSE" = col.cat.blu, "TRUE" = col.cat.red))
ggsave(file.path("plots", "Bimodality_ECDFBimodal.png"),
       width = 120, height = 100, units = "mm")
