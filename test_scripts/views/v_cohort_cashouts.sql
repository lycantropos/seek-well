CREATE OR REPLACE VIEW v_cohort_cashouts AS (

    WITH
    cashouts AS (
        SELECT
            player_id AS f_player_id,
            (stamp::DATE) AS f_date,
            ABS(transaction_value::NUMERIC / 100) AS f_cashout,
            ABS(increment_value::NUMERIC / 100) AS f_cashout_profit_increment_value,
            (CASE
                WHEN transaction_value = 0 THEN 0
                ELSE (increment_value / transaction_value)
            END) AS f_cashout_profit_increment_percent
        FROM 
            profit_balances
        WHERE
            increment_type = 'CashoutProfit'
    )
    SELECT 
        f_player_id,
        d.f_date,
        d.f_cashout,
        d.f_cashout_profit_increment_value,
        r.f_register_date,
        r.f_register_date_cohort,
        (CASE 
            WHEN d.f_cashout > 500 THEN '> 500$'
            WHEN d.f_cashout > 100 THEN '100$-500$'
            WHEN d.f_cashout > 50 THEN '50$-100$'
            WHEN d.f_cashout > 20 THEN '20$-50$'
            WHEN d.f_cashout > 10 THEN '10$-20$'
            ELSE '<= 10$'
        END) AS f_cashout_cohort,
        (CASE 
            WHEN d.f_cashout_profit_increment_percent > .7 THEN '> 70%'
            WHEN d.f_cashout_profit_increment_percent > .5 THEN '50%-70%'
            WHEN d.f_cashout_profit_increment_percent > .2 THEN '20%-50%'
            WHEN d.f_cashout_profit_increment_percent > 0 THEN '0%-20%'
            ELSE '0%'
        END) AS f_cashout_profit_increment_percent_cohort,
        m.f_group_activity_id
    FROM
        cashouts AS d
    LEFT JOIN
        v_cohort_registration AS r USING(f_player_id)
    LEFT JOIN
        v_cohort_matching AS m USING(f_player_id)
    
);