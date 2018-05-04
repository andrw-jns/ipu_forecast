/****** PROXIMITY TO DEATH BY MONTH PROVISIONAL SCRIPT  ******/


-- It may be sensible, if looking especially at the trends in last 12 months of life,
-- to exclude activity for a year before latest recorded deaths.

-- THE MONTH AND YEAR VARIABLES ARE FORMED BASED ON THESE RULES:
-- USE THE DISDATE 
-- IF NO RELIABLE DISDATE USE EPIEND
-- IF NO RELIABLE EPIEND USE EPISTART
-- MONTH, YEAR REFERENCED FOR AGE_JAN1, PROX_TO_DEATH, AND LOWER BOUND 

SELECT 
   cte3.[year]
  ,cte3.[year_adjust]
  ,cte3.[date]
  ,cte3.[encrypted_hesid]
  --,cte3.[age_jan1]
  --,cte3.[gender]
  --,cte3.[disdate]
  ,cte3.[dod]
  --,cte3.[lsoa01]
  ----,cte3.[beddays]
  ----,cte3.[cause_of_death]
  ----,cte3.[cod1]
  --,cte3.[lower_bound] -- lower bound will be out of date now
  --,cte3.[prox_to_death]

  --select datediff(MM, CONVERT(DATE, '2015-04-01'), CONVERT(DATE, '2015-06-15'))
  --,cte3.prox_to_death
    ,[boolean]
	,[month_adjust]
	,[year_adjust]
	,[prox_to_death]
  ,DATEDIFF(MM
    ,CONVERT(DATE, CONVERT(NVARCHAR(4),cte3.year_adjust) + '-' + CONVERT(NVARCHAR(2), cte3.month_adjust) +'-01')
	,cte3.dod
	) [prox_test]
   
 --  ,DATEDIFF(MM
 --   ,CONVERT(DATE, CONVERT(NVARCHAR(4),cte3.year_adjust) + '-' + CONVERT(NVARCHAR(2), cte3.month_adjust) + '-' + CONVERT(NVARCHAR(2), DATEPART(DD, cte3.date)))
	--,cte3.dod
	--) [prox_t2]
	-- I'm guessing february is a problem here.
  ,CONVERT(NVARCHAR(4),cte3.year_adjust)
  ,CONVERT(NVARCHAR(2), cte3.month_adjust)
  ,CONVERT(NVARCHAR(2), DATEPART(DD, cte3.date))
   ,CONVERT(DATE, '2016-02-29')

FROM (
SELECT * 
,CASE
  WHEN cte2.month < 12 AND cte2.boolean = 1 -- DATEPART(dd, cte.date) > DATEPART(dd, cte.dod)
  THEN cte2.month +1
  WHEN cte2.month = 12 AND cte2.boolean = 1
  THEN 1
  ELSE cte2.month
  END [month_adjust]
 
  ,CASE
  WHEN cte2.month = 12 AND cte2.boolean = 1
  THEN year +1
  ELSE cte2.year
  END [year_adjust]

FROM(

SELECT * 
 --,CASE
 --   WHEN cte.prox_to_death IS NULL
	--THEN ISNULL(DATEDIFF(MM
	--                      ,cte.disdate
	--					  ,CONVERT(DATE, '2016-04-01'))
	--		    ,ISNULL((DATEDIFF(MM
	--                      ,cte.epiend
	--					  ,CONVERT(DATE, '2016-04-01')))
	--					,(DATEDIFF(MM
	--                      ,cte.epistart
	--					  ,CONVERT(DATE, '2016-04-01')))
	--					  )
	--			)
	-- ELSE cte.prox_to_death
 -- END [lower_bound] -- DiFFERENCE BETWEEN ADMISSION AND END OF DEATHS DATA

  ,DATEDIFF(MM
    ,CONVERT(DATE, CONVERT(NVARCHAR(4),cte.year) + '-' + CONVERT(NVARCHAR(2), cte.month) +'-01')
	,cte.dod
	) [prox_2]

  --,CASE
  --  WHEN cte.month < 12 AND DATEPART(dd, date) >
  --, CONVERT(BOOLEAN, 1 > 2)
  --,DATEPART(dd, cte.date) > DATEPART(dd, cte.dod))
  
  ,CASE 
    WHEN DATEPART(dd, cte.date) > DATEPART(dd, cte.dod)
	THEN 1
	ELSE 0
	END [boolean]

  ,ISNULL(cte.prox_to_death,
		  DATEDIFF(MM
            ,CONVERT(DATE, CONVERT(NVARCHAR(4),cte.year) + '-' + CONVERT(NVARCHAR(2), cte.month) +'-01') 
            ,CONVERT(DATE, '2016-04-01')
             ) 
			 ) [lower_bound] -- DiFFERENCE BETWEEN ADMISSION AND END OF DEATHS DATA



			 --, CASE
    --    --WHEN d.Encrypted_HESid IS NULL
    --    --THEN NULL -- SET AS NULL FOR THOSE WITHOUT DEATH RECORD 
    --    WHEN DATEDIFF(MM, ip.admidate, d.DOD) between 0 and 40000  
    --    THEN CAST(
    --      FLOOR(
    --        DATEDIFF(dd, ip.admidate, d.DOD)/30.42 -- average days in a month
    --                ) AS INT
    --           )
    --    WHEN DATEDIFF(dd, ip.admidate, d.DOD) < 0
    --    THEN 999999 -- Error code will be 999999
    --    ELSE 999999 
    --END [prox_to_death]
  
 


FROM (
  
  SELECT --TOP 10000
  
  CASE 
	  WHEN disdate = '1801-01-01'
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
 
  ,CASE 
	WHEN disdate = '1801-01-01'
	THEN ISNULL(DATEPART(MONTH, ip.epiend), DATEPART(MONTH, ip.epistart)) 
	ELSE ISNULL(DATEPART(MONTH,ip.disdate),
	   ISNULL(DATEPART(MONTH, ip.epiend), DATEPART(MONTH, ip.epistart))
		) 
	END [month]
  
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
	-- from hesdata.dbo.tbinpatients1516 ip

    --,ip.startage
	,ip.sex as [gender]    
    ,ip.admidate
	,ip.epistart
	,ip.epiend
	,ip.disdate
	,d.dod
   
    --, resladst_ons -- only for 201617
    , lsoa01
    --, lsoa11 -- for years after 201415
   
 --   ,ISNULL(DATEDIFF(dd, ip.admidate, ip.disdate) 
	--         ,DATEDIFF(dd, ip.admidate, ip.epiend)
	--		 ) as [beddays] -- is this a naive way to count bed days?
    
	--,cause_of_death
    
	--,LEFT(cause_of_death, 1) as [cod1]
   
    , CASE
        --WHEN d.Encrypted_HESid IS NULL
        --THEN NULL -- SET AS NULL FOR THOSE WITHOUT DEATH RECORD 
        WHEN DATEDIFF(DD, ip.disdate, d.DOD) between 0 and 40000 
        THEN CAST(
          FLOOR(
            DATEDIFF(DD, ip.disdate, d.DOD) /30.42 -- average days in a month
                    ) AS INT
               )
        WHEN DATEDIFF(DD, ip.disdate, d.DOD) < 0
        THEN 999999 -- Error code will be 999999
        ELSE NULL 
    END [prox_to_death]
  
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
    ) cte
	)cte2
	)cte3
	WHERE BOOLEAN = 1