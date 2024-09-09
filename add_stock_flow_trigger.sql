 DROP TRIGGER IF EXISTS add_stock_flow;
 
 CREATE TRIGGER add_stock_flow
  AFTER INSERT 
     ON blockchain

BEGIN
 
 INSERT INTO stockflow (date, flow_365_p, total_stock, stock_flow, supply_growth_rate)
 
 SELECT f.date, f.flow AS flow_365_p,
        MAX(c.total_supply) AS total_stock,
	MAX(c.total_supply)/f.flow AS stock_flow,
	(f.flow/MAX(c.total_supply)) AS supply_growth_rate
   FROM (SELECT DATE(mediantime, 'unixepoch', 'localtime') AS date, SUM(SUM((subsidy/100000000.0))) OVER (
	  ORDER by DATE(mediantime, 'unixepoch', 'localtime')
	   ROWS BETWEEN 365 PRECEDING
	    AND CURRENT ROW) AS flow
           FROM blockchain
          GROUP BY DATE(mediantime, 'unixepoch', 'localtime')
		 ) AS f
   JOIN (SELECT DATE(mediantime, 'unixepoch', 'localtime') AS date,
                SUM((subsidy/100000000.0)) OVER(
          ORDER BY height
	   ROWS BETWEEN UNBOUNDED PRECEDING
	    AND CURRENT ROW) AS total_supply
           FROM blockchain
          ORDER BY height
		) AS c
     ON f.date = c.date
  GROUP BY c.date
 HAVING (f.date NOT IN (SELECT date
                        FROM stockflow))
    AND (f.date NOT IN (SELECT DATE('now')))
    AND ((SELECT MAX(DATE(mediantime, 'unixepoch', 'localtime')) FROM blockchain) IN (SELECT DATE('now')));
END;
