CREATE MATERIALIZED VIEW mv_spin_tournaments_by_pools AS (

  WITH
      last_tournament AS (
        SELECT MAX(t.f_started_stamp) AS last_tournament_stamp
        FROM
          t_tournament t,
          t_player_in_tournament tp
        WHERE
          t.f_id = tp.f_tournament_id AND
          t.f_tournament_type = 'G' AND
          t.f_prize_distribution = 'P' AND
          t.f_money_type = 'R' AND
          t.f_buy_in > 0
    ),
      all_tournaments_filtered AS (
        SELECT
          t.f_id,
          ((t.f_buy_in + t.f_entry_fee) :: FLOAT / 100) AS f_buy_in,
          DATE_TRUNC('hour', t.f_started_stamp)         AS f_stamp,
          tp.f_player_id
        FROM
          last_tournament AS lg,
          t_tournament t,
          t_player_in_tournament tp
        WHERE
          t.f_started_stamp >= last_tournament_stamp - INTERVAL '7 days' AND
          t.f_id = tp.f_tournament_id AND
          t.f_tournament_type = 'G' AND
          t.f_prize_distribution = 'P' AND
          t.f_money_type = 'R' AND
          t.f_buy_in > 0
    ),
      tournaments_with_bots_count AS (
        SELECT
          f_id,
          f_buy_in,
          f_stamp,
          COUNT(DISTINCT f_player_id) AS f_bots_count
        FROM
          all_tournaments_filtered
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 1
        GROUP BY
          f_id,
          f_buy_in,
          f_stamp
    ),
      tournaments_with_live_players_count AS (
        SELECT
          f_id,
          f_buy_in,
          f_stamp,
          COUNT(DISTINCT f_player_id) AS f_players_count
        FROM
          all_tournaments_filtered
          JOIN
          t_house_flag USING (f_player_id)
        WHERE
          t_house_flag.f_house_flag = 0
        GROUP BY
          f_id,
          f_buy_in,
          f_stamp
    )
  SELECT
    f_buy_in :: VARCHAR(20),
    -- For filterbox in superset
    COALESCE(f_bots_count, 0)    AS f_bots_count,
    COALESCE(f_players_count, 0) AS f_players_count,
    COUNT(DISTINCT f_id)         AS f_tournaments
  FROM
    tournaments_with_live_players_count
    FULL JOIN
    tournaments_with_bots_count USING (f_id, f_buy_in, f_stamp)
  GROUP BY
    f_buy_in,
    f_bots_count,
    f_players_count

);
