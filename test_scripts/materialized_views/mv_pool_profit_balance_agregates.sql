CREATE MATERIALIZED VIEW mv_pool_profit_balance_agregates AS (
    SELECT
        f_date,
        f_date::VARCHAR(12) AS f_string_date,

        SUM(f_balance_profit) AS f_balance_profit,
        SUM(f_deposit_profit) AS f_deposit_profit,
        ABS(SUM(f_cashout_profit)) AS f_cashout_profit,
        ABS(SUM(f_deposit_profit + f_cashout_profit)) AS f_net_cashout_profit
    FROM 
        mv_profit_balances_by_month
    GROUP BY
        f_date
    ORDER BY
        f_date
);