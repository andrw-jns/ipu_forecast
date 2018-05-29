
SELECT DISTINCT [id], [year2] --, [yr]
FROM (
      SELECT *
      
      FROM 
	  --- ORIGINAL TABLE 1:
        (VALUES
           ('A', 2007)
          ,('A', 2009)
          ,('B', 2008)
           ) as orig(id, yr)
      
      
      LEFT JOIN (
	  -- TO TABLE 2 (years on the fly), CREATING TABLE 3 (for every year w/ episode - give years w/o):

      			SELECT  [year]
      				   ,[year2]
      
      			FROM
      			  (VALUES (2007),(2008),(2009),(2010)) as g ([year])
      			  cross join (VALUES (2007),(2008),(2009),(2010)) a([year2])
      			  WHERE [year] <> [year2]
      			  ) table2
      			  
        	    ON orig.yr = table2.year
	) CTE1
	
    WHERE NOT EXISTS (
                      SELECT 1
					  FROM (
							SELECT *
							FROM (
							-- TABLE 1:
							    VALUES
							      ('A', 2007)
							      ,('A', 2009)
							      ,('B', 2008)
							      ) AS teens2(id, yr)
							) orig1
								
							WHERE (CTE1.year2 = orig1.yr AND CTE1.id = orig1.id)
						)

