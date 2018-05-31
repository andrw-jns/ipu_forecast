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
	  
	FROM(
	            	SELECT -- TOP (100) --[File]
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
