CREATE MATERIALIZED VIEW mv_pool_profit_balances AS (
    WITH
    t_all AS (
        SELECT
            f_date,
            SUM(f_balance_profit) AS f_balance_profit_all
        FROM 
            mv_profit_balances_by_month
        GROUP BY
            f_date
    ),
    bots AS (
        SELECT
            f_date,
            SUM(f_balance_profit) AS f_balance_profit_bots
        FROM
            mv_profit_balances_by_month
        JOIN
            t_house_flag USING(f_player_id)
        WHERE 
            t_house_flag.f_house_flag = 1
        GROUP BY
            f_date
    ),
    live_players AS (
        SELECT
            f_date,
            SUM(f_balance_profit) AS f_balance_profit_live_players
        FROM 
            mv_profit_balances_by_month
        JOIN 
            t_house_flag USING(f_player_id)
        WHERE 
            t_house_flag.f_house_flag = 0
        GROUP BY
            f_date
    ),
    house_players AS (
        SELECT
            f_date,
            SUM(f_balance_profit) AS f_balance_profit_house_players
        FROM 
            mv_profit_balances_by_month
        JOIN 
            t_house_flag USING(f_player_id)
        WHERE 
            t_house_flag.f_house_flag = 2
        GROUP BY
            f_date
    ),
    test_players AS (
        SELECT
            f_date,
            SUM(f_balance_profit) AS f_balance_profit_test_players
        FROM 
            mv_profit_balances_by_month
        JOIN 
            t_house_flag USING(f_player_id)
        WHERE 
            t_house_flag.f_house_flag = 3
        GROUP BY
            f_date
    ),
    last_4_month AS (
        SELECT
            GENERATE_SERIES(
                GREATEST(
                    MIN(f_date),
                    DATE_TRUNC('month', MAX(f_date) - INTERVAL '3 months') -- On one month less, because we include current month 
                ),
                MAX(f_date),
                '1 month'
            )::DATE AS f_date
        FROM
            t_all
    ),
    last_4_month_year_ago AS (
        SELECT
            GENERATE_SERIES(
                GREATEST(
                    MIN(f_date),
                    DATE_TRUNC('month', MAX(f_date) - INTERVAL '1 year 3 months') -- On one month less, because we include current month
                ),
                MAX(f_date) - INTERVAL '1 year',
                '1 month'
            )::DATE AS f_date
        FROM
            t_all
    ),
    date_filter AS (
        SELECT f_date
        FROM last_4_month
        FULL JOIN last_4_month_year_ago USING (f_date)
    )
    SELECT 
        f_date,
        EXTRACT('year' FROM f_date) AS f_year,
        EXTRACT('month' FROM f_date) AS f_month,

        f_balance_profit_all,
        f_balance_profit_bots,
        f_balance_profit_live_players,
        f_balance_profit_house_players,
        f_balance_profit_test_players
    FROM t_all
    JOIN date_filter USING (f_date)
    LEFT JOIN bots USING (f_date)
    LEFT JOIN house_players USING (f_date)
    LEFT JOIN test_players USING (f_date)
    LEFT JOIN live_players USING (f_date)

);