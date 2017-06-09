CREATE OR REPLACE VIEW v_cashouts AS (

    SELECT
        f_player_id,
        f_stamp::DATE AS f_date,
        (SUM(f_value)::NUMERIC / 100) AS f_cashouts
    FROM
        v_completed_transactions_on_real_money
    WHERE
        f_type IN (76, 87)
    GROUP BY
        f_player_id,
        f_date
    
);