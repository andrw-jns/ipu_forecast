##############################
"PROXIMITY TO DEATH:"
"GROUP UP"
##############################

library(tidyverse)
library(DBI)
library(odbc)
library(janitor)


create_year_vector <- function(start_year_dbl, number_of_years){
  
  years <- rep(start_year_dbl, number_of_years)
  years <- as.character(map2_dbl(seq_along(years), years, function(x, y){(x-1)*101 + y}))
  years <- ifelse(str_detect(years, "^[^1]"), str_c(0, years), years) # starts with anything but 1
  years
}


con_sw <- dbConnect(odbc(), 
                 Driver = "SQL Server", 
                 Server = "MLCSU-BI-SQL-SU", 
                 Database = "StrategicWorking", # If searching for tables must specify correct DB
                 Trusted_Connection = "True")


# This would give you more information:
# test <- DBI::dbGetQuery(con,
#                " SELECT * 
#                FROM sys.Tables
#                WHERE name LIKE '%proxdeath%'
#                ")

# Extract specific tables  (based on the naming conventions (and date) of run_sql_ip_adm.R)
test <- DBI::dbGetQuery(con_sw,
                        "SELECT *
  FROM information_schema.tables
WHERE table_name  LIKE '%aj_180613_proxdeath%'
                        ") %>% 
  clean_names() %>% 
  select(table_name)


# Parameters --------------------------------------------------------------

years <- create_year_vector(0405, 11)
# lsoa_type <- c(rep("soal", 9), rep("lsoa01",2))
# table_names <- test$table_name
 
# Groups - Note (and interrogate) local authority movements ---------------

for(i in seq_along(years)){

dbGetQuery(con_sw,
          str_c("
SELECT year_adjust
      ,encrypted_hesid -- helpful for checks
      ,age_adjust
      ,gender
      ,utla
      ,death_chapter
      ,cohort 
      ,ttd
      ,COUNT(*) as [n_adm]
      ,SUM(beddays) as [bed_days]
INTO strategicworking.defaults.aj_180616_proxdeath_grouped", years[i],
" FROM strategicworking.defaults.aj_180615_select_utla", years[i],
" GROUP BY -- invariants
        year_adjust
        ,encrypted_hesid
        ,age_adjust
        ,gender
        ,utla -- fixed on the last episode
        ,death_chapter
        ,cohort 
        ,ttd
        ")
        )
}

# CAREFUL : DROPPING MULTIPLE TABLES
# for(i in seq_along(years)){
# 
# dbExecute(con_sw, str_c("drop table strategicworking.defaults.aj_180616_proxdeath_grouped", years[i]))
# 
#   }


# Quick interrogation -----------------------------------------------------

# library(dbplot)
# test <- tbl(con_sw, in_schema("DEFAULTS", "aj_180614_proxdeath_grouped1415")) 
# 
# test %>% count(bed_days) %>% arrange(-bed_days) 
# tmp <- test %>% head(5) %>% collect
# 
# test %>% filter(year_adjust < 2014) %>% dbplot_bar(year_adjust)
# 1. a variety of odd years (but low numbers)
# 2. Good - 0.1 % lacking local authority
# 3. Good - no-one lacking a cohort


# Now check issues with local authority migration -------------------------



test2 <- tbl(con_sw, in_schema("DEFAULTS", "aj_180616_proxdeath_grouped1415")) 

test2 %>% count(is.na(utla)) 

# 2. Good - Still only 0.1 % lacking local authority


test2 %>% 
  filter(year_adjust == 2014) %>% 
  count(encrypted_hesid) %>%
  arrange(desc(n)) %>% show_query()

"Still some issues with duplicates"

test2 %>% 
  filter(year_adjust == 2014) %>% 
  count(encrypted_hesid) %>%
  count(n) %>% 
  arrange(n)
  
  # 2004:
  # 1 2030489
  # 2     492
  # 3       2
  
  # 2014:
  # 1     1 2750804
  # 2     2     218
  # 3     3       3
  # 4     7       1
# 5    18       1
# 6    25       1

# 0.025% have these problems of duplication


#  For 2004: --------------------------------------------------------------

# 3 RECORDED DUPLICATIONS:
test2 %>% filter(encrypted_hesid == "FF636A26177350B769151677C4D8079D") %>% collect %>% View()
"THIS IS perhaps bad coding in early years"

"CHECK WHAT IT'S LIKE IN LATER YEARS"

# 2 RECORDED DUPLICATIONS:
test2 %>% filter(encrypted_hesid == "0CA9BC41C8443AE120465E65AD315455") %>% collect %>% View()
test2 %>% filter(encrypted_hesid == "A8DC26FC0C2787D7901D20758B2D8F2C") %>% collect %>% View()
"They seem to be age issues - different ages assigned"

# Could do the ranking operation once more? But would have to be when split into 
# calendar years. 

# 1. Before acting, check if these problems exist in later years.


# For 2014 ----------------------------------------------------------------

# 25 RECORDED DUPLICATIONS:
test2 %>% filter(encrypted_hesid == "2BB14CBCF264A6EA5ADCE27978855261") %>% collect %>% View()
test2 %>% filter(encrypted_hesid == "F29EF7D56769A54500513B49F358DA1F") %>% collect %>% View()

"CONCLUSION:"
"LATER YEARS THERE ARE CASES WHERE 1 HESID ASSIGNED TO MANY DIFFERENT PEOPLE;
A WIDE VARIETY OF AGES. AS THESE CASES ARE VERY FEW 0.008% EITHER EXCLUDING OR INCLUDING 
WILL HAVE NEGLIGIBLE EFFECT. AS HES ID IS IRRELVENT IN MODEL, THEY WILL BE TREATED AS 
INDIVIDUALS (WHICH SOME OF THEM ARE) SO LEAVE THEM IN THE DATA FOR NOW - LESS WORK. COULD
BE CHANGED AT A LATER DATE IF NECESSARY."





# Old working: -------------------------------------------------------------

# 
# test %>% 
#   filter(year_adjust == 2014) %>% 
#   count(encrypted_hesid) %>%
#   count(n) %>% 
#   arrange(n)
# 
# test %>% 
#   filter(year_adjust == 2014) %>% 
#   count(encrypted_hesid) %>%
#   arrange(desc(n))
# 
# # 28 RECORDED DUPLICATIONS:
# test %>% filter(encrypted_hesid == "2BB14CBCF264A6EA5ADCE27978855261") %>% collect %>% View()
# "THIS IS PROBABLY AN ERROR HESID - MANY DIFFERENT PEOPLE, NO TTD"
# 
# # 12 RECORDED DUPLICATIONS:
# test %>% filter(encrypted_hesid == "E5554CA65D9E58DB68E05662A9BE3962") %>% collect %>% View()
# "THIS IS PROBABLY AN ERROR HESID - MANY DIFFERENT PEOPLE, NO TTD"
# 
# # MORE LIKELY TO FIND ISSUES WITH 200/ 10K PROPLE WHO HAVE 3/2 RECORDS PER ENCRYPTED_HESID
# test %>% 
#   filter(year_adjust == 2014) %>% 
#   count(encrypted_hesid) %>%
#   filter(n < 5) %>% 
#   arrange(desc(n))
# 
# 
# test %>% filter(encrypted_hesid == "6FB418CA812897C262C0E60D7593C976") %>% collect %>% View()
# 
# 
# "YES; It is an issue affecting 0.4% and possibly most likely in old people due move to care homes:
# probably needs fixing"
# 
# 
# test %>% filter(year_adjust< 2013) %>% collect %>% View()
# "Think the year selection can be done after union-ing the tables"
# 
# 
# table_names2 <- DBI::dbGetQuery(con_sw,
#                         "SELECT *
#                         FROM information_schema.tables
#                         WHERE table_name  LIKE '%aj_180614_proxdeath_grouped%'
#                         ") %>% 
#   clean_names() %>% 
#   select(table_name)
# 
# table_names2[1]
# 
# dbExecute(con_sw,
#            "SELECT top 10 *
#             FROM defaults.aj_180614_proxdeath_grouped0405
#           ")
# 
# 
# 
