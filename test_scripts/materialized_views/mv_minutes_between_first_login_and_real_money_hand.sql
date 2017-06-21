CREATE MATERIALIZED VIEW mv_minutes_between_first_login_and_real_money_hand AS (

  WITH
      t_first_real_money_hand AS (
        SELECT
          p.f_player_id,
          MIN(g.f_started_stamp) AS f_stamp
        FROM
          t_game AS g,
          t_participation AS p,
          v_real_money_tables AS rmt
        WHERE
          rmt.f_id = g.f_table_id AND
          g.f_id = p.f_game_id
        GROUP BY
          p.f_player_id
    ),
      t_first_login AS (
        SELECT
          f_player_id,
          MIN(f_start_stamp) AS f_stamp
        FROM
          t_sessions_log
        GROUP BY
          f_player_id
    )
  SELECT
    p.f_id                                AS f_player_id,
    h.f_stamp :: DATE                     AS f_date,
    p.f_register_stamp                    AS f_register_stamp,
    h.f_stamp                             AS first_hand_stamp,
    l.f_stamp                             AS first_login_stamp,
    diff_in_minutes(h.f_stamp, l.f_stamp) AS f_minutes
  FROM
    t_player AS p,
    t_first_real_money_hand AS h,
    t_first_login AS l
  WHERE
    l.f_player_id = h.f_player_id AND
    l.f_player_id = p.f_id

);
