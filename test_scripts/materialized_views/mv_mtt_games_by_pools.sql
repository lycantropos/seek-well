CREATE MATERIALIZED VIEW mv_mtt_games_by_pools AS (

  WITH
      last_game AS (
        SELECT MAX(g.f_started_stamp) AS last_game_stamp
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
          tour.f_tournament_type = 'S' AND
          tour.f_buy_in > 0
    ),
      all_games_filtered AS (
        SELECT
          g.f_id,
          tour.f_name,
          DATE_TRUNC('hour', g.f_started_stamp)           AS f_stamp,
          p.f_player_id,
          (SUM(COALESCE(tr.f_value, 0) :: NUMERIC /
               100))                                      AS f_rake -- in dollars
        FROM
          last_game AS lg,
          t_participation AS p,
          t_game AS g,
          t_table AS t,
          t_tournament AS tour
          FULL JOIN
          v_completed_transactions_on_real_money AS tr
            ON
              tour.f_id = tr.f_param_tournament_id AND
              tr.f_type IN (69, 71, 510, 511)
        WHERE
          g.f_started_stamp >= lg.last_game_stamp - INTERVAL '7 days' AND
          p.f_game_id = g.f_id AND
          g.f_table_id = t.f_id AND
          t.f_tournament_id = tour.f_id AND
          tour.f_money_type = 'R' AND
          tour.f_tournament_type = 'S' AND
          tour.f_buy_in > 0
        GROUP BY
          g.f_id,
          tour.f_name,
          DATE_TRUNC('hour', g.f_started_stamp),
          p.f_player_id
    ),
      games_with_bots_count AS (
        SELECT
          f_id,
          f_name,
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
          f_name,
          f_stamp
    ),
      games_with_live_players_count AS (
        SELECT
          f_id,
          f_name,
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
          f_name,
          f_stamp
    )
  SELECT
    f_name :: VARCHAR(40),
    -- For filterbox in superset
    COALESCE(f_bots_count, 0)    AS f_bots_count,
    COALESCE(f_players_count, 0) AS f_players_count,
    COUNT(DISTINCT f_id)         AS f_games,
    SUM(
        COALESCE(p.f_rake, 0) +
        COALESCE(b.f_rake, 0)
    )                            AS f_rake
  FROM
    games_with_live_players_count AS p
    FULL JOIN
    games_with_bots_count AS b USING (f_id, f_name, f_stamp)
  GROUP BY
    f_name,
    f_bots_count,
    f_players_count

);
