CREATE OR REPLACE VIEW v_cohort_registration AS (

    WITH
    register_interval AS (
        SELECT 
            f_id AS f_player_id,
            (f_register_stamp::DATE) AS f_register_date,
            (now() - f_register_stamp)::INTERVAL AS f_register_interval
        FROM
            t_player
    )
    SELECT
        f_player_id,
        f_register_date,
        (CASE 
            WHEN f_register_interval > '1 year' THEN '> 1 year'
            WHEN f_register_interval > '6 months' THEN '1 year'
            WHEN f_register_interval > '3 months' THEN '6 months'
            WHEN f_register_interval > '1 month' THEN '3 months'
            WHEN f_register_interval > '2 weeks' THEN '1 month'
            WHEN f_register_interval > '1 week' THEN '2 weeks'
            WHEN f_register_interval > '3 days' THEN '1 week'
            WHEN f_register_interval > '1 day' THEN '3 days'
            ELSE 'New'
        END) AS f_register_date_cohort
    FROM
        register_interval
        
);