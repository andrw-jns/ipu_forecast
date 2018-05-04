SELECT *
  ,ISNULL(CTE1.prox_to_death,
     DATEDIFF(MM
            --,CONVERT(DATE, CONVERT(NVARCHAR(4),cte1.year) + '-' + CONVERT(NVARCHAR(2), cte1.month) +'-01') 
			,CTE1.date
            ,CONVERT(DATE, '2016-04-01')
             )
 ) [lower_bound] -- DiFFERENCE BETWEEN ADMISSION AND END OF DEATHS DATA
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
     WHEN disdate = '1801-01-01'
	 THEN ISNULL(ip.epiend, ip.epistart)
	 ELSE ISNULL(ip.disdate, ISNULL(ip.epiend, ip.epistart)) 
  END [date]
 

  ,ip.encrypted_hesid
   
    ,CASE 
	   WHEN disdate = '1801-01-01'
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
	,ip.startage
	,ip.sex as [gender]    
    ,ip.admidate
	,ip.epistart
	,ip.epiend
	,ip.disdate
	,d.dod
	,lsoa01
    --, lsoa11 -- for years after 201415
   
    ,ISNULL(DATEDIFF(dd, ip.admidate, ip.disdate) 
	         ,DATEDIFF(dd, ip.admidate, ip.epiend)
			 ) as [beddays] -- is this a naive way to count bed days?
    
	,cause_of_death
    
	,LEFT(cause_of_death, 1) as [cod1]
   
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
    
  FROM [HESData].dbo.tbInpatients1415 ip
  
    LEFT OUTER JOIN 
    (
      SELECT
       a.[Encrypted_HESID]
      ,a.[DOD]
      ,a.[CAUSE_OF_DEATH]
      --,a.SUBSEQUENT_ACTIVITY_FLG
      
      FROM [ONS].[HESONS].[tbMortalityto1516] a
    
      WHERE DOD > '2014-04-01'
      AND SUBSEQUENT_ACTIVITY_FLG IS NULL -- Ignore deaths with subseq activity.
     ) d
    ON ip.Encrypted_HESID = d.Encrypted_HESID
    
    ---
    
    WHERE 
    1 = 1 
    AND epiorder = 1
    AND admimeth LIKE '2%' -- EMERGENCY ADMISSIONS
	
	)CTE1
