CREATE OR REPLACE VIEW v_balance AS (

    SELECT 
        f_player_id,
        f_stamp::DATE AS f_date,
        (SUM(f_value)::NUMERIC / 100) AS f_balance -- in dollars
    FROM 
        v_completed_transactions_on_real_money
    GROUP BY 
        f_player_id,
        f_date
    
);

-- TODO: calculate as sum of other metrics in mv_player_state