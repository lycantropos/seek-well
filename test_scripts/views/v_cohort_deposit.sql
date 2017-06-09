CREATE OR REPLACE VIEW v_cohort_deposit AS (

    WITH
    deposits AS (
        SELECT
            player_id AS f_player_id,
            (stamp::DATE) AS f_date,
            (transaction_value::NUMERIC / 100) AS f_deposit,
            (increment_value::NUMERIC / 100) AS f_deposit_profit_increment_value,
            (CASE
                WHEN transaction_value = 0 THEN 0
                ELSE (increment_value / transaction_value)
            END) AS f_deposit_profit_increment_percent
        FROM 
            profit_balances
        WHERE
            increment_type = 'DepositProfit'
    )
    SELECT 
        f_player_id,
        d.f_date,
        d.f_deposit,
        d.f_deposit_profit_increment_value,
        r.f_register_date,
        r.f_register_date_cohort,
        (CASE 
            WHEN d.f_deposit > 500 THEN '> 500$'
            WHEN d.f_deposit > 100 THEN '100$-500$'
            WHEN d.f_deposit > 50 THEN '50$-100$'
            WHEN d.f_deposit > 20 THEN '20$-50$'
            WHEN d.f_deposit > 10 THEN '10$-20$'
            ELSE '<= 10$'
        END) AS f_deposit_cohort,
        (CASE 
            WHEN d.f_deposit_profit_increment_percent > .7 THEN '> 70%'
            WHEN d.f_deposit_profit_increment_percent > .5 THEN '50%-70%'
            WHEN d.f_deposit_profit_increment_percent > .2 THEN '20%-50%'
            WHEN d.f_deposit_profit_increment_percent > 0 THEN '0%-20%'
            ELSE '0%'
        END) AS f_deposit_profit_increment_percent_cohort,
        m.f_group_activity_id
    FROM
        deposits AS d
    LEFT JOIN
        v_cohort_registration AS r USING(f_player_id)
    LEFT JOIN
        v_cohort_matching AS m USING(f_player_id)
    
);