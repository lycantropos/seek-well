CREATE MATERIALIZED VIEW mv_pool_state_date_steps AS (
  WITH
      steps AS (
        SELECT UNNEST(ARRAY [
        0,
        1,
        7,
        14,
        21,
        30,
        60,
        90,
        120
        ]) AS f_step
    ),
      live_player_with_registration AS (
        SELECT
          f_id                       AS f_player_id,
          (f_register_stamp :: DATE) AS f_register_date
        FROM
          t_player
          JOIN
          t_house_flag
            ON
              t_house_flag.f_player_id = t_player.f_id
        WHERE
          f_house_flag = 0
    ),
      player_all_dates AS (
        SELECT
          f_player_id,
          f_register_date,
          generate_series(f_register_date, now(), '1 day') :: DATE AS f_date
        FROM
          live_player_with_registration
    ),
      player_cumulative_balance AS (
        SELECT
          f_player_id,
          f_date,
          SUM(f_balance)
          OVER w AS f_cumulative_balance
        FROM
          v_balance
          JOIN
          live_player_with_registration USING (f_player_id)
        WINDOW w AS (
          PARTITION BY
            f_player_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_balance_by_day_with_null AS (
        SELECT
          f_player_id,
          f_register_date,
          f_date,
          f_cumulative_balance,
          COUNT(f_cumulative_balance)
          OVER w            AS f_cumulative_balance_id,
          'balance' :: TEXT AS f_metric
        FROM
          player_all_dates
          LEFT JOIN
          player_cumulative_balance USING (f_player_id, f_date)
        WINDOW w AS (
          PARTITION BY
            f_player_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_balance_by_day AS (
        SELECT
          f_player_id,
          f_register_date,
          f_date,
          f_metric,

          COALESCE(
              f_cumulative_balance,
              first_value(f_cumulative_balance)
              OVER w,
              0
          ) AS f_value
        FROM
          player_cumulative_balance_by_day_with_null
        WINDOW w AS (
          PARTITION BY
            f_player_id,
            f_cumulative_balance_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_deposit AS (
        SELECT
          f_player_id,
          f_date,
          SUM(f_deposit)
          OVER w AS f_cumulative_deposit
        FROM
          mv_deposit
          JOIN
          live_player_with_registration USING (f_player_id)
        WINDOW w AS (
          PARTITION BY
            f_player_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_deposit_by_day_with_null AS (
        SELECT
          f_player_id,
          f_register_date,
          f_date,
          f_cumulative_deposit,
          COUNT(f_cumulative_deposit)
          OVER w            AS f_cumulative_deposit_id,
          'deposit' :: TEXT AS f_metric
        FROM
          player_all_dates
          LEFT JOIN
          player_cumulative_deposit USING (f_player_id, f_date)
        WINDOW w AS (
          PARTITION BY
            f_player_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_deposit_by_day AS (
        SELECT
          f_player_id,
          f_register_date,
          f_date,
          f_metric,

          COALESCE(
              f_cumulative_deposit,
              first_value(f_cumulative_deposit)
              OVER w,
              0
          ) AS f_value
        FROM
          player_cumulative_deposit_by_day_with_null
        WINDOW w AS (
          PARTITION BY
            f_player_id,
            f_cumulative_deposit_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_cashouts AS (
        SELECT
          f_player_id,
          f_date,
          SUM(ABS(f_cashouts))
          OVER w AS f_cumulative_cashouts
        FROM
          v_cashouts
          JOIN
          live_player_with_registration USING (f_player_id)
        WINDOW w AS (
          PARTITION BY
            f_player_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_cashouts_by_day_with_null AS (
        SELECT
          f_player_id,
          f_register_date,
          f_date,
          f_cumulative_cashouts,
          COUNT(f_cumulative_cashouts)
          OVER w             AS f_cumulative_cashouts_id,
          'cashouts' :: TEXT AS f_metric
        FROM
          player_all_dates
          LEFT JOIN
          player_cumulative_cashouts USING (f_player_id, f_date)
        WINDOW w AS (
          PARTITION BY
            f_player_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_cashouts_by_day AS (
        SELECT
          f_player_id,
          f_register_date,
          f_date,
          f_metric,

          COALESCE(
              f_cumulative_cashouts,
              first_value(f_cumulative_cashouts)
              OVER w,
              0
          ) AS f_value
        FROM
          player_cumulative_cashouts_by_day_with_null
        WINDOW w AS (
          PARTITION BY
            f_player_id,
            f_cumulative_cashouts_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_rake AS (
        SELECT
          f_player_id,
          f_date,
          SUM(
              COALESCE(f_cash_rake, 0) +
              COALESCE(f_SNG_rake, 0) +
              COALESCE(f_MTT_rake, 0)
          )
          OVER w AS f_cumulative_rake
        FROM
          v_cash_rake
          FULL JOIN
          v_tournament_rake USING (f_player_id, f_date)
          JOIN
          live_player_with_registration USING (f_player_id)
        WINDOW w AS (
          PARTITION BY
            f_player_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_rake_by_day_with_null AS (
        SELECT
          f_player_id,
          f_register_date,
          f_date,
          f_cumulative_rake,
          COUNT(f_cumulative_rake)
          OVER w         AS f_cumulative_rake_id,
          'rake' :: TEXT AS f_metric
        FROM
          player_all_dates
          LEFT JOIN
          player_cumulative_rake USING (f_player_id, f_date)
        WINDOW w AS (
          PARTITION BY
            f_player_id
          ORDER BY
            f_date
        )
    ),
      player_cumulative_rake_by_day AS (
        SELECT
          f_player_id,
          f_register_date,
          f_date,
          f_metric,

          COALESCE(
              f_cumulative_rake,
              first_value(f_cumulative_rake)
              OVER w,
              0
          ) AS f_value
        FROM
          player_cumulative_rake_by_day_with_null
        WINDOW w AS (
          PARTITION BY
            f_player_id,
            f_cumulative_rake_id
          ORDER BY
            f_date
        )
    ),
      all_registrations_dates AS (
        SELECT generate_series(min(f_register_date), now(),
                               '1 day') :: DATE AS f_date
        FROM
          live_player_with_registration
    ),
      dates_with_steps AS (
        SELECT
          f_date,
          f_step,
          (f_date +
           CONCAT(f_step, ' days') :: INTERVAL) :: DATE AS f_date_with_step
        FROM
          all_registrations_dates
          CROSS JOIN
          steps
    ),
      metrics_with_zero_step AS (
        SELECT
          f_metric,
          dates.f_date,
          dates.f_step,
          SUM(f_value) AS f_value
        FROM
          dates_with_steps AS dates,
          (
            SELECT *
            FROM player_cumulative_balance_by_day
            UNION ALL
            SELECT *
            FROM player_cumulative_deposit_by_day
            UNION ALL
            SELECT *
            FROM player_cumulative_cashouts_by_day
            UNION ALL
            SELECT *
            FROM player_cumulative_rake_by_day
          ) AS metrics
        WHERE
          dates.f_step = 0 AND
          metrics.f_register_date <= dates.f_date AND
          metrics.f_date = dates.f_date_with_step
        GROUP BY
          f_metric,
          dates.f_date,
          dates.f_step
    ),
      metrics_with_not_zero_step AS (
        SELECT
          f_metric,
          dates.f_date,
          dates.f_step,
          SUM(f_value) AS f_value
        FROM
          dates_with_steps AS dates,
          (
            SELECT *
            FROM player_cumulative_balance_by_day
            UNION ALL
            SELECT *
            FROM player_cumulative_deposit_by_day
            UNION ALL
            SELECT *
            FROM player_cumulative_cashouts_by_day
            UNION ALL
            SELECT *
            FROM player_cumulative_rake_by_day
          ) AS metrics
        WHERE
          dates.f_step > 0 AND
          metrics.f_register_date > dates.f_date AND
          metrics.f_register_date <= dates.f_date_with_step AND
          metrics.f_date = dates.f_date_with_step
        GROUP BY
          f_metric,
          dates.f_date,
          dates.f_step
    )
  SELECT
    *,
    f_date :: VARCHAR(20) AS f_string_date,
    -- for filtering in superset
    f_step :: VARCHAR(10) AS f_string_step -- for filtering in superset
  FROM (
         SELECT *
         FROM metrics_with_zero_step
         UNION ALL
         SELECT *
         FROM metrics_with_not_zero_step
       ) AS all_metrics
)
