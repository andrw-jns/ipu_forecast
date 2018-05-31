
SELECT DISTINCT [id], [year2] --, [yr]
FROM (
      SELECT *
      
      FROM 
	  --- ORIGINAL TABLE 1:
        (VALUES
           ('A', 60, 2007)
          ,('A', 62, 2009)
          ,('B', 80, 2008)
           ) as orig(id, age, yr)
      
      
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
							FROM 
							     (
							-- TABLE 1: (BUT ONLY NEED ID AND ADJUSTED YEAR)
							    VALUES
							      ('A', 60, 2007)
          						  ,('A', 62, 2009)
          						  ,('B', 80, 2008)
							      ) AS teens2(id, age, yr)
							) orig1
								
							WHERE (CTE1.year2 = orig1.yr AND CTE1.id = orig1.id)
						)

