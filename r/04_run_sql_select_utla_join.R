############################################################
"PROXIMITY TO DEATH:"
"join MOST RECENT local authority"
############################################################

library(tidyverse)
library(dbplyr)
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


# test <- dbGetQuery(con_sw, "select top 100 * from strategicworking.defaults.aj_180615_select_utla0405")
# dbExecute(con_sw, "drop table strategicworking.defaults.aj_180614_proxdeath_groupedv20405")


# Then run the grouping again but you want to interrogate (test) multiple records for 
# single hesid - as at the end of the group


