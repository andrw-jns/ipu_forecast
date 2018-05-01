#############################
"LOAD"
"POPULATION ESTIMATES"
#############################

"updates available end may 2018"

library(tidyverse)
library(readxl)  
library(rvest)  
library(here)
#library(fs)


# Functions ---------------------------------------------------------------

read_new_format <- function(file, year, gender){
  read_excel(file,
             sheet = paste0("Mid-", year, " ", gender),
             skip = 3)
}


clean_new_format <- function(df, year, gender){
  df %>%
    janitor::clean_names() %>%
    filter(!is.na(area_names),
           str_detect(area_codes, "^E")) %>%
    mutate(year = year, gender = ifelse(gender == "Males", 1, 2)) %>%
    select(year, gender, everything(), -x_1, -all_ages) %>% 
    rename(lad11cd = area_codes, lad11nm = area_names)
}


gather_new_format <-  function(df){
  df %>%
    gather(age, pop, starts_with("x")) %>%
    mutate(age = as.integer(str_replace(.$age, "x", "")))
}

load_new_format <- function(file, year, gender){
  read_new_format(file, year, gender) %>%
    clean_new_format(year, gender) %>%
    gather_new_format()
}


# load_new_format <- function(file, year, gender){ # gender must have initial CAP
#   read_excel(file,
#              sheet = paste0("Mid-", year, " ", gender),
#              skip = 3) %>%
#     janitor::clean_names() %>%
#     filter(!is.na(area_names),
#            str_detect(area_codes, "^E")) %>%
#     mutate(yr = year, gender = gender) %>%
#     select(yr, gender, everything(), -x_1, -all_ages) %>%
#     gather_new_format()
# }


data_slash <- function(x){
  paste0(here::here("data"), "/", x)
  
}


# Download, unzip ---------------------------------------------------------

# url_pop <- "https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates"
url_root <- "https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates/"

url_suffixes <- c("mid2016sape19dt1/sape19dt1mid2016lsoasyoaestimates.zip",    
                  "mid2015sape18dt1/sape18dt1mid2015lsoasyoaestimates.zip",    
                  "mid2014/rft-lsoa-formatted-table-2014.zip" ,
                  "mid2013/rft-lsoa-formatted-table-2013.zip",
                  "mid2012/rftlsoaformattedtable.zip",
                  # these include 2011:
                  "mid2002tomid2010females/rftlsoaunformattedtablefemales.zip",
                  "mid2002tomid2010males/rftlsoaunformattedtablemales.zip"
)

urls_full <- paste0(url_root, url_suffixes)

zips_to_create <- data_slash(str_replace_all(url_suffixes, "/", ""))

# download:
walk2(urls_full, zips_to_create, curl::curl_download)

# unzip:
walk2(zips_to_create, here("data"), function(x, y){unzip(x, exdir = y)})

# file_delete(file_names)


# Loading -----------------------------------------------------------------

post_2011_files <- list.files(here("data"), pattern = "SAPE1|mid-2012") 
post_2011_years <- str_extract(post_2011_files, "[0-9]{4}")


# list to work with pmap 
new_format_list <- list(file   = data_slash(rep(post_2011_files, 2)),
                        year   = rep(post_2011_years, 2),
                        gender = c(rep("Females", 5), 
                                   rep("Males", 5)))


# estimates_new <- pmap(new_format_list, load_new_format)
estimates_new <- pmap_df(new_format_list, load_new_format)



# Pre 2011 ----------------------------------------------------------------

pre_2011_years <- as.character(seq(2002, 2011))


f_file1 <- data_slash(list.files(here("data"), "-females-mid2002"))
f_file2 <- data_slash(list.files(here("data"), "-females-mid2007"))

m_file1 <- data_slash(list.files(here("data"), "-males-mid2002"))
m_file2 <- data_slash(list.files(here("data"), "-males-mid2007"))

# tibble to feed to map() 
old_format <- tibble(file = c(rep(f_file1, 5),
                              rep(f_file2, 5),
                              rep(m_file1, 5),
                              rep(m_file2, 5)),
                     year = rep(pre_2011_years, 2)) 


# str_detect(old_format_tibble$file, "-males")
# str_detect(old_format_tibble$file, "females")


read_old_format <- function(file, year){
  data <- read_excel(file,
             sheet = paste0("Mid-", year)
  ) %>%
    janitor::clean_names() %>% 
    group_by(lad11cd, lad11nm) %>%
    filter(str_detect(lad11cd, "^E")) %>% 
    summarise_at(vars(starts_with("f"), starts_with("m")),
                 funs(sum)) %>%
    mutate(gender = as.integer(ifelse(str_detect(file, "-males"),
                           "1", "2")),
           year   = year) %>%
    #mutate(gender = as.integer(gender)) %>% 
    select(year, gender, everything()) 
  
  if(str_detect(file, "-males")){
    data <- data %>% 
      gather(age, pop, starts_with("m")) %>% 
      mutate(age = as.integer(str_replace_all(age, "m|plus", "")))
    } else {
    data <- data %>% 
      gather(age, pop, starts_with("f")) %>% 
      mutate(age = as.integer(str_replace_all(age, "f|plus", "")))
  }
 data
}


# test on smaller df:
# test_old      <- map2_df(old_format$file[c(1)], old_format$year[c(1)], read_old_format)

# all <- bind_rows(test_old, estimates_new)

# all %>% ungroup %>% count(year)

# estimates_old <- map2(old_format$file, old_format$year, read_old_format)
# or, in one df:
estimates_old <- map2_df(old_format$file, old_format$year, read_old_format)

estimates_all <- bind_rows(estimates_old, estimates_new)

saveRDS(estimates_all, data_slash("estimates_all.RDS"))

test <- read_rds(data_slash("estimates_all.RDS"))

# Quick checks seem to be as expected:
ggplot(estimates_all %>%
         filter(gender == 2| gender == 1,
                lad11nm == "Birmingham",
                age == 0 | age == 90),
       aes(year, pop, group = interaction(age, gender),
           colour =interaction(age, gender)))+
  geom_point()+
  geom_line()

# Follow a cohort:
ggplot()+
  geom_point(data = estimates_all %>%
               filter(gender == 2,
                      lad11nm == "Kensington and Chelsea",
                      age == 0,
                      year == 2010),
            aes(year, pop))+
  geom_point(data = estimates_all %>%
               filter(gender == 2, 
                      lad11nm == "Kensington and Chelsea",
                      age == 1,
                      year == 2011),
            aes(year, pop))+
  geom_point(data = estimates_all %>%
               filter(gender == 2, 
                      lad11nm == "Kensington and Chelsea",
                      age == 2,
                      year == 2012),
            aes(year, pop))+
  geom_point(data = estimates_all %>%  
               filter(gender == 2, 
                      lad11nm == "Kensington and Chelsea",
                      age == 3,
                      year == 2013),
             aes(year, pop))
  
  

  
  # what needs to happen next is...
  
  # reshape and join to deprivation. 
  # Test this data by examining df and plotting. 
  # Ultimately subtract from numbers in the HES query.
  
  # Make a package. 
  # Do some more exploring around purr Fay and Bryan
  # Web apis and scraping.
