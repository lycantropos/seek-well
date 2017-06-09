CREATE MATERIALIZED VIEW mv_pool_sng_tournaments AS (
    WITH
    player_in_sng_tournaments AS (
        SELECT
            f_started_stamp,
            tour.f_id,
            f_player_id
        FROM
            t_tournament AS tour,
            t_player_in_tournament AS tp 
        WHERE
            tour.f_id = tp.f_tournament_id AND
            tour.f_money_type = 'R' AND
            tour.f_tournament_type = 'G' AND
            tour.f_buy_in > 0
    ),
    t_all AS (
         SELECT
            DATE_TRUNC('month', f_started_stamp)::DATE AS f_date,
            COUNT(DISTINCT f_id) AS f_sng_touraments_all
        FROM
            player_in_sng_tournaments AS tour
        GROUP BY 
            DATE_TRUNC('month', f_started_stamp)
    ),
    bots AS (
        SELECT
            DATE_TRUNC('month', f_started_stamp)::DATE AS f_date,
            COUNT(DISTINCT tour.f_id) AS f_sng_touraments_bots
        FROM
            player_in_sng_tournaments AS tour,
            t_house_flag AS hf
        WHERE
            hf.f_house_flag = 1 AND
            tour.f_player_id = hf.f_player_id
        GROUP BY 
            DATE_TRUNC('month', f_started_stamp)
    ),
    live_players AS (
        SELECT
            DATE_TRUNC('month', f_started_stamp)::DATE AS f_date,
            COUNT(DISTINCT tour.f_id) AS f_sng_touraments_live_players
        FROM
            player_in_sng_tournaments AS tour,
            t_house_flag AS hf
        WHERE
            hf.f_house_flag = 0 AND
            tour.f_player_id = hf.f_player_id
        GROUP BY 
            DATE_TRUNC('month', f_started_stamp)
    ),
    house_players AS (
        SELECT
            DATE_TRUNC('month', f_started_stamp)::DATE AS f_date,
            COUNT(DISTINCT tour.f_id) AS f_sng_touraments_house_players
        FROM
            player_in_sng_tournaments AS tour,
            t_house_flag AS hf
        WHERE
            hf.f_house_flag = 2 AND
            tour.f_player_id = hf.f_player_id
        GROUP BY 
            DATE_TRUNC('month', f_started_stamp)
    ),
    test_players AS (
        SELECT
            DATE_TRUNC('month', f_started_stamp)::DATE AS f_date,
            COUNT(DISTINCT tour.f_id) AS f_sng_touraments_test_players
        FROM
            player_in_sng_tournaments AS tour,
            t_house_flag AS hf
        WHERE
            hf.f_house_flag = 3 AND
            tour.f_player_id = hf.f_player_id
        GROUP BY 
            DATE_TRUNC('month', f_started_stamp)
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

        COALESCE(f_sng_touraments_all, 0) AS f_sng_touraments_all,
        COALESCE(f_sng_touraments_bots, 0) AS f_sng_touraments_bots,
        COALESCE(f_sng_touraments_live_players, 0) AS f_sng_touraments_live_players,
        COALESCE(f_sng_touraments_house_players, 0) AS f_sng_touraments_house_players,
        COALESCE(f_sng_touraments_test_players, 0) AS f_sng_touraments_test_players
    FROM t_all
    JOIN date_filter USING (f_date)
    LEFT JOIN bots USING (f_date)
    LEFT JOIN house_players USING (f_date)
    LEFT JOIN test_players USING (f_date)
    LEFT JOIN live_players USING (f_date)

);