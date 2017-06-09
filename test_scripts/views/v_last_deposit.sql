CREATE OR REPLACE VIEW v_last_deposit AS (

    SELECT DISTINCT ON (f_player_id, f_stamp::DATE)
        f_player_id,
        f_stamp::DATE AS f_date,
        (f_value::NUMERIC / 100) AS f_last_deposit
    FROM
        v_completed_transactions_on_real_money
    WHERE
        f_type = 68
    ORDER BY
        f_player_id,
        f_date DESC,
        f_stamp DESC

);