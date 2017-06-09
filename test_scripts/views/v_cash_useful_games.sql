CREATE OR REPLACE VIEW v_cash_useful_games AS (

    WITH 
    games_without_bots AS (
        SELECT 
            f_limit,
            'without bots'::TEXT AS f_metric_name,
            SUM(f_games) AS f_games,
            SUM(f_rake) AS f_rake
        FROM
            mv_cash_games_by_pools
        WHERE
            f_bots_count = 0
        GROUP BY 
            f_limit
    ),
    games_without_players AS (
        SELECT 
            f_limit,
            'without players'::TEXT AS f_metric_name,
            SUM(f_games) AS f_games,
            SUM(f_rake) AS f_rake
        FROM
            mv_cash_games_by_pools
        WHERE
            f_players_count = 0
        GROUP BY 
            f_limit
    ),
    games_with_players_and_bots AS (
        SELECT 
            f_limit,
            'with players and bots'::TEXT AS f_metric_name,
            SUM(f_games) AS f_games,
            SUM(f_rake) AS f_rake
        FROM
            mv_cash_games_by_pools
        WHERE
            f_players_count > 0 AND
            f_bots_count > 0
        GROUP BY 
            f_limit
    )
    SELECT 
        f_limit,
        f_metric_name,
        f_games,
        f_rake
    FROM games_with_players_and_bots
    FULL JOIN games_without_bots USING (f_limit, f_metric_name, f_games, f_rake)
    FULL JOIN games_without_players USING (f_limit, f_metric_name, f_games, f_rake)

);