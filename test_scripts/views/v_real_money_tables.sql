CREATE OR REPLACE VIEW v_real_money_tables AS (
    SELECT 
        tab.*
    FROM 
        t_table AS tab
    LEFT OUTER JOIN 
        t_tournament tour ON tour.f_id = tab.f_tournament_id
    WHERE 
        tab.f_money_type = 'R' OR 
        (tab.f_money_type = 'T' AND tour.f_money_type = 'R' AND tour.f_buy_in > 0)
);