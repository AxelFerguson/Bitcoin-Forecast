DROP VIEW IF EXISTS bitc_price_sf;

/*
This view selects the relevant data for the machine learning model. The date, price low and high, the stock flow, and stock growth rate.
*/
CREATE VIEW bitc_price_sf
AS

SELECT s.*,
       b.low, b.high
  FROM stockflow s
  JOIN bitcoin_price b
    ON s.date = b.date
 WHERE s.date >= '2009-01-08'
 ORDER BY s.date;
