############################################################
"PROXIMITY TO DEATH:"
"CREATE LOOKUP RANKING VIEWS (MOST RECENT LOCAL AUTHORITY)"
############################################################

library(tidyverse)
library(DBI)
library(odbc)

con_sw <- dbConnect(odbc(), 
                 Driver = "SQL Server", 
                 Server = "MLCSU-BI-SQL-SU", 
                 Database = "StrategicWorking", 
                 Trusted_Connection = "True")

# RANK 1 IS THE MOST RECENT EPISODE (LATEST DATE)


create_year_vector <- function(start_year_dbl, number_of_years){
  
  years <- rep(start_year_dbl, number_of_years)
  years <- as.character(map2_dbl(seq_along(years), years, function(x, y){(x-1)*101 + y}))
  years <- ifelse(str_detect(years, "^[^1]"), str_c(0, years), years) # starts with anything but 1
  years
}

years <- create_year_vector(0405, 11)


for(i in seq_along(years)){

query_rank <- str_c("
CREATE VIEW [aj_180615_lookup_utla", years[i], "]
AS
WITH TABLO
AS (
SELECT encrypted_hesid, 
utla17nm as [utla]
 FROM (
  SELECT *
  , ROW_NUMBER() OVER (PARTITION BY encrypted_hesid ORDER BY date DESC) AS rank

  FROM [StrategicWorking].[defaults].[aj_180614_proxdeathlsoa", years[i], "] 

)x
  
WHERE x.rank = 1
)
SELECT *FROM TABLO")

dbExecute(con_sw, query_rank)
rm(query_rank)
}


# dbExecute(con_sw, "drop table [StrategicWorking].[defaults].[aj_180615_lookup_utla1415]")
# --INTO [StrategicWorking].[defaults].[aj_180615_lookup_utla", years[1], "]

# dbGetQuery(con_sw, "select top 5 * from [aj_180615_lookup_utla0910]") %>% View
# dbExecute(con_sw, "drop view [aj_180615_lookup_utla1415]")



# This will have to be used as a lookup