--SELECT*
--FROM 
--  (VALUES
--     ('A', 2007)
--    ,('A', 2009)
--    ,('B', 2008)
--     ) as teens2 (id, yr)

--RIGHT JOIN (


      SELECT *
      -- id
      --,yr
      --,year2
      FROM 
        (VALUES
           ('A', 2007)
          ,('A', 2009)
          ,('B', 2008)
           ) as teens(id, yr)
      
      
      LEFT JOIN (
      			SELECT  [year]
      				   ,[year2]
      
      			FROM
      			  (VALUES (2007),(2008),(2009),(2010)) as g ([year])
      			  cross join (VALUES (2007),(2008),(2009),(2010)) a([year2])
      			  WHERE [year] <> [year2]
      			  ) y
      			  
        	ON teens.yr = y.year
       
	   
	 
   
   
   
   
   
   
   
   
        
	---- ANTI JOIN
	--WHERE NOT EXISTS (
	--				  SELECT 1 FROM ( 
					  
	--				  --- JOIN TWO TABLES TO CREATE INDEX OF DUPLICATES

	--								 SELECT new.encrypted_hesid
	--								 FROM [ONS].[HESONS].[tbMortality1516] new
	--									INNER JOIN [ONS].[HESONS].[tbMortalityto1415] old
	--									ON new.encrypted_hesid = old.encrypted_hesid AND old.[File] = '1314to1415'
	
	--									WHERE DATEPART(MONTH, OLD.DOD)  > 03
	--									AND DATEPART(YEAR, oLD.DOD)  >= 2015 
	--									) duplicates
										
	--					WHERE duplicates.encrypted_hesid = mort.encrypted_hesid
	--					)