 DROP TRIGGER IF EXISTS add_stock_flow;

/*
This trigger produces the date, the flow for 365 days prior to that date, the total stock that has ever entered the market,
divides the stock by flow the to calculate the stock flow ratio, finally the table divides flow by stock to calculate the supply growth rate.
This trigger then groups all the variables by the day to ensure that the forecasts can be calculated simply.
To see a further break down take a look at the select_clean_blockchain file.
The very last AND requirement in the HAVING statement is to ensure that only complete information is processed.
*/

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
