CREATE MATERIALIZED VIEW mv_deposit AS (

  SELECT
    f_player_id,
    f_stamp :: DATE                 AS f_date,
    (SUM(f_value) :: NUMERIC / 100) AS f_deposit,
    COUNT(*)                        AS f_deposit_count
  FROM
    v_completed_transactions_on_real_money
  WHERE
    f_type = 68
  GROUP BY
    f_player_id,
    f_date

);
