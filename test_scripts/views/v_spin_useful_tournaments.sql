CREATE OR REPLACE VIEW v_spin_useful_tournaments AS (

    WITH 
    tournaments_without_bots AS (
        SELECT 
            f_buy_in,
            'without bots'::TEXT AS f_metric_name,
            SUM(f_tournaments) AS f_tournaments
        FROM
            mv_spin_tournaments_by_pools
        WHERE
            f_bots_count = 0
        GROUP BY 
            f_buy_in
    ),
    tournaments_without_players AS (
        SELECT 
            f_buy_in,
            'without players'::TEXT AS f_metric_name,
            SUM(f_tournaments) AS f_tournaments
        FROM
            mv_spin_tournaments_by_pools
        WHERE
            f_players_count = 0
        GROUP BY 
            f_buy_in
    ),
    tournaments_with_players_and_bots AS (
        SELECT 
            f_buy_in,
            'with players and bots'::TEXT AS f_metric_name,
            SUM(f_tournaments) AS f_tournaments
        FROM
            mv_spin_tournaments_by_pools
        WHERE
            f_players_count > 0 AND
            f_bots_count > 0
        GROUP BY 
            f_buy_in
    )
    SELECT 
        f_buy_in,
        f_metric_name,
        f_tournaments
    FROM tournaments_with_players_and_bots
    FULL JOIN tournaments_without_bots USING (f_buy_in, f_metric_name, f_tournaments)
    FULL JOIN tournaments_without_players USING (f_buy_in, f_metric_name, f_tournaments)

);