CREATE OR REPLACE VIEW v_session_count AS (

    SELECT
        f_player_id,
        f_date,
        COUNT(f_session_id) AS f_session_count
    FROM 
        mv_player_sessions
    GROUP BY 
        f_player_id,
        f_date

);
