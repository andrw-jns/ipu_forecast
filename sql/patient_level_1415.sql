
-- It may be sensible, if looking especially at the trends in last 12 months of life,
-- to exclude activity for a year before latest recorded deaths.

SELECT * 
 ,CASE
    WHEN cte.prox_to_death IS NULL
	THEN ISNULL(DATEDIFF(MM
	                      ,cte.disdate
						  ,CONVERT(DATE, '2016-04-01'))
			    ,DATEDIFF(MM
	                      ,cte.epiend
						  ,CONVERT(DATE, '2016-04-01'))
				)

	ELSE cte.prox_to_death
  END [lower_bound]-- LOWER BOUND GOES HERE : ADMISSION AND END OF DEATHS DATA

FROM (
  
  SELECT TOP 100000
    -- Datepart(YEAR, ip.disdate) as [year]
  CASE 
	  WHEN disdate = '1801-01-01'
	  THEN Datepart(YEAR, ip.epiend)
	  ELSE ISNULL(Datepart(YEAR, ip.disdate), Datepart(YEAR, ip.epiend)) 
	  END [year]
	
   -- CASE 
   --   WHEN Datepart(YEAR, ip.disdate) as [year] IS NOT NULL
  	--THEN Datepart(YEAR, ip.disdate) as [year]
    --, Datepart(YEAR, ip.admidate) as [year_admi]
  ,CASE 
	WHEN disdate = '1801-01-01'
	THEN Datepart(MONTH, ip.epiend)
	ELSE ISNULL(Datepart(MONTH,ip.disdate), Datepart(MONTH, ip.epiend))
	END [month]
    --, Datepart(MONTH,ip.disdate) as [month] 
  ,ip.encrypted_hesid
   
    ,CASE 
	   WHEN disdate = '1801-01-01'
	   THEN DATEDIFF(Y
                    ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                    ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATEPART(YY, ip.epiend))+ '-01-01')
                     ) / 365
	   ELSE ISNULL((DATEDIFF(Y
                             ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                             ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATepart(YY, ip.disdate))+ '-01-01')
                             ) / 365)
				   ,(DATEDIFF(Y
                             ,CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
                             ,CONVERT(DATE, CONVERT(NVARCHAR(4), DATepart(YY, ip.epiend))+ '-01-01')
                              ) / 365)
					 ) 
					 END [age_jan1]
	-- from hesdata.dbo.tbinpatients1516 ip
    --,DATEDIFF(Y
    --          , CONVERT(DATE, SUBSTRING(ip.mydob, 3, 4) + '-' + SUBSTRING(ip.mydob, 1, 2) + '-16')
    --          , CONVERT(DATE, CONVERT(NVARCHAR(4), DATepart(YY, ip.disdate))+ '-01-01')
    --          --, CONVERT(DATE, '2015' + '-01-01') -- FIX: episodes could fall in one of two years. 
    --          ) / 365 as [age_jan1]
    --,ip.startage
	,ip.sex as [gender]    
    ,ip.admidate
	,ip.epiend
	,ip.disdate
   
    --, resladst_ons
    , lsoa01
    --, lsoa11
   
    , ISNULL(DATEDIFF(dd, ip.admidate, ip.disdate) 
	         ,DATEDIFF(dd, ip.admidate, ip.epiend)
			 ) as [beddays] -- is there a better way to count bed days
    ,cause_of_death
    ,LEFT(cause_of_death, 1) as [cod_1]
    , CASE
        WHEN d.Encrypted_HESid IS NULL
        THEN NULL -- SET NULLS FOR THOSE WITHOUT DEATH RECORD 
        WHEN DATEDIFF(dd, ip.admidate, d.DOD) between 0 and 40000 
        THEN CAST(
          FLOOR(
            DATEDIFF(dd, ip.admidate, d.DOD)/30.42 -- average days in a month
                    ) AS INT
               )
        WHEN DATEDIFF(dd, ip.admidate, d.DOD) < 0
        THEN 999999 -- Error code will be 999999
        ELSE 999999 
    END [prox_to_death]
  
    ----
    
  FROM [HESData].dbo.tbInpatients1415 ip
  
    -- LEFT OUTER JOIN [StrategicReference].dbo.vwGPPracticeToCCGAndPCT ccg 
    --   ON ip.gpprac = ccg.GPPractice 
    
    LEFT OUTER JOIN 
    (
    SELECT
     a.[Encrypted_HESID]
    ,a.[DOD]
    ,a.[CAUSE_OF_DEATH]
    --,a.derivedage
    ,a.SUBSEQUENT_ACTIVITY_FLG
    
    FROM [ONS].[HESONS].[tbMortalityto1516] a
    --WHERE DOD between '20", str_sub(years[i], 1, 2), "-04-01' AND '20", year_plus_one , "-03-31'
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