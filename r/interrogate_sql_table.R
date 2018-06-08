####################################
"Interrogating 1314 impatient query"
####################################

library(tidyverse)
library(dbplyr)
library(readxl)
library(DBI)
library(odbc)
library(janitor)

data_slash <- function(x){
  paste0(here::here("data"), "/", x)
}


con <- dbConnect(odbc(), 
                 Driver = "SQL Server", 
                 Server = "MLCSU-BI-SQL-SU", 
                 Database = "StrategicWorking", 
                 Trusted_Connection = "True")


# sql_style <- DBI::dbGetQuery(con,
#                              "SELECT TOP 5 *
#                              FROM HESData.dbo.tbInpatients1516
#                              "
#)

# plyr::db_list_tables(con) # it would help if this worked for other schemas

test <- tbl(con, in_schema("DEFAULTS", "aj_180607_proxdeath1314")) 

tmp <- test %>% head(100000) %>% collect

# RECOMMMENDATIONS
# 1. date is superfluous
# 2. exclude all those with age over 110
# 3. excl gender not 1 or 2
# 4.

names(tmp)

tmp %>% count(ttd)
tmp %>% count(age_jan1) %>% head 
tmp %>% count(age_jan1) %>% tail(10) 
# Based on 100k sample:
# - number of rows with age_jan1 of 200+ -presume 1800, 1801 dob issue (0.2%)
"Null startage - will have to exclude"
# - have no lsoa (0.9%)
"Will have to exclude"
# - 3 with beddays over 365. NAs = 91
"may have to exclude"
# - 174 with yob 1800 means cohort will be affected
"Will have to exclude"
# - but there are 8 more who are not given a cohort for some reason. 
# (look at cohort definition to assess)


# Investigate misaligned ttds (fixed at SQL source) ----------------------------

"Ultimately this needs to be formatted to feed the regression model"

# tmp %>% count(year, encrypted_hesid) %>% arrange(-n)
# tmp %>% count(year, encrypted_hesid, ttd) %>% arrange(-n)

# There are still a number of hesids which have 2 ttd. Is this based on year?
# still 500 or so more even with year taken into account

# tmp %>% filter(encrypted_hesid == "AFD414FAD43EF0F3CA50EE7875B32F01")

# Find those ecrypted hesids who have multiple ttd
"FORWARD ASSIGNMENT WORKED! - ONLY A HANDFUL OF RECORDS TO INVESTIGATE"

tmp %>% group_by(encrypted_hesid, year_adjust, ttd) %>% summarise(n()) %>% 
  filter(year_adjust == 2014) %>% 
  group_by(encrypted_hesid) %>% 
  summarise(n = n()) %>% 
  arrange(-n) %>%
 View("here")

# 524 in 2013
# 38  in 2014
# Have 2 ttds given same hesid and year

"There are 4 anomalies based on the 30.41 principle not extending to 365*3 (years)"

# CHECK ANOMALIES:
tmp %>%
  filter(encrypted_hesid == "722E431165BE6729C90A129716D177D5") %>%
  select(year, date, age_jan1, prox_to_death, dod, year_adjust, age_adjust, ttd) %>%
  View("anom")


# Investigate the possibility of estimated ttd ----------------------------
non_deaths <- tmp %>% 
  filter(is.na(ttd))

###
"Life expectancy can be found by age and gender (ONS), and then multiplied by a factor based on
life expectancy for upper tier local authorities?"
"A join?"
###
"Can get LA and Gender, but not age. Assume every cohort from now on dies at the same age:"


# Try a basic one first of all: just gender and location:
# The issue of being an xls file format that readxl currently doesn't read 

url <- "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/birthsdeathsandmarriages/lifeexpectancies/datasets/lifeexpectancyatbirthandatage65bylocalareasinenglandandwalesreferencetable1/current/corrected201214referencetable1finalnewtcm77422242tcm77422242.xls"
destfile <- data_slash("life_exp.xls")

curl::curl_download(url, destfile)


life_exp_m <- read_excel("data/life_exp1.xlsx", 
                         sheet = "E&W LAs at birth - M", skip = 7)

life_exp_f <- read_excel("data/life_exp1.xlsx", 
                        sheet = "E&W LAs at birth - F", skip = 7)


tmp11_m <- life_exp_m %>% 
  clean_names() %>% 
  select(1,3,25) %>% 
  filter(!str_detect(area_code, "^E1")) %>% 
  filter(str_detect(area_code, "^E")) %>% 
  rename(life_m = x2012_2014)


tmp11_f <- life_exp_f %>% 
  clean_names() %>% 
  select(1,3,25) %>% 
  filter(!str_detect(area_code, "^E1")) %>% 
  filter(str_detect(area_code, "^E")) %>% 
  rename(life_f = x2012_2014)

life_exp_all <- left_join(tmp11_m, tmp11_f, by = c("area_code", "x_1")) %>% 
  mutate_at(vars(starts_with("life")), funs(as.numeric)) %>% 
  mutate_at(vars(starts_with("life")), funs(floor))

# Note isles of scilly and city of london have no values.
