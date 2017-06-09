CREATE OR REPLACE VIEW v_session_avg_game_count AS (
    

    SELECT DISTINCT ON (f_player_id, f_date)
        f_player_id,
        f_date,
        AVG(f_games_count) OVER (
            PARTITION BY 
                f_player_id
            ORDER BY
                f_player_id,
                f_date
        ) AS f_session_avg_game_count
    FROM 
        mv_player_sessions

);
