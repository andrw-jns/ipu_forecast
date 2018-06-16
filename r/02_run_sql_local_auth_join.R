##############################
"PROXIMITY TO DEATH:"
"JOIN LOCAL AUTH TO DB TABLES"
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


years <- create_year_vector(0405, 11)

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

# Loop --------------------------------------------------------------------


for(i in seq_along(test$table_name)){
  
  dbExecute(con_sw,
            str_c("SELECT *
                  INTO strategicworking.defaults.aj_180614_proxdeathlsoa", years[i],
                  " FROM STRATEGICWORKING.DEFAULTS.",
                  test$table_name[i],
                  " i 
                  LEFT JOIN (SELECT lsoa01 as [placeholder]
                  ,utla17nm
                  FROM STRATEGICWORKING.dbo.aj_180614_lookup_lsoa_to_la) ii
                  ON i.", lsoa_type[i] ," = ii.placeholder"
                  
            ))
  
}




