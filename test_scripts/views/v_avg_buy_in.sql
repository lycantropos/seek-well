CREATE OR REPLACE VIEW v_avg_buy_in AS (

    WITH
    t_player_tournaments_buy_in AS (
    SELECT DISTINCT
            p.f_player_id,
            tour.f_ended_stamp AS f_stamp, 
            tour.f_tournament_type,
            (tour.f_buy_in::NUMERIC / 100) AS f_buy_in -- in dollars
        FROM 
            t_participation AS p,
            t_tournament AS tour,
            t_table AS tab
        WHERE
            p.f_table_id = tab.f_id AND
            tab.f_tournament_id = tour.f_id AND
            tour.f_money_type = 'R' AND
            tour.f_buy_in > 0
    )
    SELECT
        f_player_id,
        f_stamp::DATE AS f_date,
        f_buy_in,
        AVG(f_buy_in) FILTER (WHERE f_tournament_type = 'G') OVER w AS f_SNG_avg_buy_in,
        AVG(f_buy_in) FILTER (WHERE f_tournament_type = 'S') OVER w AS f_MTT_avg_buy_in
    FROM 
        t_player_tournaments_buy_in
    WINDOW w AS (
        PARTITION BY 
            f_player_id
        ORDER BY
            f_player_id,
            f_stamp::DATE
    )
    -- There is null values between dates, which will be filled in mv_player_state

);