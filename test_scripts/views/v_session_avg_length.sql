CREATE OR REPLACE VIEW v_session_avg_length AS (

    SELECT DISTINCT ON (f_player_id, f_date)
        f_player_id,
        f_date,
        AVG(diff_in_minutes(f_session_ended_stamp, f_session_started_stamp)) OVER (
            PARTITION BY 
                f_player_id
            ORDER BY
                f_player_id,
                f_date
        ) AS f_session_avg_length_in_minutes
    FROM 
        mv_player_sessions
    
);
