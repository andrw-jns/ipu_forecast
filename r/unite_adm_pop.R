#################################
"UNITE ADMISSIONS AND POPULATION"
#################################

library(tidyverse)

simple_1314 <- read_csv("data/simple_1314.csv", 
                        col_types = cols(cause_of_death = col_skip(), 
                                         date = col_skip(), prox_to_death = col_skip(), 
                                         yob = col_skip()),
                        na = "NULL")


simple_1415 <- read_csv("data/simple_1415.csv", 
                        col_types = cols(cause_of_death = col_skip(), 
                                         date = col_skip(), prox_to_death = col_skip(), 
                                         yob = col_skip()),
                        na = "NULL")

one_2014 <- bind_rows(simple_1314, simple_1415) %>% 
  filter(year == 2014)


one_2014 <- one_2014 %>% left_join(lkp_lsoa_utla, by = "lsoa01") 

collate_2014 <- one_2014 %>% 
  group_by(year, encrypted_hesid, age_jan1, gender, cohort, ttd, utla17nm) %>% 
  summarise(n_adm = n(), beddays = sum(beddays))
  
check_collate <-  one_2014 %>% 
  group_by(year, encrypted_hesid, age_jan1, gender, cohort, utla17nm) %>% #, age_jan1, gender, cohort, ttd, utla17nm) %>% 
  summarise()

# Across the two datasets:
with_enc <- nrow(check_collate)
with_enc_yr  <- nrow(check_collate) # 600 have different years of births
with_enc_yr_gend_cohort <- nrow(check_collate) 
with_enc_yr_gend_cohort_utla <- nrow(check_collate) # 30000 have different utla
# leaving approx 50,000 with different ttd in years. (this is probably a fact with years, too)

# 1. need a way of selecting the most recent dob and lsoa01 #
"do the whole binding in SQL?"
# 2. How reasonable is it to have the same person within the same year having 2 ttd?
"Is it fine if we have one big dataset? No"

"Bring date of death through"

