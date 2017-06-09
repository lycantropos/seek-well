CREATE OR REPLACE VIEW v_avg_stake AS (

    WITH
    t_cash_table_with_bb AS (
        SELECT
            f_id,
            f_high_bet AS f_bb
        FROM
            t_table
        WHERE
            f_money_type = 'R'
    ),
    t_cash_games_with_bb AS (
        SELECT 
            g.f_id,
            g.f_ended_stamp AS f_game_stamp,
            f_bb
        FROM
            t_cash_table_with_bb AS t,
            t_game AS g
        WHERE
            g.f_table_id = t.f_id
    ),
    t_player_cash_games_with_bb AS (
        SELECT
            p.f_player_id,
            p.f_game_id,
            cg.f_game_stamp::DATE AS f_date,
            (cg.f_bb::NUMERIC / 100) AS f_stake  -- in dollars
        FROM
            t_participation AS p,
            t_cash_games_with_bb AS cg
        WHERE
            p.f_game_id = cg.f_id
    )
    SELECT DISTINCT
        f_player_id,
        f_date,
        AVG(f_stake) OVER (
            PARTITION BY 
                f_player_id
            ORDER BY
                f_player_id,
                f_date
        ) AS f_avg_stake
    FROM 
        t_player_cash_games_with_bb

);