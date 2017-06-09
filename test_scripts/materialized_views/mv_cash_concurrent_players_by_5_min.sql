CREATE MATERIALIZED VIEW mv_cash_concurrent_players_by_5_min AS (

    WITH 
    all_cash_players_games AS (
        SELECT DISTINCT
            DATE_TRUNC('minute', g.f_started_stamp) AS f_started_stamp,
            DATE_TRUNC('minute', g.f_ended_stamp) AS f_ended_stamp,
            (t.f_high_bet::NUMERIC / 100) AS f_limit,
            p.f_player_id 
        FROM 
            t_participation AS p,
            t_game AS g,
            t_table AS t 
        WHERE 
            p.f_game_id = g.f_id AND
            g.f_table_id = t.f_id AND
            g.f_started_stamp >= '2017-01-01T00:00:00' AND 
            t.f_money_type='R'
    ),
    all_time_slices AS (
        SELECT
            GENERATE_SERIES(
                DATE_TRUNC(
                    'hour',
                    GREATEST(
                        MIN(f_started_stamp),
                        MAX(f_ended_stamp) - INTERVAL '1 day'
                    )
                ),
                MAX(f_ended_stamp),
                '5 min'
            ) AS f_stamp
        FROM 
            all_cash_players_games
    ),
    all_cash_players_by_interval AS (
        SELECT 
            ts.f_stamp,
            g.f_limit,
            COUNT(DISTINCT g.f_player_id) AS f_all_players
        FROM 
            all_cash_players_games AS g,
            all_time_slices AS ts
        WHERE
            g.f_started_stamp <= ts.f_stamp AND
            g.f_ended_stamp >= ts.f_stamp
        GROUP BY 
            f_stamp,
            f_limit
    ),
    bot_cash_players_games AS (
        SELECT *
        FROM all_cash_players_games
        JOIN t_house_flag USING (f_player_id)
        WHERE f_house_flag = 1
    ),
    bot_cash_players_by_interval AS (
        SELECT 
            ts.f_stamp,
            g.f_limit,
            COUNT(DISTINCT g.f_player_id) AS f_bot_players
        FROM 
            bot_cash_players_games AS g,
            all_time_slices AS ts
        WHERE
            g.f_started_stamp <= ts.f_stamp AND
            g.f_ended_stamp >= ts.f_stamp
        GROUP BY 
            f_stamp,
            f_limit
    ),
    live_cash_players_games AS (
        SELECT *
        FROM all_cash_players_games
        JOIN t_house_flag USING (f_player_id)
        WHERE f_house_flag = 0
    ),
    live_cash_players_by_interval AS (
        SELECT 
            ts.f_stamp,
            g.f_limit,
            COUNT(DISTINCT g.f_player_id) AS f_live_players
        FROM 
            live_cash_players_games AS g,
            all_time_slices AS ts
        WHERE
            g.f_started_stamp <= ts.f_stamp AND
            g.f_ended_stamp >= ts.f_stamp
        GROUP BY 
            f_stamp,
            f_limit
    ),
    house_cash_players_games AS (
        SELECT *
        FROM all_cash_players_games
        JOIN t_house_flag USING (f_player_id)
        WHERE f_house_flag = 2
    ),
    house_cash_players_by_interval AS (
        SELECT 
            ts.f_stamp,
            g.f_limit,
            COUNT(DISTINCT g.f_player_id) AS f_house_players
        FROM 
            house_cash_players_games AS g,
            all_time_slices AS ts
        WHERE
            g.f_started_stamp <= ts.f_stamp AND
            g.f_ended_stamp >= ts.f_stamp
        GROUP BY 
            f_stamp,
            f_limit
    ),
    test_cash_players_games AS (
        SELECT *
        FROM all_cash_players_games
        JOIN t_house_flag USING (f_player_id)
        WHERE f_house_flag = 3
    ),
    test_cash_players_by_interval AS (
        SELECT 
            ts.f_stamp,
            g.f_limit,
            COUNT(DISTINCT g.f_player_id) AS f_test_players
        FROM 
            test_cash_players_games AS g,
            all_time_slices AS ts
        WHERE
            g.f_started_stamp <= ts.f_stamp AND
            g.f_ended_stamp >= ts.f_stamp
        GROUP BY 
            f_stamp,
            f_limit
    )
    SELECT
        f_stamp,
        f_limit,
        f_all_players,
        COALESCE(f_bot_players, 0) AS f_bot_players,
        COALESCE(f_live_players, 0) AS f_live_players,
        COALESCE(f_house_players, 0) AS f_house_players,
        COALESCE(f_test_players, 0) AS f_test_players
    FROM all_cash_players_by_interval
    LEFT JOIN bot_cash_players_by_interval USING (f_stamp, f_limit)
    LEFT JOIN live_cash_players_by_interval USING (f_stamp, f_limit)
    LEFT JOIN house_cash_players_by_interval USING (f_stamp, f_limit)
    LEFT JOIN test_cash_players_by_interval USING (f_stamp, f_limit)

);