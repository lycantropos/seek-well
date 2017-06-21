CREATE MATERIALIZED VIEW mv_pool_deposit_count AS (
  WITH
      t_all AS (
        SELECT
          DATE_TRUNC('month', f_date) :: DATE AS f_date,
          SUM(f_deposit_count)                AS f_deposit_count_all
        FROM
          mv_deposit
        GROUP BY
          DATE_TRUNC('month', f_date)
    ),
      bots AS (
        SELECT
          DATE_TRUNC('month', f_date) :: DATE AS f_date,
          SUM(f_deposit_count)                AS f_deposit_count_bots
        FROM
          mv_deposit
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 1
        GROUP BY
          DATE_TRUNC('month', f_date)
    ),
      live_players AS (
        SELECT
          DATE_TRUNC('month', f_date) :: DATE AS f_date,
          SUM(f_deposit_count)                AS f_deposit_count_live_players
        FROM
          mv_deposit
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 0
        GROUP BY
          DATE_TRUNC('month', f_date)
    ),
      house_players AS (
        SELECT
          DATE_TRUNC('month', f_date) :: DATE AS f_date,
          SUM(f_deposit_count)                AS f_deposit_count_house_players
        FROM
          mv_deposit
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 2
        GROUP BY
          DATE_TRUNC('month', f_date)
    ),
      test_players AS (
        SELECT
          DATE_TRUNC('month', f_date) :: DATE AS f_date,
          SUM(f_deposit_count)                AS f_deposit_count_test_players
        FROM
          mv_deposit
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 3
        GROUP BY
          DATE_TRUNC('month', f_date)
    ),
      all_dates AS (
        SELECT generate_series(min(f_date), max(f_date),
                               '1 month') :: DATE AS f_date
        FROM
          t_all
    ),
      with_gaps AS (
        SELECT
          f_date                                     AS f_date,
          COALESCE(f_deposit_count_all, 0)           AS f_deposit_count_all,
          COALESCE(f_deposit_count_bots, 0)          AS f_deposit_count_bots,
          COALESCE(f_deposit_count_live_players,
                   0)                                AS f_deposit_count_live_players,
          COALESCE(f_deposit_count_house_players,
                   0)                                AS f_deposit_count_house_players,
          COALESCE(f_deposit_count_test_players,
                   0)                                AS f_deposit_count_test_players
        FROM t_all
          FULL JOIN all_dates USING (f_date)
          LEFT JOIN bots USING (f_date)
          LEFT JOIN live_players USING (f_date)
          LEFT JOIN house_players USING (f_date)
          LEFT JOIN test_players USING (f_date)
    ),
      cumulative_sum AS (
        SELECT
          f_date,
          SUM(f_deposit_count_all)
          OVER w AS f_deposit_count_all,
          SUM(f_deposit_count_bots)
          OVER w AS f_deposit_count_bots,
          SUM(f_deposit_count_live_players)
          OVER w AS f_deposit_count_live_players,
          SUM(f_deposit_count_house_players)
          OVER w AS f_deposit_count_house_players,
          SUM(f_deposit_count_test_players)
          OVER w AS f_deposit_count_test_players
        FROM
          with_gaps
        WINDOW w AS (
          ORDER BY f_date
        )
    ),
      with_ids AS (
        SELECT
          f_date,

          f_deposit_count_all,
          COUNT(f_deposit_count_all)
          OVER w AS f_deposit_count_all_id,

          f_deposit_count_bots,
          COUNT(f_deposit_count_bots)
          OVER w AS f_deposit_count_bots_id,

          f_deposit_count_live_players,
          COUNT(f_deposit_count_live_players)
          OVER w AS f_deposit_count_live_players_id,

          f_deposit_count_house_players,
          COUNT(f_deposit_count_house_players)
          OVER w AS f_deposit_count_house_players_id,

          f_deposit_count_test_players,
          COUNT(f_deposit_count_test_players)
          OVER w AS f_deposit_count_test_players_id
        FROM cumulative_sum
        WINDOW w AS (
          ORDER BY f_date
        )
    ),
      without_gaps AS (
        SELECT
          f_date,
          EXTRACT('year' FROM f_date)  AS f_year,
          EXTRACT('month' FROM f_date) AS f_month,

          COALESCE(f_deposit_count_all, first_value(f_deposit_count_all)
          OVER (PARTITION BY f_deposit_count_all_id
            ORDER BY f_date)
          )                            AS f_deposit_count_all,

          COALESCE(f_deposit_count_bots, first_value(f_deposit_count_bots)
          OVER (PARTITION BY f_deposit_count_bots_id
            ORDER BY f_date)
          )                            AS f_deposit_count_bots,

          COALESCE(f_deposit_count_live_players,
                   first_value(f_deposit_count_live_players)
                   OVER (PARTITION BY f_deposit_count_live_players_id
                     ORDER BY f_date)
          )                            AS f_deposit_count_live_players,

          COALESCE(f_deposit_count_house_players,
                   first_value(f_deposit_count_house_players)
                   OVER (PARTITION BY f_deposit_count_house_players_id
                     ORDER BY f_date)
          )                            AS f_deposit_count_house_players,

          COALESCE(f_deposit_count_test_players,
                   first_value(f_deposit_count_test_players)
                   OVER (PARTITION BY f_deposit_count_test_players_id
                     ORDER BY f_date)
          )                            AS f_deposit_count_test_players
        FROM with_ids
    ),
      last_4_month AS (
        SELECT GENERATE_SERIES(
                   GREATEST(
                       MIN(f_date),
                       DATE_TRUNC('month', MAX(f_date) - INTERVAL '3 months')
                       -- On one month less, because we include current month
                   ),
                   MAX(f_date),
                   '1 month'
               ) :: DATE AS f_date
        FROM
          t_all
    ),
      last_4_month_year_ago AS (
        SELECT GENERATE_SERIES(
                   GREATEST(
                       MIN(f_date),
                       DATE_TRUNC('month',
                                  MAX(f_date) - INTERVAL '1 year 3 months')
                       -- On one month less, because we include current month
                   ),
                   MAX(f_date) - INTERVAL '1 year',
                   '1 month'
               ) :: DATE AS f_date
        FROM
          t_all
    ),
      date_filter AS (
        SELECT f_date
        FROM last_4_month
          FULL JOIN last_4_month_year_ago USING (f_date)
    )
  SELECT without_gaps.*
  FROM without_gaps
    RIGHT JOIN date_filter USING (f_date)

);
