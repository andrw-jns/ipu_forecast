/****** CROSS PREP IS V2 OF NON_ADM_TRACKER  ******/

-- Pick up: mask complexity (and replication) by creating a view (or table, or temp table)


-- A VIEW WOULD BE PREFERABLE BECAUSE ONE COULD USE IT TWICE.
-- ADJUSTS YEAR (AND AGE) FOLLOWING THE FORWARDS ALLOCATION RULE

/* TO SIMPLIFY: CONSIDER CTE/ TEMP TABLES / VIEWS AND RUNNING FROM R WITH LOOP */

--SELECT DISTINCT [encrypted_hesid], [year2]


-- CTE4 BEGINS
-- SELECT DISTINCT year2, encrypted_hesid, age_countbk, gender, soal
-- FROM (



SELECT *, -- CTE3 BEGINS
  [age_adjust] - ([year] - [year2]) AS [age_countbk]
  
FROM (

SELECT * -- CTE2 BEGINS
    --   ,[encrypted_hesid]
	--   ,[year_adjust] -- year is the same as year_adjust
	--   ,[year2]
	  --,[age]
	  -- ,[gender]
	  -- ,[soal]
FROM (
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
	  
	FROM(
		SELECT TOP (100) --[File]
      deaths.[encrypted_hesid]
	  ,CASE 
	   WHEN DATEPART(YY, ip.disdate) IN (1582, 1800, 1801)
	   -- HIERARCHY: DISDATE, EPIEND, EPISTART
	   -- WHEN 1800 ETC. USE EPIEND THEN EPISTART
	   THEN ISNULL((DATEDIFF(Y
                    ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16') -- take dob to be mid month
                    ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.epiend))+ '-01-01')
                     ) / 365)
					 ,(DATEDIFF(Y
                    ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                    ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.epistart))+ '-01-01')
                     ) / 365)
					 )
	   -- BUT PREDOMINANTLY USE DISDATE:
	   ELSE ISNULL((DATEDIFF(Y
                             ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                             ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.disdate))+ '-01-01')
                             ) / 365)
				   , ISNULL((DATEDIFF(Y
                             ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                             ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.epiend))+ '-01-01')
                              ) / 365),
							  (DATEDIFF(Y
                             ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                             ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.epistart))+ '-01-01')
                              ) / 365)

							)
					) 
	   END [age_jan1]
	  ,ip.sex as [gender]
	  ,ip.soal
	  --,deaths.[DerivedAge] as [age_death]
	  --,deaths.sex as [gender]
	  --local authority
	  ,CASE
		WHEN DATEPART(YY, ip.disdate) IN (1582, 1800, 1801)
		THEN ISNULL(ip.epiend, ip.epistart)
		ELSE ISNULL(ip.disdate, ISNULL(ip.epiend, ip.epistart)) 
      END [date]
      ,[DOD]
      --,[DOR]
      --,[RESSTHA]
      --,[RESPCT]
  FROM [ONS].[HESONS].[tbMortalityto1617] deaths
  
  -- JOIN TO ADMISSIONS UPTO 5 CALENDAR YEARS BACKWARDS (MIN YEAR 0506 FOR 2006)
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
			FROM 
			[HESDATA].[DBO].[tbinpatients0708]
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
			FROM 
			[HESDATA].[DBO].[tbinpatients0607]
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
			FROM 
			[HESDATA].[DBO].[tbinpatients0506]
			WHERE 
			   1 = 1 
			   AND epiorder = 1
			   AND admimeth LIKE '2%'

			) ip
   ON deaths.encrypted_hesid = ip.encrypted_hesid
   WHERE (DOD >= '2010-01-01' AND DOD < '2011-01-01')
) CTE1
) CTE2

LEFT JOIN (
			SELECT [year]
				   ,[year2]

			FROM
			  (VALUES (2007),(2008),(2009),(2010)) as g ([year])
			  cross join (VALUES (2007),(2008),(2009),(2010)) a([year2])
			  WHERE [year] <> [year2]
			  ) y
			  
	ON CTE2.year_adjust = y.year

) CTE3

WHERE NOT EXISTS (
                  SELECT 1
					  FROM (
							SELECT *
							FROM (
							-- TABLE 1: (BUT ONLY NEED ID AND ADJUSTED YEAR)
							SELECT -- * -- CTE21 BEGINS
							[encrypted_hesid]
							,[year_adjust]
    --   ,[encrypted_hesid]
	--   ,[year_adjust] -- year is the same as year_adjust
	--   ,[year2]
	  --,[age]
	  -- ,[gender]
	  -- ,[soal]
FROM (
 -- SELECT THE REQUIRED INFO FROM DEATHS AND ADMISSIONS FOR MANY YEARS OF ADMISSIONS
 -- FOR THOSE DYING IN THE CALENDAR YR 2010
 -- GO BACK AS MANY YEARS AS THERE ARE TTD YEARS
 
  SELECT * -- CTE11 BEGINS
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
	  
	FROM(
		SELECT TOP (100) --[File]
      deaths.[encrypted_hesid]
	  ,CASE 
	   WHEN DATEPART(YY, ip.disdate) IN (1582, 1800, 1801)
	   -- HIERARCHY: DISDATE, EPIEND, EPISTART
	   -- WHEN 1800 ETC. USE EPIEND THEN EPISTART
	   THEN ISNULL((DATEDIFF(Y
                    ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16') -- take dob to be mid month
                    ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.epiend))+ '-01-01')
                     ) / 365)
					 ,(DATEDIFF(Y
                    ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                    ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.epistart))+ '-01-01')
                     ) / 365)
					 )
	   -- BUT PREDOMINANTLY USE DISDATE:
	   ELSE ISNULL((DATEDIFF(Y
                             ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                             ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.disdate))+ '-01-01')
                             ) / 365)
				   , ISNULL((DATEDIFF(Y
                             ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                             ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.epiend))+ '-01-01')
                              ) / 365),
							  (DATEDIFF(Y
                             ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                             ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.epistart))+ '-01-01')
                              ) / 365)

							)
					) 
	   END [age_jan1]
	  ,ip.sex as [gender]
	  ,ip.soal
	  --,deaths.[DerivedAge] as [age_death]
	  --,deaths.sex as [gender]
	  --local authority
	  ,CASE
		WHEN DATEPART(YY, ip.disdate) IN (1582, 1800, 1801)
		THEN ISNULL(ip.epiend, ip.epistart)
		ELSE ISNULL(ip.disdate, ISNULL(ip.epiend, ip.epistart)) 
      END [date]
      ,[DOD]
      --,[DOR]
      --,[RESSTHA]
      --,[RESPCT]
  FROM [ONS].[HESONS].[tbMortalityto1617] deaths
  
  -- JOIN TO ADMISSIONS UPTO 5 CALENDAR YEARS BACKWARDS (MIN YEAR 0506 FOR 2006)
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
			FROM 
			[HESDATA].[DBO].[tbinpatients0708]
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
			FROM 
			[HESDATA].[DBO].[tbinpatients0607]
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
			FROM 
			[HESDATA].[DBO].[tbinpatients0506]
			WHERE 
			   1 = 1 
			   AND epiorder = 1
			   AND admimeth LIKE '2%'

			) ip
   ON deaths.encrypted_hesid = ip.encrypted_hesid
   WHERE (DOD >= '2010-01-01' AND DOD < '2011-01-01')
) CTE11
) CTE21 


							) orig1
								
							WHERE (CTE3.year2 = orig1.year_adjust AND CTE3.encrypted_hesid = orig1.encrypted_hesid)
						)


			

-- JOINING BACK TO A SIMPLIFIED VERSION OF CTE 2