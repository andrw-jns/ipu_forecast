/****** CROSS PREP IS V2 OF NON_ADM_TRACKER  ******/

-- Pick up: mask complexity (and replication) by creating a view (or table, or temp table)


-- A VIEW WOULD BE PREFERABLE BECAUSE ONE COULD USE IT TWICE.
-- ADJUSTS YEAR (AND AGE) FOLLOWING THE FORWARDS ALLOCATION RULE

/* TO SIMPLIFY: CONSIDER CTE/ TEMP TABLES / VIEWS AND RUNNING FROM R WITH LOOP */

--SELECT DISTINCT [encrypted_hesid], [year2]


-- CTE4 BEGINS
-- SELECT DISTINCT year2, encrypted_hesid, age_countbk, gender, soal
-- FROM (



SELECT DISTINCT [encrypted_hesid] -- CTE3 BEGINS
   ,[age_adjust] - ([year] - [year2]) AS [age_countbk]
   ,[gender]
   ,[soal]
   ,[DOD] as [dod]
   ,[death_chapter]
   ,[cohort]
   ,[year]
   ,[year2]
  ,[ttd] + ([year] - [year2]) AS [ttd_countback]
  -- NEED A TIME TO DEATH COUNTBACK?
INTO [StrategicWorking].[DEFAULTS].[aj_180619_tracker_test]
FROM (

SELECT * -- CTE2 BEGINS
    --   ,[encrypted_hesid]
	--   ,[year_adjust] -- year is the same as year_adjust
	--   ,[year2]
	  --,[age]
	  -- ,[gender]
	  -- ,[soal]
FROM [StrategicWorking].[dbo].[vw_prx_death_tracker] tracker

LEFT JOIN (
			SELECT [year]
				   ,[year2]

			FROM
			  (VALUES(2008),(2009),(2010)) as g ([year])
			  cross join (VALUES (2008),(2009),(2010)) a([year2])
			  WHERE [year] <> [year2]
			  ) y
			  
	ON tracker.year_adjust = y.year

) CTE3

WHERE NOT EXISTS (
                  SELECT 1
					  FROM (
							SELECT [encrypted_hesid]
							,[year_adjust] -- *
							FROM [StrategicWorking].[dbo].[vw_prx_death_tracker]
							-- TABLE 1: (BUT ONLY NEED ID AND ADJUSTED YEAR)
							) orig1
								
							WHERE (CTE3.year2 = orig1.year_adjust AND CTE3.encrypted_hesid = orig1.encrypted_hesid)
						)
AND [year_adjust] <> 2007

ORDER BY [encrypted_hesid]

			