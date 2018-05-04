SELECT 
  
  CASE
  WHEN cte2.month = 12 AND cte2.month_adjust_flag = 1
  THEN year +1
  ELSE cte2.year
  END [year]
  
  ,CASE
  WHEN cte2.month < 12 AND cte2.month_adjust_flag = 1 -- DATEPART(dd, cte.date) > DATEPART(dd, cte.dod)
  THEN cte2.month +1
  WHEN cte2.month = 12 AND cte2.month_adjust_flag = 1
  THEN 1
  ELSE cte2.month
  END [month]
 
   ,[encrypted_hesid]
   ,[age_jan1]
   ,[gender]
   ,[lsoa01]
   ,cte2.[admidate]
   ,cte2.[disdate]
   ,[dod]
   ,[cause_of_death]
   ,[cod1]
   ,[beddays]
   ,[prox_to_death]
   ,[lower_bound]
   

FROM(

SELECT *

,CASE 
    WHEN DATEPART(dd, cte1.date) > DATEPART(dd, cte1.dod)
	THEN 1
	ELSE 0
	END [month_adjust_flag]

,ISNULL(cte1.prox_to_death,
		  DATEDIFF(MM
            --,CONVERT(DATE, CONVERT(NVARCHAR(4),cte1.year) + '-' + CONVERT(NVARCHAR(2), cte1.month) +'-01') 
			,cte1.date
            ,CONVERT(DATE, '2016-04-01')
             ) 
 ) [lower_bound] -- DiFFERENCE BETWEEN ADMISSION AND END OF DEATHS DATA

FROM(
SELECT TOP 1000

CASE
     WHEN ip.disdate = '1801-01-01'
	 THEN ISNULL(ip.epiend, ip.epistart)
	 ELSE ISNULL(ip.disdate, ISNULL(ip.epiend, ip.epistart)) 
  END [date]
,ip.encrypted_hesid
   
    ,CASE 
	   WHEN disdate = '1801-01-01'
	   -- WHEN 1801 USE EPISTART IF NO EPIEND  :
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
				   ,(DATEDIFF(Y
                             ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                             ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.epiend))+ '-01-01')
                              ) / 365)
					 ) 
	   END [age_jan1]
	,ip.sex as [gender]    
    ,ip.admidate
	--,ip.epistart
	--,ip.epiend
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
        WHEN DATEDIFF(DD, ip.disdate, d.DOD) < 0
        THEN 999999 -- Error code will be 999999
        ELSE NULL 
    END [prox_to_death]
	
	 ,CASE 
	WHEN disdate = '1801-01-01'
	THEN ISNULL(DATEPART(MONTH, ip.epiend), DATEPART(MONTH, ip.epistart)) 
	ELSE ISNULL(DATEPART(MONTH,ip.disdate),
	   ISNULL(DATEPART(MONTH, ip.epiend), DATEPART(MONTH, ip.epistart))
		) 
	END [month]

	 ,CASE 
	  WHEN disdate = '1801-01-01'
	  THEN ISNULL(DATEPART(YEAR, ip.epiend), DATEPART(YEAR, ip.epistart))
	  ELSE ISNULL(DATEPART(YEAR, ip.disdate),
	    ISNULL(DATEPART(YEAR, ip.epiend), DATEPART(year, ip.epistart))
		) 
	  END [year]

	 ----
    
  FROM [HESData].dbo.tbInpatients1415 ip
  
    LEFT OUTER JOIN 
    (
      SELECT
       a.[Encrypted_HESID]
      ,a.[DOD]
      ,a.[CAUSE_OF_DEATH]
     
      ,a.SUBSEQUENT_ACTIVITY_FLG
      
      FROM [ONS].[HESONS].[tbMortalityto1516] a
    
      WHERE DOD between '2014-04-01' AND '2016-03-31'
      AND SUBSEQUENT_ACTIVITY_FLG IS NULL -- Ignore deaths with subseq activity.
     ) d
    ON ip.Encrypted_HESID = d.Encrypted_HESID
    
    ---
    
    WHERE 
    1 = 1 
    AND epiorder = 1
    AND admimeth LIKE '2%' -- EMERGENCY ADMISSIONS


	)CTE1
	)CTE2
  