CREATE OR REPLACE VIEW v_cohort_game_activity AS (

    WITH
    games AS (
        SELECT
            f_player_id,
            f_date,
            COUNT(*) AS f_games_count
        FROM 
            mv_real_money_games
        GROUP BY 
            f_player_id,
            f_date
    ),
    rakes AS (
        SELECT
            f_player_id,
            f_date,
            COALESCE(f_cash_rake, 0) AS f_cash_rake,
            (COALESCE(f_SNG_rake, 0) + COALESCE(f_MTT_rake, 0)) AS f_tournament_rake,
            (COALESCE(f_cash_rake, 0) + COALESCE(f_SNG_rake, 0) + COALESCE(f_MTT_rake, 0)) AS f_total_rake
        FROM
            v_cash_rake
        FULL JOIN 
            v_tournament_rake USING(f_player_id, f_date)
    ),
    total_profit AS (
        SELECT
            player_id AS f_player_id,
            (stamp::DATE) AS f_date,
            SUM(transaction_value::NUMERIC / 100) AS f_total_profit
        FROM 
            profit_balances
        WHERE
            increment_type = 'TotalProfit'
        GROUP BY
            player_id,
            stamp::DATE
    )
    SELECT 
        f_player_id,
        f_date,
        
        g.f_games_count,
        
        COALESCE(r.f_cash_rake, 0) AS f_cash_rake,
        COALESCE(r.f_tournament_rake, 0) AS f_tournament_rake,
        COALESCE(r.f_total_rake, 0) AS f_total_rake,

        COALESCE(tp.f_total_profit, 0) AS f_total_profit,
        
        reg.f_register_date,
        reg.f_register_date_cohort,

        (CASE
            WHEN g.f_games_count >= 5000 THEN '>= 5000'
            WHEN g.f_games_count >= 2000 THEN '>= 2000'
            WHEN g.f_games_count >= 1000 THEN '>= 1000'
            WHEN g.f_games_count >= 500 THEN '>= 500'
            WHEN g.f_games_count >= 100 THEN '>= 100'
            WHEN g.f_games_count >= 50 THEN '>= 50'
            WHEN g.f_games_count >= 10 THEN '>= 10'
            WHEN g.f_games_count >= 1 THEN '>= 1'
            ELSE '0'
        END) AS f_games_count_cohort,
        
        (CASE
            WHEN r.f_total_rake >= 100 THEN '>= 100$'
            WHEN r.f_total_rake >= 50 THEN '>= 50$'
            WHEN r.f_total_rake >= 10 THEN '>= 10$'
            WHEN r.f_total_rake >= 5 THEN '>= 5$'
            WHEN r.f_total_rake >= 1 THEN '>= 1$'
            WHEN r.f_total_rake >= 0.1 THEN '>= 0.1$'
            WHEN r.f_total_rake >= 0.01 THEN '>= 0.01$'
            ELSE '< 0.01'
        END) AS f_total_rake_cohort,
        
        (CASE 
            WHEN tp.f_total_profit >= 1000 THEN '>= 1000$'
            WHEN tp.f_total_profit >= 500 THEN '< 1000$'
            WHEN tp.f_total_profit >= 200 THEN '< 500$'
            WHEN tp.f_total_profit >= 100 THEN '< 200$'
            WHEN tp.f_total_profit >= 50 THEN '< 100$'
            WHEN tp.f_total_profit >= 10 THEN '< 50$'
            WHEN COALESCE(tp.f_total_profit, 0) >= 0 THEN '< 10$'
            WHEN tp.f_total_profit >= -100 THEN '< 0$'
            WHEN tp.f_total_profit >= -200 THEN '< -100$'
            WHEN tp.f_total_profit >= -500 THEN '< -200$'
            ELSE '< -500$'
        END) AS f_total_profit_cohort,

        m.f_group_activity_id
    FROM
        games AS g
    LEFT JOIN
        rakes AS r USING(f_player_id, f_date)
    LEFT JOIN
        total_profit AS tp USING(f_player_id, f_date)
    LEFT JOIN
        v_cohort_registration AS reg USING(f_player_id)
    LEFT JOIN
        v_cohort_matching AS m USING(f_player_id)
    
);