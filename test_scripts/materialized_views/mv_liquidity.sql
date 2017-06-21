CREATE MATERIALIZED VIEW mv_liquidity AS (

  WITH
      cash_games AS (
        SELECT
          g.f_started_stamp :: DATE    AS f_date,
          COUNT(g.f_id)                AS total_cash_hands,
          COUNT(DISTINCT g.f_table_id) AS total_cash_tables
        FROM
          t_game AS g,
          t_table AS t
        WHERE
          g.f_table_id = t.f_id AND
          g.f_started_stamp >= '2017-01-01T00:00:00' AND
          t.f_money_type = 'R'
        GROUP BY
          f_date
    ),
      bot_player AS (
        SELECT *
        FROM
          t_house_flag
        WHERE
          f_house_flag = 1
    ),
      bot_cash_games AS (
        SELECT
          g.f_started_stamp :: DATE      AS f_date,
          COUNT(DISTINCT (p.f_game_id))  AS bot_cash_hands,
          COUNT(DISTINCT (p.f_table_id)) AS bot_cash_tables
        FROM
          t_game AS g,
          t_participation AS p,
          t_table AS t,
          bot_player AS b
        WHERE
          g.f_id = p.f_game_id AND
          g.f_table_id = t.f_id AND
          p.f_player_id = b.f_player_id AND
          g.f_started_stamp >= '2017-01-01T00:00:00' AND
          t.f_money_type = 'R'
        GROUP BY
          f_date
    ),
      tour_SNG AS (
        SELECT
          tour.f_started_stamp :: DATE       AS f_date,
          COUNT(DISTINCT tour.f_id)          AS SNG_tournaments,
          SUM(tp.f_participated)             AS SNG_participants,
          (SUM(tp.f_prize) :: NUMERIC / 100) AS SNG_prizes --in dollars
        FROM
          t_tournament AS tour,
          t_player_in_tournament AS tp
        WHERE
          tour.f_id = tp.f_tournament_id AND
          tour.f_started_stamp > '2017-01-01T00:00:00' AND
          tour.f_money_type = 'R' AND
          tour.f_tournament_type = 'G' AND
          tour.f_buy_in > 0
        GROUP BY
          f_date
    ),
      bot_tour_SNG AS (
        SELECT
          tour.f_started_stamp :: DATE       AS f_date,
          COUNT(DISTINCT tour.f_id)          AS bot_SNG_tournaments,
          SUM(tp.f_participated)             AS bot_SNG_participants,
          (SUM(tp.f_prize) :: NUMERIC / 100) AS bot_SNG_prizes --in dollars
        FROM
          t_tournament AS tour,
          t_player_in_tournament AS tp,
          bot_player AS b
        WHERE
          tour.f_id = tp.f_tournament_id AND
          tp.f_player_id = b.f_player_id AND
          tour.f_started_stamp > '2017-01-01T00:00:00' AND
          tour.f_money_type = 'R' AND
          tour.f_tournament_type = 'G' AND
          tour.f_buy_in > 0
        GROUP BY
          f_date
    ),
      tour_MTT AS (
        SELECT
          tour.f_started_stamp :: DATE       AS f_date,
          COUNT(DISTINCT tour.f_id)          AS MTT_tournaments,
          SUM(tp.f_participated)             AS MTT_participants,
          (SUM(tp.f_prize) :: NUMERIC / 100) AS MTT_prizes --in dollars
        FROM
          t_tournament AS tour,
          t_player_in_tournament AS tp
        WHERE
          tour.f_id = tp.f_tournament_id AND
          tour.f_started_stamp > '2017-01-01T00:00:00' AND
          tour.f_money_type = 'R' AND
          tour.f_tournament_type = 'S' AND
          tour.f_buy_in > 0
        GROUP BY
          f_date
    ),
      bot_tour_MTT AS (
        SELECT
          tour.f_started_stamp :: DATE       AS f_date,
          COUNT(DISTINCT tour.f_id)          AS bot_MTT_tournaments,
          SUM(tp.f_participated)             AS bot_MTT_participants,
          (SUM(tp.f_prize) :: NUMERIC / 100) AS bot_MTT_prizes --in dollars
        FROM
          t_tournament AS tour,
          t_player_in_tournament AS tp,
          bot_player AS b
        WHERE
          tour.f_id = tp.f_tournament_id AND
          tp.f_player_id = b.f_player_id AND
          tour.f_started_stamp > '2017-01-01T00:00:00' AND
          tour.f_money_type = 'R' AND
          tour.f_buy_in > 0 AND
          tour.f_tournament_type = 'S'
        GROUP BY
          f_date
    ),
      dau AS (
        SELECT
          g.f_started_stamp :: DATE     AS f_date,
          COUNT(DISTINCT p.f_player_id) AS DAU
        FROM
          t_participation AS p,
          t_game AS g
        WHERE
          p.f_game_id = g.f_id AND
          g.f_started_stamp > '2017-01-01T00:00:00'
        GROUP BY
          f_date
    ),
      liquidity_with_base_metrics AS (
        SELECT
          f_date,

          COALESCE(cash_games.total_cash_hands, 0)       AS total_cash_hands,
          COALESCE(bot_cash_games.bot_cash_hands, 0)     AS bot_cash_hands,
          COALESCE(cash_games.total_cash_tables, 0)      AS total_cash_tables,
          COALESCE(bot_cash_games.bot_cash_tables, 0)    AS bot_cash_tables,

          COALESCE(tour_SNG.SNG_tournaments, 0)          AS SNG_tournaments,
          COALESCE(tour_SNG.SNG_participants, 0)         AS SNG_participants,
          COALESCE(tour_SNG.SNG_prizes, 0)               AS SNG_prizes,

          COALESCE(bot_tour_SNG.bot_SNG_tournaments,
                   0)                                    AS bot_SNG_tournaments,
          COALESCE(bot_tour_SNG.bot_SNG_participants,
                   0)                                    AS bot_SNG_participants,
          COALESCE(bot_tour_SNG.bot_SNG_prizes, 0)       AS bot_SNG_prizes,

          COALESCE(tour_MTT.MTT_tournaments, 0)          AS MTT_tournaments,
          COALESCE(tour_MTT.MTT_participants, 0)         AS MTT_participants,
          COALESCE(tour_MTT.MTT_prizes, 0)               AS MTT_prizes,

          COALESCE(bot_tour_MTT.bot_MTT_tournaments,
                   0)                                    AS bot_MTT_tournaments,
          COALESCE(bot_tour_MTT.bot_MTT_participants,
                   0)                                    AS bot_MTT_participants,
          COALESCE(bot_tour_MTT.bot_MTT_prizes, 0)       AS bot_MTT_prizes,

          COALESCE(dau.dau, 0)                           AS dau
        FROM cash_games
          FULL JOIN bot_cash_games USING (f_date)
          FULL JOIN tour_SNG USING (f_date)
          FULL JOIN bot_tour_SNG USING (f_date)
          FULL JOIN tour_MTT USING (f_date)
          FULL JOIN bot_tour_MTT USING (f_date)
          FULL JOIN dau USING (f_date)
    )
  SELECT
    *,
    (total_cash_hands - bot_cash_hands)       AS cash_hands_without_bots,

    (MTT_tournaments - bot_MTT_tournaments)   AS MTT_tournaments_without_bots,
    (MTT_participants - bot_MTT_participants) AS MTT_participants_without_bots,
    (MTT_prizes - bot_MTT_prizes)             AS MTT_prizes_without_bots,

    (SNG_tournaments - bot_SNG_tournaments)   AS SNG_tournaments_without_bots,
    (SNG_participants - bot_SNG_participants) AS SNG_participants_without_bots,
    (SNG_prizes - bot_SNG_prizes)             AS SNG_prizes_without_bots
  FROM
    liquidity_with_base_metrics

);
