##############################
"PROXIMITY TO DEATH:"
"UNION GROUPED DATASETS"
##############################

library(tidyverse)
library(dbplyr)
library(DBI)
library(odbc)

con_sw <- dbConnect(odbc(), 
                    Driver = "SQL Server", 
                    Server = "MLCSU-BI-SQL-SU", 
                    Database = "StrategicWorking", # If searching for tables must specify correct DB
                    Trusted_Connection = "True")




str_flatten(map_chr(years, 
                    function(x){
                      str_c("SELECT * FROM defaults.aj_180616_proxdeath_grouped", x, " UNION ALL ")
                    }
))
# Remove the last UNION ALL, add an INTO, and insert string into:

# last time:
# dbExecute(con_sw,
#           "SELECT * INTO defaults.aj_180614_proxdeath_ALL FROM defaults.aj_180614_proxdeath_grouped0405 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped0506 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped0607 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped0708 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped0809 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped0910 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped1011 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped1112 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped1213 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped1314 UNION ALL SELECT * FROM defaults.aj_180614_proxdeath_grouped1415 ")
# 41140624 rows.

dbExecute(con_sw,
"SELECT * 
INTO defaults.aj_180616_proxdeath_ALL 
FROM (
SELECT *  FROM defaults.aj_180616_proxdeath_grouped0405 UNION ALL SELECT * FROM defaults.aj_180616_proxdeath_grouped0506 UNION ALL SELECT * FROM defaults.aj_180616_proxdeath_grouped0607 UNION ALL SELECT * FROM defaults.aj_180616_proxdeath_grouped0708 UNION ALL SELECT * FROM defaults.aj_180616_proxdeath_grouped0809 UNION ALL SELECT * FROM defaults.aj_180616_proxdeath_grouped0910 UNION ALL SELECT * FROM defaults.aj_180616_proxdeath_grouped1011 UNION ALL SELECT * FROM defaults.aj_180616_proxdeath_grouped1112 UNION ALL SELECT * FROM defaults.aj_180616_proxdeath_grouped1213 UNION ALL SELECT * FROM defaults.aj_180616_proxdeath_grouped1314 UNION ALL SELECT * FROM defaults.aj_180616_proxdeath_grouped1415
) CTE1
WHERE (year_adjust > 2004.0 AND year_adjust < 2015.0) AND (age_adjust > -1.0) AND (NOT(cohort IS NULL))") 
# [1] 37654140
# about right - because removing large numbers in 2004 and 2015

# Interrogate -------------------------------------------------------------


test3 <- tbl(con_sw, in_schema("defaults", "aj_180616_proxdeath_ALL"))

# For reference: 
test3 %>% head(10) %>% collect %>% View("REFERENCE")

test3 %>% count(is.na(cohort)) %>% collect %>% View

# 0. FILTER YEARS
# 1. MUST REMOVE ALL WITH AGE LESS THAN ZERO.
# 2. Remove 1 NAS in COHORT
# 3. What to do about ttd == 999999
# 4. Lots of instances of high -ve and +ve bed_days! Figure out what to do with these later on.
" DONE!"



