CREATE MATERIALIZED VIEW mv_pool_avg_minutes_between_first_login_and_real_money_hand AS (
  WITH
      t_all AS (
        SELECT
          DATE_TRUNC('month', f_register_stamp) :: DATE AS f_date,
          AVG(f_minutes)                                AS f_avg_minutes_all
        FROM
          mv_minutes_between_first_login_and_real_money_hand
        GROUP BY
          DATE_TRUNC('month', f_register_stamp)
    ),
      bots AS (
        SELECT
          DATE_TRUNC('month', f_register_stamp) :: DATE AS f_date,
          AVG(f_minutes)                                AS f_avg_minutes_bots
        FROM
          mv_minutes_between_first_login_and_real_money_hand
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 1
        GROUP BY
          DATE_TRUNC('month', f_register_stamp)
    ),
      house_players AS (
        SELECT
          DATE_TRUNC('month', f_date) :: DATE AS f_date,
          AVG(f_minutes)                      AS f_avg_minutes_house_players
        FROM
          mv_minutes_between_first_login_and_real_money_hand
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 2 AND
          f_register_stamp >= '2016-10-01'
        GROUP BY
          DATE_TRUNC('month', f_date)
    ),
      test_players AS (
        SELECT
          DATE_TRUNC('month', f_register_stamp) :: DATE AS f_date,
          AVG(
              f_minutes)                                AS f_avg_minutes_test_players
        FROM
          mv_minutes_between_first_login_and_real_money_hand
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 3
        GROUP BY
          DATE_TRUNC('month', f_register_stamp)
    ),
      live_players AS (
        SELECT
          DATE_TRUNC('month', f_register_stamp) :: DATE AS f_date,
          AVG(
              f_minutes)                                AS f_avg_minutes_live_players
        FROM
          mv_minutes_between_first_login_and_real_money_hand
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 0
        GROUP BY
          DATE_TRUNC('month', f_register_stamp)
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
  SELECT
    f_date,
    EXTRACT('year' FROM f_date)  AS f_year,
    EXTRACT('month' FROM f_date) AS f_month,

    f_avg_minutes_all,
    f_avg_minutes_bots,
    f_avg_minutes_house_players,
    f_avg_minutes_test_players,
    f_avg_minutes_live_players
  FROM t_all
    JOIN date_filter USING (f_date)
    LEFT JOIN bots USING (f_date)
    LEFT JOIN house_players USING (f_date)
    LEFT JOIN test_players USING (f_date)
    LEFT JOIN live_players USING (f_date)
);
