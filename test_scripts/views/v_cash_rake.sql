CREATE OR REPLACE VIEW v_cash_rake AS (

    SELECT
        p.f_player_id,
        t.f_stamp::DATE AS f_date,
        (SUM(p.f_rake)::NUMERIC / 1000 / 100) AS f_cash_rake  -- p.f_rake in 1/1000 of cent. f_value in dollars
    FROM 
        t_participation AS p,
        v_completed_transactions_on_real_money AS t
    WHERE
        t.f_param_game_id = p.f_game_id AND
        t.f_type = 75
    GROUP BY 
        p.f_player_id,
        f_date

);