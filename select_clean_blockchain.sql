WITH
time_subsidy AS
( 
 SELECT DATE(mediantime, 'unixepoch', 'localtime') AS date, (subsidy/100000000.0) AS reward, height, (mediantime - 31556926) AS date_12
   FROM blockchain
),

annual_r AS
(
 SELECT SUM(reward) AS annual_reward, STRFTIME('%Y', date) AS year
   FROM time_subsidy
  GROUP BY STRFTIME('%Y', date)
),

d_reward AS
(
 SELECT date, SUM(reward) AS daily_reward
   FROM time_subsidy
  GROUP BY date
),

flow_365_pre AS
(
SELECT date, SUM(daily_reward) OVER (
                                     ORDER by date
                                      ROWS BETWEEN 365 PRECEDING
				       AND CURRENT ROW
				) AS flow
  FROM d_reward
 GROUP BY date  
),

cumulative_r AS
(
 SELECT date, reward, height,
        SUM(reward) OVER(
                         ORDER BY height
	                  ROWS BETWEEN UNBOUNDED PRECEDING
	                   AND CURRENT ROW
	            ) AS total_supply
  FROM time_subsidy
 ORDER BY height
),

stock_flow AS
(
 SELECT f.date, f.flow AS flow_365_p,
        MAX(c.total_supply) AS total_stock,
	MAX(c.total_supply)/f.flow AS stock_flow,
	(f.flow/MAX(c.total_supply)) AS supply_growth_rate
  FROM flow_365_pre f
  JOIN cumulative_r c
    ON f.date = c.date
 GROUP BY c.date
HAVING f.date NOT IN (SELECT DATE('now'))
)

SELECT *
  FROM stock_flow s
 ORDER BY date DESC 
 LIMIT 500;
