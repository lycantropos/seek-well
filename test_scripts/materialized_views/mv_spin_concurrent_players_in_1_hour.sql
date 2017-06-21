CREATE MATERIALIZED VIEW mv_spin_concurrent_players_in_1_hour AS (

  WITH
      all_spin_players AS (
        SELECT DISTINCT
          DATE_TRUNC('minute', g.f_started_stamp) AS f_time,
          (tour.f_buy_in :: NUMERIC / 100)        AS f_limit,
          p.f_player_id
        FROM
          t_participation AS p,
          t_game AS g,
          t_table AS t,
          t_tournament AS tour
        WHERE
          p.f_game_id = g.f_id AND
          g.f_table_id = t.f_id AND
          t.f_tournament_id = tour.f_id AND
          tour.f_money_type = 'R' AND
          tour.f_tournament_type = 'G' AND
          tour.f_buy_in > 0 AND
          tour.f_prize_distribution = 'P' AND
          g.f_started_stamp >= '2017-01-01T00:00:00'
    ),
      min_time AS (
        SELECT DATE_TRUNC(
                   'hour',
                   GREATEST(
                       MIN(f_time),
                       MAX(f_time) - INTERVAL '7 day'
                   )
               ) AS f_min_time
        FROM
          all_spin_players
    ),
      all_spin_players_by_interval AS (
        SELECT
          date_trunc_by_interval(f_time, '1 hour') AS f_stamp,
          f_limit,
          COUNT(DISTINCT f_player_id)              AS f_all_players
        FROM
          all_spin_players,
          min_time
        WHERE
          f_time >= f_min_time
        GROUP BY
          f_stamp,
          f_limit
    ),
      live_spin_players AS (
        SELECT *
        FROM all_spin_players
          JOIN t_house_flag USING (f_player_id)
        WHERE f_house_flag = 0
    ),
      live_spin_players_by_interval AS (
        SELECT
          date_trunc_by_interval(f_time, '1 hour') AS f_stamp,
          f_limit,
          COUNT(DISTINCT f_player_id)              AS f_live_players
        FROM
          live_spin_players,
          min_time
        WHERE
          f_time >= f_min_time
        GROUP BY
          f_stamp,
          f_limit
    ),
      bot_spin_players AS (
        SELECT *
        FROM all_spin_players
          JOIN t_house_flag USING (f_player_id)
        WHERE f_house_flag = 1
    ),
      bot_spin_players_by_interval AS (
        SELECT
          date_trunc_by_interval(f_time, '1 hour') AS f_stamp,
          f_limit,
          COUNT(DISTINCT f_player_id)              AS f_bot_players
        FROM
          bot_spin_players,
          min_time
        WHERE
          f_time >= f_min_time
        GROUP BY
          f_stamp,
          f_limit
    ),
      house_spin_players AS (
        SELECT *
        FROM all_spin_players
          JOIN t_house_flag USING (f_player_id)
        WHERE f_house_flag = 2
    ),
      house_spin_players_by_interval AS (
        SELECT
          date_trunc_by_interval(f_time, '1 hour') AS f_stamp,
          f_limit,
          COUNT(DISTINCT f_player_id)              AS f_house_players
        FROM
          house_spin_players,
          min_time
        WHERE
          f_time >= f_min_time
        GROUP BY
          f_stamp,
          f_limit
    ),
      test_spin_players AS (
        SELECT *
        FROM all_spin_players
          JOIN t_house_flag USING (f_player_id)
        WHERE f_house_flag = 3
    ),
      test_spin_players_by_interval AS (
        SELECT
          date_trunc_by_interval(f_time, '1 hour') AS f_stamp,
          f_limit,
          COUNT(DISTINCT f_player_id)              AS f_test_players
        FROM
          test_spin_players,
          min_time
        WHERE
          f_time >= f_min_time
        GROUP BY
          f_stamp,
          f_limit
    )
  SELECT
    f_stamp,
    f_limit,
    f_all_players,
    COALESCE(f_live_players, 0)  AS f_live_players,
    COALESCE(f_bot_players, 0)   AS f_bot_players,
    COALESCE(f_house_players, 0) AS f_house_players,
    COALESCE(f_test_players, 0)  AS f_test_players
  FROM all_spin_players_by_interval
    LEFT JOIN live_spin_players_by_interval USING (f_stamp, f_limit)
    LEFT JOIN bot_spin_players_by_interval USING (f_stamp, f_limit)
    LEFT JOIN house_spin_players_by_interval USING (f_stamp, f_limit)
    LEFT JOIN test_spin_players_by_interval USING (f_stamp, f_limit)

);
