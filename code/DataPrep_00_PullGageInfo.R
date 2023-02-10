## DataPrep_00_PullGageInfo.R
# This script is intended to pull necessary data from the IntermittencyTrends repo,
# for example related to the gage IDs and characteristics.

source(file.path("code", "paths+packages.R"))

# get gage mean stats
gage_info <- read_csv("https://raw.githubusercontent.com/dry-rivers-rcn/IntermittencyTrends/master/results/00_SelectGagesForAnalysis_GageSampleMean.csv")

# join and save
write_csv(gage_info, file.path("data", "gage_info_no0GAGEID.csv"))
