WITH
	
/*
This table converts the data from the bitcoin node blockchain data from UNIX-epoch time to the corresponding date.
It also converts the subsidy to the number of Bitcoin provided to the server that mined the coin originally, which will later be utilized to calculate the flow and supply.
The height is also selected as another way to order the later tables.
 */
time_subsidy AS
( 
 SELECT DATE(mediantime, 'unixepoch', 'localtime') AS date, (subsidy/100000000.0) AS reward, height
   FROM blockchain
),

/*
This table aggregates the reward into the total amount of Bitcoin(reward) given for each day.
*/
d_reward AS
(
 SELECT date, SUM(reward) AS daily_reward
   FROM time_subsidy
  GROUP BY date
),

/*
This table calculates the flow of bitcoin into the market for the previous 365 days prior to each row.
*/
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

/*
This table calculates the running total of all Bitcoin that have entered the market, grouped by height.
*/	
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

/* 
This table combines all the above tables. It selects the date, the flow for 365 days prior to that date,
the total stock that has ever entered the market, selecting the max(total_supply) because the prior table was grouped by height to ensure no block was missed.
It then utilizes the stock and divides it by flow to calculate the stock flow ratio, finally the table divides flow by total supply to calculate the supply growth rate.
This table then groups all the variables by the day to ensure that the forecasts can be calculated simply.
 */
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

/*
This table selects everything from the previous table, and places it in descending order.
This simplifies checking that the automatically added entries are being submitted properly.
*/
SELECT *
  FROM stock_flow s
 ORDER BY date DESC 
 LIMIT 500;
