#############################
"LOAD"
"POPULATION PROJECTIONS"
#############################

library(readr)
#library(ipu)

data_slash <- function(x){
  paste0(here::here("data"), "/", x)
  }


url <- "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationprojections/datasets/localauthoritiesinenglandz1/2014based/snppz1population.zip"
destfile <- data_slash("pop_projections.zip")

curl::curl_download(url, destfile)
# walk(file_names, unzip)
unzip(destfile)

# Remember to remove "all ages"!

snpp_f_pop <- read_csv(data_slash("2014 SNPP Population females.csv"))
snpp_m_pop <- read_csv(data_slash("2014 SNPP Population males.csv"))

test2 <- snpp_f_pop %>% 
  gather(year, pop, starts_with("2")) %>% 
  filter(!AGE_GROUP == "All ages",
         !year == 2014)
# can probably just add pop to death dataset (or vice versa)

unique(test2$)

glimpse(test2)
glimpse(test)
