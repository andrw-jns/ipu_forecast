####################
"PROXIMITY TO DEATH:"
"CREATE TABLES ON DB"
####################

library(tidyverse)
library(DBI)
library(odbc)

con <- dbConnect(odbc(), 
                 Driver = "SQL Server", 
                 Server = "MLCSU-BI-SQL-SU", 
                 Database = "HESDATA", 
                 Trusted_Connection = "True")



create_year_vector <- function(start_year_dbl, number_of_years){
  
  years <- rep(start_year_dbl, number_of_years)
  years <- as.character(map2_dbl(seq_along(years), years, function(x, y){(x-1)*101 + y}))
  years <- ifelse(str_detect(years, "^[^1]"), str_c(0, years), years) # starts with anything but 1
  years
}

years <- create_year_vector(0405, 11)
lsoa_type <- c(rep("soal", 9), rep("lsoa01",2))


ip_data <- vector("list", 11)

# 3. Loop  -----------------------------------------------------------

for(i in seq_along(years)){

DBI::dbExecute(con, str_c("SELECT *,
CASE
WHEN (
DATEPART(MM, date) > DATEPART(MM, dod) 
)
THEN DATEPART(yy, date) +1
WHEN (
DATEPART(MM, date) = DATEPART(MM, dod) 
AND DATEPART(DD, date) > DATEPART(DD, dod)
)
THEN DATEPART(yy, date) +1
ELSE DATEPART(yy, date) 
END [year_adjust]

-- AND CONSEQUENTLY NEED TO ADJUST AGE_JAN_1:
,CASE
WHEN (
  DATEPART(MM, date) > DATEPART(MM, dod) 
)
THEN age_jan1 +1
WHEN (
  DATEPART(MM, date) = DATEPART(MM, dod) 
  AND DATEPART(DD, date) > DATEPART(DD, dod)
)
THEN age_jan1 +1
ELSE age_jan1
END [age_adjust]

-- ASSUMES COHORTS OF DIFFERENT SIZE ARE APPROPRIATE
, CASE
WHEN yob BETWEEN 1895 AND 1906
THEN 1895 
WHEN yob BETWEEN 1907 AND 1918
THEN 1907
WHEN yob BETWEEN 1919 AND 1930
THEN 1919
WHEN yob BETWEEN 1931 AND 1945 -- LARGER COHORT
THEN 1931
WHEN yob BETWEEN 1946 AND 1957 
THEN 1946
WHEN yob BETWEEN 1958 AND 1969 
THEN 1958
WHEN yob BETWEEN 1970 AND 1981
THEN 1970
WHEN yob BETWEEN 1982 AND 1993
THEN 1982
WHEN yob BETWEEN 1994 AND 2005
THEN 1994
WHEN yob BETWEEN 2006 AND 2017
THEN 2006
ELSE NULL
END [cohort]

,CASE
WHEN prox_to_death < 12
THEN 1
WHEN prox_to_death > 11 AND prox_to_death < 24
THEN 2
WHEN prox_to_death > 23 AND prox_to_death < 36
THEN 3
WHEN prox_to_death > 35 AND prox_to_death < 48
THEN 4
WHEN prox_to_death > 47 AND prox_to_death < 60
THEN 5
WHEN prox_to_death = 999999
THEN 999999
ELSE NULL
END [ttd]

INTO strategicworking.defaults.aj_180613_proxdeath", years[i], "  
FROM (
  SELECT 
  CASE
  WHEN -- DATEPART(YY, admidate) LIKE '19%' OR 
  DATEPART(YY, admidate) < 1990
  THEN DATEPART(YY, ip.epistart)
  ELSE DATEPART(YY, admidate)
  END [year]
  
  ,CASE
  WHEN DATEPART(YY, ip.admidate) < 1990
  THEN ip.epistart
  ELSE ip.admidate 
  END [date]
  
  ,ip.encrypted_hesid
  
  ,DATEDIFF(Y
            ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
            ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.admidate))+ '-01-01')
  ) / 365
  
  AS [age_jan1]
  
  ,CAST(right(ip.mydob, 4) AS INT) AS [yob]
  
  ,ip.sex as [gender],",
lsoa_type[i], 
" 
,CASE 
  WHEN DATEPART(YY, ip.disdate) < 2000 -- IN (1800, 1801)
  THEN DATEDIFF(dd, ip.admidate, ip.epiend)
  ELSE ISNULL(DATEDIFF(dd, ip.admidate, ip.disdate) 
              ,DATEDIFF(dd, ip.admidate, ip.epiend)
  ) 
  END [beddays]
  
  
  ,icd_chap.chapter AS [death_chapter]
  
  -- Proximity to death better done by day (datediff(yy) doesn't return expected results): 
                                            , CASE
                                            WHEN DATEDIFF(DD, ip.admidate, d.DOD) between 0 and 40000 
                                            THEN CAST(
                                            FLOOR(
                                            DATEDIFF(DD, ip.admidate, d.DOD) / 30.41   -- 30.42 = average days in a month
                                            ) AS INT													-- 30.41 tips the 365th day into the next year (FIRST DAY IS 0)
                                            ) 																			-- Note: 3.41 will cause issues around the 3 year mark (not so serious)
                                            WHEN DATEDIFF(DD, ip.admidate, d.DOD) < 0     -- Could be addressed by making prox_death a float and using ttd to select to the decimal place.
                                            THEN 999999 -- Error code will be 999999
                                            ELSE NULL 
                                            END [prox_to_death]
                                            
                                            -- ,CASE 
                                            --   WHEN DATEDIFF(YY, ip.admidate, d.DOD) between 0 and 4 
                                            --   THEN CAST(
                                            --       FLOOR(
                                            --         DATEDIFF(YY, ip.admidate, d.DOD)) AS INT
                                            --            ) 
                                            -- 	WHEN DATEDIFF(DD, ip.admidate, d.DOD) < 0
                                            --   THEN 999999 -- Error code will be 999999
                                            --   ELSE NULL 
                                            -- END [ttd]
                                            
                                            
                                            ,DOD as [dod]
                                            
                                            ----
                                            
                                            FROM [HESData].dbo.tbInpatients", years[i]," ip
                                            
                                            LEFT OUTER JOIN 
                                            (
                                            SELECT
                                            a.[Encrypted_HESID]
                                            ,a.[DOD]
                                            ,a.[CAUSE_OF_DEATH]
                                            --,a.SUBSEQUENT_ACTIVITY_FLG
                                            
                                            FROM [ONS].[HESONS].[tbMortalityto1617] a
                                            
                                            WHERE DOD > '20", str_sub(years[i], 1, 2), "-04-01'
                                            AND SUBSEQUENT_ACTIVITY_FLG IS NULL -- Ignore deaths with subseq activity.
                                            ) d
                                            ON ip.Encrypted_HESID = d.Encrypted_HESID
                                            
                                            ---
                                            LEFT JOIN StrategicWorking.dbo.aj_180613_icd10_chapter_fix icd_chap
                                            ON d.CAUSE_OF_DEATH = icd_chap.diagnosis_code
                                            
                                            
                                            
                                            WHERE 
                                            1 = 1 
                                            AND epiorder = 1
                                            AND admimeth LIKE '2%' -- EMERGENCY ADMISSIONS
              

)CTE1
                                            
                                            WHERE CTE1.age_jan1 < 110
                                            AND (CTE1.gender = 1 OR CTE1.gender = 2)
                                            AND ",
lsoa_type[i], " NOT LIKE 'W%'"
))
}
