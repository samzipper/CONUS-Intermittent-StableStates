## DataPrep_01_CalculateHydroSignatures.R
# This script is intended to load daily streamflow data and calculate 
# some hydrologic signatures.

source(file.path("code", "paths+packages.R"))

# load gage info
gage_info <- read_csv(file.path("data", "gage_info_no0GAGEID.csv"))

# get file names from daily streamflow data folder
fnames <- list.files(file.path(dir_data, "daily_data_just_flow"))

# because the gage_ID field in gage_info drops the leading 0, have to do the
# same to figure out what files to load
gids <- str_sub(fnames, end = -5)
gids_no0 <- as.numeric(gids)

# loop through gage IDs, load file, calculate metrics, join to output data frame
gage_info$USGS_ID <- NaN
for (i in 1:length(gage_info$gage_ID)){
  # figure out gage ID and file name
  g <- gage_info$gage_ID[i]
  i_g <- which(gids_no0 == g)
  
  if (length(i_g)==0) stop("gage ID not found in daily data files")

  # add real gage ID as USGS_ID field
  gage_info$USGS_ID[i] <- gids[i_g]

  # load daily data and extract discharge
  g_daily <- 
    read_csv(file.path(dir_data, "daily_data_just_flow", fnames[i_g]), col_types = cols()) |> 
    rename(gage_ID = site_no, Q = X_00060_00003) |> 
    dplyr::select(gage_ID, Date, Q) |> 
    mutate(Q_rounded = round(Q, 1),
           year = year(Date),
           month = month(Date))
  
  # summarize by year/month
  g_monthly <- 
    g_daily |> 
    group_by(gage_ID, year, month) |> 
    summarize(n_days_data = sum(is.finite(Q_rounded)),
              n_noflow = sum(Q_rounded == 0, na.rm = T),
              prc_noflow = round(n_noflow/n_days_data, 3)) |> 
    filter(n_days_data > 25)  # only retain monthts with at least 25 days of data
  
  # select output
  g_mo_out <- dplyr::select(g_monthly, gage_ID, year, month, prc_noflow, n_days_data)
  
  # build overall data frame
  if (i == 1){
    df_mo_all <- g_mo_out
  } else {
    df_mo_all <- bind_rows(df_mo_all, g_mo_out)
  }
 
  print(paste0(i, " complete, ", Sys.time()))
   
}

# save output
write_csv(gage_info, file.path("data", "gage_info.csv"))
write_csv(df_mo_all, file.path("data", "HydroSignatures_Monthly.csv"))
