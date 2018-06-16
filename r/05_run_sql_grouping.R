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
lsoa_type <- c(rep("soal", 9), rep("lsoa01",2))
table_names <- test$table_name
 
# Groups - Note (and interrogate) local authority movements ---------------

for(i in seq_along(years)){

dbGetQuery(con_sw,
          str_c("
SELECT year_adjust
      ,encrypted_hesid -- helpful for checks
      ,age_adjust
      ,gender
      ,utla17nm
      ,death_chapter
      ,cohort 
      ,ttd
      ,COUNT(*) as [n_adm]
      ,SUM(beddays) as [bed_days]
INTO strategicworking.defaults.aj_180614_proxdeath_grouped", years[i],
" FROM strategicworking.defaults.aj_180614_proxdeathlsoa", years[i],
" GROUP BY -- invariants
        year_adjust
        ,encrypted_hesid
        ,age_adjust
        ,gender
        ,utla17nm -- could vary during the year
        ,death_chapter
        ,cohort 
        ,ttd
        ")
        )
}

# NO PERMISSIONS TO DO THIS:
# for(i in seq_along(years)){
# 
# dbRemoveTable(con_sw, str_c("strategicworking.defaults.aj_180614_proxdeath_zgrouped", years[i]))
# 
#   }


# Quick interrogation -----------------------------------------------------

library(dbplot)
test <- tbl(con_sw, in_schema("DEFAULTS", "aj_180614_proxdeath_grouped1415")) 

test %>% count(bed_days) %>% arrange(-bed_days) 
tmp <- test %>% head(5) %>% collect

test %>% filter(year_adjust < 2014) %>% dbplot_bar(year_adjust)
# 1. a variety of odd years (but low numbers)
# 2. Good - 0.1 % lacking local authority
# 3. Good - no-one lacking a cohort


# Now check issues with local authority migration -------------------------

test %>% 
  filter(year_adjust == 2014) %>% 
  count(encrypted_hesid) %>%
  count(n) %>% 
  arrange(n)

test %>% 
  filter(year_adjust == 2014) %>% 
  count(encrypted_hesid) %>%
  arrange(desc(n))

# 28 RECORDED DUPLICATIONS:
test %>% filter(encrypted_hesid == "2BB14CBCF264A6EA5ADCE27978855261") %>% collect %>% View()
"THIS IS PROBABLY AN ERROR HESID - MANY DIFFERENT PEOPLE, NO TTD"

# 12 RECORDED DUPLICATIONS:
test %>% filter(encrypted_hesid == "E5554CA65D9E58DB68E05662A9BE3962") %>% collect %>% View()
"THIS IS PROBABLY AN ERROR HESID - MANY DIFFERENT PEOPLE, NO TTD"

# MORE LIKELY TO FIND ISSUES WITH 200/ 10K PROPLE WHO HAVE 3/2 RECORDS PER ENCRYPTED_HESID
test %>% 
  filter(year_adjust == 2014) %>% 
  count(encrypted_hesid) %>%
  filter(n < 5) %>% 
  arrange(desc(n))


test %>% filter(encrypted_hesid == "6FB418CA812897C262C0E60D7593C976") %>% collect %>% View()


"YES; It is an issue affecting 0.4% and possibly most likely in old people due move to care homes:
probably needs fixing"


test %>% filter(year_adjust< 2013) %>% collect %>% View()
"Think the year selection can be done after union-ing the tables"


table_names2 <- DBI::dbGetQuery(con_sw,
                        "SELECT *
                        FROM information_schema.tables
                        WHERE table_name  LIKE '%aj_180614_proxdeath_grouped%'
                        ") %>% 
  clean_names() %>% 
  select(table_name)

table_names2[1]

dbExecute(con_sw,
           "SELECT top 10 *
            FROM defaults.aj_180614_proxdeath_grouped0405
          ")




map_chr(years[1:10], function(x){dbExecute(con_sw,
                                           str_c("SELECT top 10 *
            FROM defaults.aj_180614_proxdeath_grouped", x, "
                                 UNION ALL "))}

str_flatten(map_chr(years, 
                    function(x){
                      str_c("SELECT * FROM defaults.aj_180614_proxdeath_grouped", x, " UNION ALL ")
                      }
                    ))
# Remove the last UNION ALL, and an INTO, and insert string into:

dbExecute(con_sw,
          "SELECT * INTO defaults.aj_180614_proxdeath_ALL FROM defaults.aj_180614_proxdeath_grouped0405 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped0506 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped0607 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped0708 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped0809 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped0910 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped1011 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped1112 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped1213 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped1314 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped1415 ")
# 41140624 rows.