CREATE OR REPLACE VIEW v_net_rake AS (

    SELECT 
        f_player_id,
        f_date,
        COALESCE(l.f_loyalty, 0) AS f_loyalty,
        COALESCE(cr.f_cash_rake, 0) AS f_cash_rake,
        COALESCE(tr.f_SNG_rake, 0) AS f_SNG_rake,
        COALESCE(tr.f_MTT_rake, 0) AS f_MTT_rake,
        (
            COALESCE(cr.f_cash_rake, 0) + 
            COALESCE(tr.f_SNG_rake, 0) + 
            COALESCE(tr.f_MTT_rake, 0)
        ) AS f_total_rake,
        (
            COALESCE(l.f_loyalty, 0) + 
            COALESCE(cr.f_cash_rake, 0) + 
            COALESCE(tr.f_SNG_rake, 0) + 
            COALESCE(tr.f_MTT_rake, 0)
        ) AS f_net_rake
    FROM 
        v_loyalty AS l
    FULL JOIN v_cash_rake AS cr USING (f_player_id, f_date)
    FULL JOIN v_tournament_rake AS tr USING (f_player_id, f_date)

);