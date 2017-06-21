CREATE MATERIALIZED VIEW mv_cash_games_by_pools AS (

  WITH
      last_game AS (
        SELECT MAX(g.f_started_stamp) AS last_game_stamp
        FROM
          t_game AS g,
          t_participation AS p,
          t_table AS t
        WHERE
          g.f_id = p.f_game_id AND
          g.f_table_id = t.f_id AND
          t.f_money_type = 'R'
    ),
      all_games_filtered AS (
        SELECT
          g.f_id,
          (t.f_high_bet :: FLOAT / 100)         AS f_limit,
          DATE_TRUNC('hour', g.f_started_stamp) AS f_stamp,
          (p.f_rake :: NUMERIC / 1000 / 100)    AS f_rake,
          -- p.f_rake in 1/1000 of cent. f_value in dollars
          p.f_player_id
        FROM
          t_game AS g,
          t_participation AS p,
          t_table AS t,
          last_game AS lg
        WHERE
          g.f_started_stamp >= lg.last_game_stamp - INTERVAL '7 days' AND
          g.f_id = p.f_game_id AND
          g.f_table_id = t.f_id AND
          t.f_money_type = 'R'
    ),
      games_with_bots_count AS (
        SELECT
          f_id,
          f_limit,
          f_stamp,
          SUM(f_rake)                 AS f_rake,
          COUNT(DISTINCT f_player_id) AS f_bots_count
        FROM
          all_games_filtered
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 1
        GROUP BY
          f_id,
          f_limit,
          f_stamp
    ),
      games_with_live_players_count AS (
        SELECT
          f_id,
          f_limit,
          f_stamp,
          SUM(f_rake)                 AS f_rake,
          COUNT(DISTINCT f_player_id) AS f_players_count
        FROM
          all_games_filtered
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 0
        GROUP BY
          f_id,
          f_limit,
          f_stamp
    )
  SELECT
    f_limit :: VARCHAR(20),
    -- For filterbox in superset
    COALESCE(f_bots_count, 0)    AS f_bots_count,
    COALESCE(f_players_count, 0) AS f_players_count,
    SUM(
        COALESCE(p.f_rake, 0) +
        COALESCE(b.f_rake, 0)
    )                            AS f_rake,
    COUNT(DISTINCT f_id)         AS f_games
  FROM
    games_with_live_players_count AS p
    FULL JOIN
    games_with_bots_count AS b USING (f_id, f_limit, f_stamp)
  GROUP BY
    f_limit,
    f_bots_count,
    f_players_count

);
