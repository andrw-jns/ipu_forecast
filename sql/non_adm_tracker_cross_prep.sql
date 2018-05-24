/****** Script for SelectTopNRows command from SSMS  ******/

/* TO SIMPLIFY: CONSIDER CTE/ TEMP TABLES/VIEWS AND RUNNING FROM R WITH LOOP */

SELECT [encrypted_hesid]
		,[year] -- year is the same as year_adjust
		,[year2]
FROM
(
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
  -- AND CONSEQUENTLY NEED TO ADJUST AGE JAN 1
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
  LEFT JOIN (
			 --SELECT [encrypted_hesid]
			 --		,[disdate]
			 --		,[epiend]
			 --		,[epistart]
				--	,[sex]
				--	,[soal]
				--	,[mydob]
			 --FROM 
			 --[HESDATA].[DBO].[tbinpatients1011]
			 --WHERE 
			 --  1 = 1 
			 --  AND epiorder = 1
			 --  AND admimeth LIKE '2%' 

			 --UNION ALL

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
			   ) ip
   ON deaths.encrypted_hesid = ip.encrypted_hesid
   WHERE (DOD >= '2010-01-01' AND DOD < '2011-01-01')
--ORDER BY ENCRYPTED_HESID
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
				