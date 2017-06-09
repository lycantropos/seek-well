CREATE OR REPLACE VIEW v_profit_balances AS (

    SELECT DISTINCT ON (player_id, stamp::DATE)
        player_id AS f_player_id,
        stamp::DATE as f_date,
        total_profit::NUMERIC / 100 AS f_total_profit,
        balance_profit::NUMERIC / 100 AS f_balance_profit,
        deposit_profit::NUMERIC / 100 AS f_deposit_profit,
        cashout_profit::NUMERIC / 100 AS f_cashout_profit
    FROM 
        profit_balances
    ORDER BY
        f_player_id,
        f_date DESC,
        stamp DESC

);