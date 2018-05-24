

SELECT *
  , CASE 
    WHEN yob BETWEEN 1907 AND 1916
	  THEN 1907
	WHEN yob BETWEEN 1917 AND 1926
	  THEN 1917
	WHEN yob BETWEEN 1927 AND 1936
	  THEN 1927
	WHEN yob BETWEEN 1937 AND 1946
	  THEN 1937
	WHEN yob BETWEEN 1947 AND 1956
	  THEN 1947
	WHEN yob BETWEEN 1957 AND 1966
	  THEN 1957
	WHEN yob BETWEEN 1967 AND 1976
	  THEN 1967
	WHEN yob BETWEEN 1977 AND 1986
	  THEN 1977
	WHEN yob BETWEEN 1987 AND 1996
	  THEN 1987
	WHEN yob BETWEEN 1997 AND 2006
	  THEN 1997
	WHEN yob BETWEEN 2007 AND 2016
	  THEN 2007
	ELSE NULL
	END [cohort]


  ,ISNULL(CTE1.prox_to_death,
     DATEDIFF(MM
            --,CONVERT(DATE, CONVERT(NVARCHAR(4),cte1.year) + '-' + CONVERT(NVARCHAR(2), cte1.month) +'-01') 
			,CTE1.date
            ,CONVERT(DATE, '2016-04-01')
             )
 ) [lower_bound] -- DiFFERENCE BETWEEN ADMISSION AND END OF DEATHS DATA

-- THIS (AND THE PROX_DEATH) CAN BE COMPRESSED INTO ONE BIT OF CODE
 ,CASE
   WHEN prox_to_death < 12
   THEN 1
   WHEN prox_to_death > 11 AND prox_to_death < 24
   THEN 2
   WHEN prox_to_death > 23 AND prox_to_death < 36
   THEN 3
   WHEN prox_to_death > 35 AND prox_to_death < 48
   THEN 4
   ELSE NULL
   END [ttd]

   INTO strategicworking.defaults.aj_prox_death_1314
 FROM (
SELECT 

 CASE 
	  WHEN DATEPART(YY, ip.disdate) IN (1800, 1801)
	  THEN ISNULL(DATEPART(YEAR, ip.epiend), DATEPART(YEAR, ip.epistart))
	  ELSE ISNULL(DATEPART(YEAR, ip.disdate),
	    ISNULL(DATEPART(YEAR, ip.epiend), DATEPART(year, ip.epistart))
		) 
	  END [year]
  ,CASE
     WHEN DATEPART(YY, ip.disdate) IN (1800, 1801)
	 THEN ISNULL(ip.epiend, ip.epistart)
	 ELSE ISNULL(ip.disdate, ISNULL(ip.epiend, ip.epistart)) 
  END [date]
 

  ,ip.encrypted_hesid
   
    ,CASE 
	   WHEN DATEPART(YY, ip.disdate) IN (1800, 1801)
	   -- HIERARCHY: DISDATE, EPIEND, EPISTART
	   -- WHEN 1801 USE EPIEND. IF NO EPI END USE EPISTART...
	   THEN ISNULL((DATEDIFF(Y
                    ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
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
	--,ip.startage
	,CAST(right(ip.mydob, 4) AS INT) AS [yob]
	,ip.sex as [gender]    
 --   ,ip.admidate
	--,ip.epistart
	--,ip.epiend
	--,ip.disdate
	--,d.dod
	,lsoa01
    --, lsoa11 -- for years after 201415
   
    --,ISNULL(DATEDIFF(dd, ip.admidate, ip.disdate) 
	   --      ,DATEDIFF(dd, ip.admidate, ip.epiend)
			 --) as [beddays] -- is this a naive way to count bed days?
    

	,CASE 
	  WHEN DATEPART(YY, ip.disdate) IN (1800, 1801)
	  THEN DATEDIFF(dd, ip.admidate, ip.epiend)
	  ELSE ISNULL(DATEDIFF(dd, ip.admidate, ip.disdate) 
	         ,DATEDIFF(dd, ip.admidate, ip.epiend)
		) 
	  END [beddays]


	,cause_of_death
    
	--,LEFT(cause_of_death, 1) as [cod1]
   
    , CASE
        WHEN DATEDIFF(DD, ip.admidate, d.DOD) between 0 and 40000 
        THEN CAST(
          FLOOR(
            DATEDIFF(DD, ip.admidate, d.DOD) /30.42 -- average days in a month
                    ) AS INT
               )
        WHEN DATEDIFF(DD, ip.admidate, d.DOD) < 0
        THEN 999999 -- Error code will be 999999
        ELSE NULL 
    END [prox_to_death]
	
	-- ,CASE 
	--WHEN disdate = '1801-01-01'
	--THEN ISNULL(DATEPART(MONTH, ip.epiend), DATEPART(MONTH, ip.epistart)) 
	--ELSE ISNULL(DATEPART(MONTH,ip.disdate),
	--   ISNULL(DATEPART(MONTH, ip.epiend), DATEPART(MONTH, ip.epistart))
	--	) 
	--END [month]

	

	 ----
    
  FROM [HESData].dbo.tbInpatients1314 ip
  
    LEFT OUTER JOIN 
    (
      SELECT
       a.[Encrypted_HESID]
      ,a.[DOD]
      ,a.[CAUSE_OF_DEATH]
      --,a.SUBSEQUENT_ACTIVITY_FLG
      
      FROM [ONS].[HESONS].[tbMortalityto1516] a
    
      WHERE DOD > '2013-04-01'
      AND SUBSEQUENT_ACTIVITY_FLG IS NULL -- Ignore deaths with subseq activity.
     ) d
    ON ip.Encrypted_HESID = d.Encrypted_HESID
    
    ---
    
    WHERE 
    1 = 1 
    AND epiorder = 1
    AND admimeth LIKE '2%' -- EMERGENCY ADMISSIONS
	
	)CTE1
