#############################
"IMD Local Authority Summary"
#############################

library(tidyverse)
library(here)

data_slash <- function(x){
  paste0(here::here("data"), "/", x)
  
}

# url <- "https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/464464/File_10_ID2015_Local_Authority_District_Summaries.xlsx"
# destfile <- data_slash("imd_local_auth.xlsx")
# 
# tmp <- curl::curl_download(url, destfile)
# imd_la <- readxl::read_excel(destfile, sheet = 2) # other sheets for different indices.

#############################
"LOCAL AUTHORITY"
#############################

# hes_la to lsoa01 and lsoa11 from Inpatients 1617
resladst_reference <- read_csv("resladst_reference.csv") %>%
  filter(str_detect(lsoa01, "^E"))


# url <- "https://opendata.arcgis.com/datasets/3ecc1f604e0148fab8ea0b007dee4d2e_0.csv"
destfile <- data_slash("lsoa_la.csv")

#tmp <- curl::curl_download(url, destfile)
#lsoa_la <- read_csv(destfile) # other sheets for different indices.

lsoa_la <- read_csv("data/lsoa_la.csv",
                    col_types = cols_only(LAD16CD = col_guess(),
                                          LSOA11CD = col_guess())) %>% 
  distinct() %>% 
  janitor::clean_names()

# lsoa_la %>% distinct(LAD16CD) %>% View # 326 la district codes

build1 <- left_join(resladst_reference, lsoa_la, by = c("lsoa11" = "lsoa11cd")) 

#url1 <- "https://opendata.arcgis.com/datasets/41828627a5ae4f65961b0e741258d210_0.csv"
destfile1 <- data_slash("upper_tier_la.csv")

#tmp <- curl::curl_download(url1, destfile1)
upper_tier <- read_csv(destfile1)



# Upper tier selection ----------------------------------------------------
# lad <- lsoa_la %>% distinct(lad16cd)

upper_tier_la <- read_csv("data/upper_tier_la.csv", 
                          col_types = cols(FID = col_skip())) %>% 
  janitor::clean_names()

build2 <- left_join(build1, upper_tier_la, by = c("lad16cd" = "ltla17cd"))

lkp_lsoa_utla <- build2 %>% select(lsoa01, utla17nm) %>% 
  distinct()


lkp_lsoa_utla %>% count(lsoa01) %>% filter(n>1)
# lkp_lsoa_utla %>% filter(lsoa01 == "E01003242"| lsoa01 == "E01012664")
# build2 %>% filter(lsoa01 ==  "E01003242" | lsoa01 == "E01012664")
#  Will designate 3242 as Outer London as population probably won't have great effect
#  2664 as Blackpool

lkp_lsoa_utla <- lkp_lsoa_utla %>% mutate(utla17nm = ifelse(lsoa01 == "E01003242",
                                                            "Outer London",
                                                            ifelse(lsoa01 == "E01012664",
                                                                   "Blackpool", utla17nm))) 

lkp_lsoa_utla <- lkp_lsoa_utla %>% distinct()


lkp_ut_lt <- build2 %>% select(ltla17nm, lad16cd, utla17nm) %>% 
  distinct()
