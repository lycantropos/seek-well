CREATE OR REPLACE VIEW v_loyalty AS (

    SELECT 
        f_player_id,
        f_stamp::DATE AS f_date,
        (SUM(f_value)::NUMERIC / 100) AS f_loyalty -- in dollars
    FROM 
        v_completed_transactions_on_real_money
    WHERE 
        f_type in (50, 51, 90, 520, 521, 530, 531, 540, 541, 550, 551)
    GROUP BY 
        f_player_id,
        f_date
        
);