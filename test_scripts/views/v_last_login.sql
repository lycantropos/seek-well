CREATE OR REPLACE VIEW v_last_login AS (

    SELECT
        f_player_id,
        MAX(f_end_stamp)::DATE AS f_date,
        MAX(f_end_stamp) AS f_last_login_stamp
    FROM
        t_sessions_log
    GROUP BY
        f_player_id

);