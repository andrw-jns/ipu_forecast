############################################################
"PROXIMITY TO DEATH:"
"join MOST RECENT local authority"
############################################################

library(tidyverse)
library(DBI)
library(odbc)

con_sw <- dbConnect(odbc(), 
                    Driver = "SQL Server", 
                    Server = "MLCSU-BI-SQL-SU", 
                    Database = "StrategicWorking", 
                    Trusted_Connection = "True")


create_year_vector <- function(start_year_dbl, number_of_years){
  
  years <- rep(start_year_dbl, number_of_years)
  years <- as.character(map2_dbl(seq_along(years), years, function(x, y){(x-1)*101 + y}))
  years <- ifelse(str_detect(years, "^[^1]"), str_c(0, years), years) # starts with anything but 1
  years
}

years <- create_year_vector(0405, 11)


for(i in seq_along(years)){

query_join_utla <- str_c(
"SELECT * 
INTO strategicworking.defaults.aj_180615_select_utla", years[i],
" FROM strategicworking.defaults.aj_180614_proxdeathlsoa", years[i],
" a
LEFT JOIN ( SELECT encrypted_hesid as hesid, utla
FROM [aj_180615_lookup_utla", years[i],
"] ) b
 ON a.encrypted_hesid = b.hesid")

dbExecute(con_sw, query_join_utla)
rm(query_join_utla)
}


test <- dbGetQuery(con_sw, "select top 100 * from strategicworking.defaults.aj_180615_select_utla0405")
#dbExecute(con_sw, "drop table strategicworking.defaults.aj_180615_select_utla0506")
# Then run the grouping again but you want to interrogate (test) multiple records for 
# single hesid - as at the end of the group


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
                 INTO strategicworking.defaults.aj_180614_proxdeath_groupedv20405
FROM strategicworking.defaults.aj_180615_select_utla0405
GROUP BY -- invariants
year_adjust
,encrypted_hesid
,age_adjust
,gender
,utla
,death_chapter
,cohort 
,ttd
")
        )


library(dbplyr)
test2 <- tbl(con_sw, in_schema("DEFAULTS", "aj_180614_proxdeath_groupedv20405")) 

test2 %>% count(is.na(utla)) %>% arrange(-bed_days) 

# 2. Good - Still only 0.1 % lacking local authority


# Now check issues with local authority migration -------------------------


test2 %>% 
  filter(year_adjust == 2004) %>% 
  count(encrypted_hesid) %>%
  arrange(desc(n))

"Still some issues with duplicates"

test2 %>% 
  filter(year_adjust == 2004) %>% 
  count(encrypted_hesid) %>%
  count(n) %>% 
  arrange(n)

# 1 2030489
# 2     492
# 3       2

# 0.025% have these problems of duplication

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