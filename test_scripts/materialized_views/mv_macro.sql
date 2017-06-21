CREATE MATERIALIZED VIEW mv_macro AS (

  WITH
      filtered_money_transactions AS (
        SELECT *
        FROM v_completed_transactions_on_real_money
        WHERE f_stamp >= '2017-01-01T00:00:00'
    ),
      room_player AS (
        SELECT *
        FROM
          t_house_flag
        WHERE
          f_house_flag = 4
    ),
      bot_player AS (
        SELECT *
        FROM
          t_house_flag
        WHERE
          f_house_flag = 1
    ),
      house_player AS (
        SELECT *
        FROM
          t_house_flag
        WHERE
          f_house_flag = 2
    ),
      bot_money_transactions AS (
        SELECT t.*
        FROM
          filtered_money_transactions AS t,
          bot_player AS b
        WHERE
          b.f_player_id = t.f_player_id
    ),
      house_money_transactions AS (
        SELECT t.*
        FROM
          filtered_money_transactions AS t,
          house_player AS h
        WHERE
          h.f_player_id = t.f_player_id
    ),
      game AS (
        SELECT
          f_started_stamp :: DATE    AS f_date,
          COUNT(f_id)                AS hands,
          COUNT(DISTINCT f_table_id) AS tables
        FROM
          t_game
        WHERE
          f_started_stamp >= '2017-01-01T00:00:00'
        GROUP BY
          f_date
    ),
      tour_SNG AS (
        SELECT
          f_started_stamp :: DATE AS f_date,
          COUNT(DISTINCT f_id)    AS SNG_tournaments
        FROM
          t_tournament tour
        WHERE
          f_money_type = 'R' AND
          f_tournament_type = 'G' AND
          f_buy_in > 0 AND
          f_started_stamp > '2017-01-01T00:00:00'
        GROUP BY
          f_date
    ),
      tour_MTT AS (
        SELECT
          tour.f_started_stamp :: DATE AS f_date,
          COUNT(DISTINCT tour.f_id)    AS MTT_tournaments
        FROM
          t_tournament tour
        WHERE
          tour.f_money_type = 'R' AND
          f_tournament_type = 'S' AND
          tour.f_buy_in > 0 AND
          tour.f_started_stamp > '2017-01-01T00:00:00'
        GROUP BY
          f_date
    ),
      registrations AS (
        SELECT DISTINCT
          f_date,
          MAX(players) AS registrations
        FROM (
               SELECT DISTINCT
                 tt.f_register_stamp :: DATE AS f_date,
                 COUNT(tt.f_id) + (
                   SELECT COUNT(DISTINCT f_id) AS client_base
                   FROM
                     t_player AS pp -- FIXME
                   WHERE
                     pp.f_register_stamp <= tt.f_register_stamp
                 )                           AS players
               FROM
                 t_player AS tt -- FIXME
               WHERE
                 f_register_stamp > '2017-01-01T00:00:00'
               GROUP BY
                 f_register_stamp
             ) AS foo
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
      cash_rake AS (
        SELECT
          f_stamp :: DATE               AS f_date,
          SUM(f_value) :: NUMERIC / 100 AS cash_rake
        FROM
          filtered_money_transactions
        WHERE
          f_type = 75
        GROUP BY
          f_date
    ),
      bot_cash_rake AS (
        SELECT
          t.f_stamp :: DATE                     AS f_date,
          SUM(p.f_rake) :: NUMERIC / 1000 / 100 AS bot_cash_rake
        FROM
          t_participation AS p,
          filtered_money_transactions AS t,
          bot_player AS b
        WHERE
          t.f_param_game_id = p.f_game_id AND
          b.f_player_id = p.f_player_id AND
          t.f_type = 75
        GROUP BY
          f_date
    ),
      house_cash_rake AS (
        SELECT
          t.f_stamp :: DATE                     AS f_date,
          SUM(p.f_rake) :: NUMERIC / 1000 / 100 AS house_cash_rake
        FROM
          t_participation AS p,
          filtered_money_transactions AS t,
          house_player AS h
        WHERE
          t.f_param_game_id = p.f_game_id AND
          h.f_player_id = p.f_player_id AND
          t.f_type = 75
        GROUP BY
          f_date
    ),
      tournament_rake AS (
        SELECT
          f_stamp :: DATE               AS f_date,
          SUM(f_value) :: NUMERIC / 100 AS tournament_rake
        FROM
          filtered_money_transactions
        WHERE
          f_type IN (69, 71, 510, 511)
        GROUP BY
          f_date
    ),
      bot_tournament_rake AS (
        SELECT
          t.f_stamp :: DATE               AS f_date,
          SUM(t.f_value) :: NUMERIC / 100 AS bot_tournament_rake
        FROM
          filtered_money_transactions AS t,
          bot_player AS p
        WHERE
          t.f_type IN (69, 71, 510, 511) AND
          t.f_param_player_id = p.f_player_id
        GROUP BY
          f_date
    ),
      house_tournament_rake AS (
        SELECT
          t.f_stamp :: DATE               AS f_date,
          SUM(t.f_value) :: NUMERIC / 100 AS house_tournament_rake
        FROM
          filtered_money_transactions AS t,
          house_player AS p
        WHERE
          t.f_type IN (69, 71, 510, 511) AND
          t.f_param_player_id = p.f_player_id
        GROUP BY
          f_date
    ),
      bot_cash_profit AS (
        SELECT
          f_stamp :: DATE               AS f_date,
          SUM(f_value) :: NUMERIC / 100 AS bot_cash_profit
        FROM
          bot_money_transactions
        WHERE
          f_type IN (70, 84)
        GROUP BY
          f_date
    ),
      bot_tour_profit AS (
        SELECT
          f_stamp :: DATE               AS f_date,
          SUM(f_value) :: NUMERIC / 100 AS bot_tour_profit
        FROM
          bot_money_transactions
        WHERE
          f_type IN (49, 82, 80, 66, 67, 510, 511)
        GROUP BY
          f_date
    ),
      house_cash_profit AS (
        SELECT
          f_stamp :: DATE               AS f_date,
          SUM(f_value) :: NUMERIC / 100 AS house_cash_profit
        FROM
          house_money_transactions
        WHERE
          f_type IN (70, 84)
        GROUP BY
          f_date
    ),
      house_tour_profit AS (
        SELECT
          f_stamp :: DATE               AS f_date,
          SUM(f_value) :: NUMERIC / 100 AS house_tour_profit
        FROM
          house_money_transactions
        WHERE
          f_type IN (49, 82, 80, 66, 67, 510, 511)
        GROUP BY
          f_date
    ),
      deposit AS (
        SELECT
          f_stamp :: DATE               AS f_date,
          SUM(f_value) :: NUMERIC / 100 AS deposit
        FROM
          filtered_money_transactions
        WHERE
          f_type = 68
        GROUP BY
          f_date
    ),
      cashout AS (
        SELECT
          f_stamp :: DATE               AS f_date,
          SUM(f_value) :: NUMERIC / 100 AS cashout
        FROM
          filtered_money_transactions
        WHERE
          f_type IN (76, 87)
        GROUP BY
          f_date
    ),
      balance AS (
        SELECT
          t.f_stamp :: DATE               AS f_date,
          SUM(t.f_value) :: NUMERIC / 100 AS balance
        FROM
          filtered_money_transactions AS t
          LEFT JOIN
          room_player AS p
            ON
              t.f_player_id = p.f_player_id
        WHERE
          p.f_player_id IS NULL
        GROUP BY
          f_date
    ),
      room_balance AS (
        SELECT
          t.f_stamp :: DATE               AS f_date,
          SUM(t.f_value) :: NUMERIC / 100 AS room_balance
        FROM
          filtered_money_transactions AS t,
          room_player AS p
        WHERE
          t.f_player_id = p.f_player_id
        GROUP BY
          f_date
    ),
      bot_balance AS (
        SELECT
          f_stamp :: DATE               AS f_date,
          SUM(f_value) :: NUMERIC / 100 AS bot_balance
        FROM
          bot_money_transactions
        GROUP BY
          f_date
    ),
      house_balance AS (
        SELECT
          f_stamp :: DATE               AS f_date,
          SUM(f_value) :: NUMERIC / 100 AS house_balance
        FROM
          house_money_transactions
        GROUP BY
          f_date
    ),
      daily_macro_base_metrics AS (
        SELECT
          f_date,

          COALESCE(dau.dau, 0)                                     AS dau,
          COALESCE(registrations.registrations,
                   0)                                              AS registrations,

          COALESCE(game.hands, 0)                                  AS hands,
          COALESCE(game.tables, 0)                                 AS tables,

          COALESCE(tour_SNG.SNG_tournaments,
                   0)                                              AS SNG_tournaments,
          COALESCE(tour_MTT.MTT_tournaments,
                   0)                                              AS MTT_tournaments,

          COALESCE(deposit.deposit, 0)                             AS deposit,
          COALESCE(cashout.cashout, 0)                             AS cashout,

          COALESCE(balance.balance, 0)                             AS balance,
          COALESCE(room_balance.room_balance,
                   0)                                              AS room_balance,
          COALESCE(bot_balance.bot_balance,
                   0)                                              AS bot_balance,
          COALESCE(house_balance.house_balance,
                   0)                                              AS house_balance,

          COALESCE(bot_cash_profit.bot_cash_profit,
                   0)                                              AS bot_cash_profit,
          COALESCE(house_cash_profit.house_cash_profit,
                   0)                                              AS house_cash_profit,
          COALESCE(bot_tour_profit.bot_tour_profit,
                   0)                                              AS bot_tour_profit,
          COALESCE(house_tour_profit.house_tour_profit,
                   0)                                              AS house_tour_profit,

          COALESCE(cash_rake.cash_rake,
                   0)                                              AS cash_rake,
          COALESCE(bot_cash_rake.bot_cash_rake,
                   0)                                              AS bot_cash_rake,
          COALESCE(house_cash_rake.house_cash_rake,
                   0)                                              AS house_cash_rake,

          COALESCE(tournament_rake.tournament_rake,
                   0)                                              AS tournament_rake,
          COALESCE(bot_tournament_rake.bot_tournament_rake,
                   0)                                              AS bot_tournament_rake,
          COALESCE(house_tournament_rake.house_tournament_rake,
                   0)                                              AS house_tournament_rake
        FROM dau
          FULL JOIN deposit USING (f_date)

          FULL JOIN cash_rake USING (f_date)
          FULL JOIN bot_cash_rake USING (f_date)
          FULL JOIN house_cash_rake USING (f_date)

          FULL JOIN tournament_rake USING (f_date)
          FULL JOIN bot_tournament_rake USING (f_date)
          FULL JOIN house_tournament_rake USING (f_date)

          FULL JOIN cashout USING (f_date)

          FULL JOIN room_balance USING (f_date)
          FULL JOIN balance USING (f_date)
          FULL JOIN bot_balance USING (f_date)
          FULL JOIN house_balance USING (f_date)

          FULL JOIN bot_cash_profit USING (f_date)
          FULL JOIN bot_tour_profit USING (f_date)

          FULL JOIN house_cash_profit USING (f_date)
          FULL JOIN house_tour_profit USING (f_date)

          FULL JOIN game USING (f_date)

          FULL JOIN tour_SNG USING (f_date)
          FULL JOIN tour_MTT USING (f_date)

          FULL JOIN registrations USING (f_date)
    ),
      daily_macro_with_extra_metrics AS (
        SELECT
          *,
          (cash_rake + tournament_rake)         AS total_rake,
          (bot_cash_rake + bot_tournament_rake) AS bot_rake
        FROM
          daily_macro_base_metrics
    ),
      daily_macro_with_live_rake AS (
        SELECT
          *,
          (total_rake - bot_rake) AS live_rake
        FROM
          daily_macro_with_extra_metrics
    ),
      daily_macro_with_cumulative_base_metrics AS (
        SELECT
          f_date,
          dau,
          registrations,

          hands,
          tables,
          SNG_tournaments,
          MTT_tournaments,

          total_rake,
          bot_rake,
          live_rake,

          SUM(deposit)
          OVER w AS cumulative_deposit,
          SUM(cashout)
          OVER w AS cumulative_cashout,

          SUM(balance)
          OVER w AS cumulative_balance,
          SUM(room_balance)
          OVER w AS cumulative_room_balance,
          SUM(bot_balance)
          OVER w AS cumulative_bot_balance,
          SUM(house_balance)
          OVER w AS cumulative_house_balance,

          SUM(bot_cash_profit)
          OVER w AS cumulative_bot_cash_profit,
          SUM(house_cash_profit)
          OVER w AS cumulative_house_cash_profit,

          SUM(bot_tour_profit)
          OVER w AS cumulative_bot_tour_profit,
          SUM(house_tour_profit)
          OVER w AS cumulative_house_tour_profit,

          SUM(cash_rake)
          OVER w AS cumulative_cash_rake,
          SUM(bot_cash_rake)
          OVER w AS cumulative_bot_cash_rake,
          SUM(house_cash_rake)
          OVER w AS cumulative_house_cash_rake,

          SUM(total_rake)
          OVER w AS cumulative_total_rake,
          SUM(bot_rake)
          OVER w AS cumulative_bot_rake,
          SUM(live_rake)
          OVER w AS cumulative_live_rake,

          SUM(tournament_rake)
          OVER w AS cumulative_tournament_rake,
          SUM(bot_tournament_rake)
          OVER w AS cumulative_bot_tournament_rake,
          SUM(house_tournament_rake)
          OVER w AS cumulative_house_tournament_rake
        FROM
          daily_macro_with_live_rake
        WINDOW w AS (
          ORDER BY
            f_date
        )
    ),
      daily_macro_with_extra_cumulative_metrics AS (
        SELECT
          *,
          (cumulative_bot_cash_profit +
           cumulative_bot_tour_profit)                                  AS cumulative_bot_profit,
          (cumulative_house_cash_profit +
           cumulative_house_tour_profit)                                AS cumulative_house_profit,
          (cumulative_balance -
           cumulative_bot_balance)                                      AS cumulative_live_balance,
          (cumulative_room_balance +
           cumulative_bot_balance)                                      AS cumulative_revenue
        FROM
          daily_macro_with_cumulative_base_metrics
    )
  SELECT
    *,
    (cumulative_bot_profit +
     cumulative_bot_rake) AS cumulative_bot_profit_and_rake
  FROM
    daily_macro_with_extra_cumulative_metrics

);
