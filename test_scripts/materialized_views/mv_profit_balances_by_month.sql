CREATE MATERIALIZED VIEW mv_profit_balances_by_month AS (

    WITH
    player_max_date_by_month AS (
        SELECT
            f_player_id,
            MAX(f_date) AS f_date
        FROM
            v_profit_balances
        GROUP BY
            f_player_id,
            DATE_TRUNC('month', f_date)::DATE
    ),
    last_values_by_month AS (
        SELECT
            f_player_id,
            DATE_TRUNC('month', f_date)::DATE AS f_date,
            f_total_profit,
            f_balance_profit,
            f_deposit_profit,
            f_cashout_profit
        FROM 
            v_profit_balances
        JOIN
            player_max_date_by_month USING(f_player_id, f_date)
    ),
    last_month AS (
        SELECT
            MAX(f_date) AS f_last_month
        FROM
            last_values_by_month
    ),
    player_all_months AS (
        SELECT
            f_player_id,
            generate_series(min(f_date), f_last_month, '1 month')::DATE AS f_date
        FROM
            last_values_by_month,
            last_month
        GROUP BY
            f_player_id,
            f_last_month
    ),
    with_metric_ids AS (
        SELECT 
            f_player_id,
            f_date,

            f_total_profit,
            f_balance_profit,
            f_deposit_profit,
            f_cashout_profit,
            
            COUNT(f_balance_profit) OVER w AS f_balance_profit_id -- Use only one column id because all profits exist at the same time
        FROM 
            player_all_months
        LEFT JOIN 
            last_values_by_month USING(f_player_id, f_date)
        WINDOW w AS (
            PARTITION BY 
                f_player_id 
            ORDER BY
                f_date
        )
    )
    SELECT
        f_player_id,
        f_date,

        COALESCE(
            f_balance_profit,
            first_value(f_balance_profit) OVER w
        ) AS f_balance_profit,

        COALESCE(
            f_total_profit,
            first_value(f_balance_profit) OVER w
        ) AS f_total_profit,

        COALESCE(
            f_deposit_profit,
            first_value(f_deposit_profit) OVER w
        ) AS f_deposit_profit,

        COALESCE(
            f_cashout_profit,
            first_value(f_cashout_profit) OVER w
        ) AS f_cashout_profit
    FROM
        with_metric_ids
    WINDOW w AS (
        PARTITION BY 
            f_player_id,
            f_balance_profit_id
        ORDER BY
            f_date
    )

);