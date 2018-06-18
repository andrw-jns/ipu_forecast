/* TEST CREATE VIEW TO MASK COMPLEXITY */

USE [StrategicWorking]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [vw_prx_death_tracker] AS 


 -- SELECT THE REQUIRED INFO FROM DEATHS AND ADMISSIONS FOR MANY YEARS OF ADMISSIONS
 -- FOR THOSE DYING IN THE CALENDAR YR 2010
 -- GO BACK AS MANY YEARS AS THERE ARE TTD YEARS
 
  SELECT *
  ,CASE
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
  
  -- AND CONSEQUENTLY NEED TO ADJUST AGE_JAN_1
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

	  
	FROM(
	            SELECT TOP (100) --[File]
                  deaths.[encrypted_hesid]

				  ,DATEDIFF(Y
                           ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                           ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.admidate))+ '-01-01')
                            ) / 365
  
                AS [age_jan1]
	             
	            ,ip.sex as [gender]
	            ,ip.soal -- need correct type and to join to la 
	             
	            ,CASE
  					WHEN DATEPART(YY, ip.admidate) < 1990
  					THEN ip.epistart
  					ELSE ip.admidate 
  				END [date]
				  
				,CAST(right(ip.mydob, 4) AS INT) AS [yob]

                ,[DOD]
	  			
				,icd_chap.chapter AS [death_chapter]
				
				, CASE
        			WHEN DATEDIFF(DD, ip.admidate, deaths.DOD) between 0 and 40000 
        			THEN CAST(
        			  FLOOR(
        			    DATEDIFF(DD, ip.admidate, deaths.DOD) /30.41 -- average days in a month
        			            ) AS INT
        			       )
        			WHEN DATEDIFF(DD, ip.admidate, deaths.DOD) < 0
        			THEN 999999 -- Error code will be 999999
        			ELSE NULL 
   				END [prox_to_death]
	  

	
                 --,[DOR]
                 --,[RESSTHA]
                 --,[RESPCT]
         FROM [ONS].[HESONS].[tbMortalityto1617] deaths
  

  LEFT JOIN StrategicWorking.dbo.aj_180613_icd10_chapter_fix icd_chap
                                            ON deaths.CAUSE_OF_DEATH = icd_chap.diagnosis_code
                                            

  -- JOIN TO ADMISSIONS UPTO 5 CALENDAR YEARS BACK(MIN YEAR WILL BE 0506 FOR 2006)
  -- FOR 2010 INVOLVES 1011, 0910, 0809, 0708, 0607, 0506 
  -- ie. COMPLETE 2010, 2009, 2008, 2007, 2006, 
  -- ANY OTHER DEATHS GO IN UNKNOWN TTD CATEGORY.
  -- NOTE: IS TTD MORE THAN 5 YEARS SIGNIFICANT?
  LEFT JOIN (
			SELECT [encrypted_hesid]
				   ,[disdate]
				   ,[epiend]
				   ,[epistart]
				   ,[sex]
				   ,[soal]
				   ,[mydob]
				   ,[admidate]
			FROM 
			[HESDATA].[DBO].[tbinpatients1011]
			WHERE 
			  1 = 1 
			  AND epiorder = 1
			  AND admimeth LIKE '2%' 
			
			UNION ALL

			SELECT  [encrypted_hesid]
			 		,[disdate]
			 		,[epiend]
			 		,[epistart]
					,[sex]
					,[soal]
					,[mydob]
					,[admidate]
			 FROM 
			 [HESDATA].[DBO].[tbinpatients0910]
			 WHERE 
			   1 = 1 
			   AND epiorder = 1
			   AND admimeth LIKE '2%' 

			UNION ALL
			  
			SELECT [encrypted_hesid]
			 		,[disdate]
			 		,[epiend]
			 		,[epistart]
					,[sex]
					,[soal]
					,[mydob]
					,[admidate]
			FROM 
			[HESDATA].[DBO].[tbinpatients0809]
			WHERE 
			   1 = 1 
			   AND epiorder = 1
			   AND admimeth LIKE '2%'

			UNION ALL
			  
			SELECT [encrypted_hesid]
			 		,[disdate]
			 		,[epiend]
			 		,[epistart]
					,[sex]
					,[soal]
					,[mydob]
					,[admidate]
			FROM 
			[HESDATA].[DBO].[tbinpatients0708]
			WHERE 
			   1 = 1 
			   AND epiorder = 1
			   AND admimeth LIKE '2%'
			  
			--UNION ALL
			  
			-- SELECT [encrypted_hesid]
			--  		,[disdate]
			--  		,[epiend]
			--  		,[epistart]
			-- 		,[sex]
			-- 		,[soal]
			-- 		,[mydob]
			-- 		,[admidate]
			-- FROM 
			-- [HESDATA].[DBO].[tbinpatients0607]
			-- WHERE 
			--    1 = 1 
			--    AND epiorder = 1
			--    AND admimeth LIKE '2%'
			
			-- UNION ALL
			  
			-- SELECT [encrypted_hesid]
			--  		,[disdate]
			--  		,[epiend]
			--  		,[epistart]
			-- 		,[sex]
			-- 		,[soal]
			-- 		,[mydob]
			-- 		,[admidate]
			-- FROM 
			-- [HESDATA].[DBO].[tbinpatients0506]
			-- WHERE 
			--    1 = 1 
			--    AND epiorder = 1
			--    AND admimeth LIKE '2%'

			) ip
   ON deaths.encrypted_hesid = ip.encrypted_hesid
   -- FOR DEATH IN CALENDAR YEAR:
   WHERE (DOD >= '2010-01-01' AND DOD < '2011-01-01')
) CTE1

 WHERE CTE1.age_jan1 < 110
   AND (CTE1.gender = 1 OR CTE1.gender = 2)
   AND soal NOT LIKE 'W%'
