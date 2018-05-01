#############################
"LOAD"
"DEATH PROJECTIONS"
#############################

library(tidyverse)
library(readr)
# library(ipu)
#library(fs)


data_slash <- function(x){
  paste0(here::here("data"), "/", x)
}


url <- "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationprojections/datasets/deathsz4/2014based/snppz4deaths.zip"
destfile <- data_slash("death_projections.zip")

curl::curl_download(url, destfile)
unzip(destfile)

snpp_f_deaths <- read_csv(data_slash("2014 SNPP Deaths females.csv"))
snpp_m_deaths <- read_csv(data_slash("2014 SNPP Deaths males.csv"))

test <- snpp_f_deaths %>% 
  gather(year, deaths, starts_with("2")) %>% 
  filter(!AGE_GROUP == "All ages")

