CREATE MATERIALIZED VIEW mv_profit_balance_structure_in_last_month AS (
  WITH last_month AS (
      SELECT MAX(f_date) AS f_date
      FROM
        mv_profit_balances_by_month
  )
  SELECT
    f_player_id,
    f_date,
    f_date :: VARCHAR(12) AS f_string_date,

    f_balance_profit,
    (CASE
     WHEN f_balance_profit > 10000
       THEN '>10000'
     WHEN f_balance_profit > 9000
       THEN '10000'
     WHEN f_balance_profit > 8000
       THEN '9000'
     WHEN f_balance_profit > 7000
       THEN '8000'
     WHEN f_balance_profit > 6000
       THEN '7000'
     WHEN f_balance_profit > 5000
       THEN '6000'
     WHEN f_balance_profit > 4000
       THEN '5000'
     WHEN f_balance_profit > 3000
       THEN '4000'
     WHEN f_balance_profit > 2000
       THEN '3000'
     WHEN f_balance_profit > 1500
       THEN '2000'
     WHEN f_balance_profit > 1000
       THEN '1500'
     WHEN f_balance_profit > 900
       THEN '1000'
     WHEN f_balance_profit > 800
       THEN '900'
     WHEN f_balance_profit > 700
       THEN '800'
     WHEN f_balance_profit > 600
       THEN '700'
     WHEN f_balance_profit > 500
       THEN '600'
     WHEN f_balance_profit > 400
       THEN '500'
     WHEN f_balance_profit > 300
       THEN '400'
     WHEN f_balance_profit > 200
       THEN '300'
     WHEN f_balance_profit > 100
       THEN '200'
     WHEN f_balance_profit > 50
       THEN '100'
     WHEN f_balance_profit > 10
       THEN '50'
     WHEN f_balance_profit > 5
       THEN '10'
     WHEN f_balance_profit > 0
       THEN '5'
     ELSE '0'
     END)                 AS category_interval
  FROM
    mv_profit_balances_by_month
    JOIN
    last_month USING (f_date)
  ORDER BY
    f_date
);
