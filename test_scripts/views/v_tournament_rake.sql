CREATE OR REPLACE VIEW v_tournament_rake AS (

    WITH
    t_tournament_rake_by_date AS (
        SELECT 
            tr.f_param_player_id AS f_player_id,
            tr.f_stamp::DATE AS f_date,
            tour.f_tournament_type,
            (SUM(tr.f_value)::NUMERIC / 100) AS f_value -- in dollars
        FROM 
            v_completed_transactions_on_real_money AS tr,
            t_tournament AS tour
        WHERE 
            tour.f_id = tr.f_param_tournament_id AND
            tr.f_type IN (69, 71, 510, 511)
        GROUP BY 
            tr.f_param_player_id,
            f_date,
            tour.f_tournament_type
    )
    SELECT
        f_player_id,
        f_date,
        SUM(CASE WHEN f_tournament_type = 'G' THEN f_value ELSE 0 END) AS f_SNG_rake,
        SUM(CASE WHEN f_tournament_type = 'S' THEN f_value ELSE 0 END) AS f_MTT_rake
    FROM 
        t_tournament_rake_by_date
    GROUP BY 
        f_player_id,
        f_date

);