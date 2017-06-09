CREATE OR REPLACE VIEW v_player_profit AS (

    WITH
    t_calculated_cash_transactions AS (
        SELECT
            f_player_id,
            f_stamp::DATE AS f_date,
            SUM(CASE WHEN f_type = 70 THEN f_value ELSE 0 END) AS f_from_table,
            SUM(CASE WHEN f_type = 84 THEN f_value ELSE 0 END) AS f_to_table -- <= 0
        FROM
            v_completed_transactions_on_real_money
        WHERE
            f_type IN (70, 84)
        GROUP BY 
            f_player_id,
            f_date
    ),
    t_cash_profit AS (
        SELECT
            f_player_id,
            f_date,
            (f_to_table + f_from_table)::NUMERIC / 100 AS f_profit -- in dollars
        FROM
            t_calculated_cash_transactions
    ),
    t_calculated_tournament_transactions AS (
        SELECT 
            tr.f_player_id,
            tr.f_stamp::DATE AS f_date,
            tour.f_tournament_type,
            SUM(CASE WHEN tr.f_type IN (49, 82) THEN tr.f_value ELSE 0 END) AS f_tournament_rebuy, -- <= 0
            SUM(CASE WHEN tr.f_type = 80 THEN tr.f_value ELSE 0 END) AS f_tournament_prize, -- > 0
            SUM(CASE WHEN tr.f_type = 66 THEN tr.f_value ELSE 0 END) AS f_tournament_register, -- <= 0
            SUM(CASE WHEN tr.f_type = 67 THEN tr.f_value ELSE 0 END) AS f_tournament_unregister, -- >= 0
            
            SUM(CASE WHEN tr.f_type = 510 THEN tr.f_value ELSE 0 END) AS f_tournament_re_entry, -- ? no records now
            SUM(CASE WHEN tr.f_type = 511 THEN tr.f_value ELSE 0 END) AS f_tournament_re_entry_cancelled
        FROM 
            v_completed_transactions_on_real_money AS tr,
            t_tournament AS tour
        WHERE
            tr.f_param_tournament_id = tour.f_id AND
            tr.f_type IN (49, 82, 80, 60, 66, 67, 510, 511)
        GROUP BY 
            tr.f_player_id,
            f_date,
            tour.f_tournament_type
    ),
    t_tournament_profit_with_type AS (
        SELECT
            f_player_id,
            f_date,
            f_tournament_type,
            (
                f_tournament_prize + f_tournament_rebuy +
                f_tournament_register + f_tournament_unregister -
                ABS(f_tournament_re_entry) + ABS(f_tournament_re_entry_cancelled) -- TODO: delete abs, when sign will be known
            )::NUMERIC / 100 AS f_profit -- in dollars
        FROM
            t_calculated_tournament_transactions
    ),
    t_selected_tournament_profit AS (
        SELECT 
            f_player_id,
            f_date,
            (CASE
                WHEN f_tournament_type = 'G' THEN f_profit
                ELSE 0
            END) AS f_SNG_profit,
            (CASE
                WHEN f_tournament_type = 'S' THEN f_profit
                ELSE 0
            END) AS f_MTT_profit,
            f_profit AS f_total_profit
        FROM 
            t_tournament_profit_with_type
    )
    SELECT 
        f_player_id,
        f_date,
        COALESCE(t.f_SNG_profit, 0) AS f_SNG_profit,
        COALESCE(t.f_MTT_profit, 0) AS f_MTT_profit,
        COALESCE(c.f_profit, 0) AS f_cash_profit,
        (COALESCE(c.f_profit, 0) + COALESCE(t.f_total_profit, 0)) AS f_total_profit
    FROM
        t_cash_profit AS c
    FULL JOIN 
        t_selected_tournament_profit AS t USING (f_player_id, f_date)

);