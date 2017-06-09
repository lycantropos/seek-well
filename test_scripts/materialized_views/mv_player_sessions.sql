CREATE MATERIALIZED VIEW mv_player_sessions AS (

    WITH 
    t_player_games_on_real_money AS (
        SELECT 
            p.f_player_id,
            g.f_started_stamp,
            g.f_ended_stamp,
            t.f_money_type AS f_table_type
        FROM 
            t_participation AS p,
            t_game AS g,
            v_real_money_tables AS t
        WHERE 
            g.f_id = p.f_game_id AND
            t.f_id = p.f_table_id
    ),
    t_player_games_on_real_money_with_ids AS (
        SELECT
            *,
            LAG(f_ended_stamp) OVER w AS prev_ended_stamp,
            (CASE 
                WHEN diff_in_minutes(f_started_stamp, LAG(f_ended_stamp) OVER w) <= 30
                THEN NULL
                ELSE 1
            END) AS session_increment
        FROM 
            t_player_games_on_real_money
        WINDOW w AS (
            PARTITION BY 
                f_player_id,
                f_table_type
            ORDER BY
                f_started_stamp
        )
    ),
    t_player_games_with_sessions_ids AS (
        SELECT 
            *,
            SUM(session_increment) OVER (ORDER BY f_player_id, f_started_stamp, f_ended_stamp, f_table_type) AS f_session_id
        FROM 
            t_player_games_on_real_money_with_ids
    ),
    t_sessions_info AS (
        SELECT 
            COUNT (f_started_stamp) AS f_games_count,
            min(f_started_stamp) AS f_session_started_stamp,
            max(f_ended_stamp) AS f_session_ended_stamp,
            f_session_id
        FROM 
            t_player_games_with_sessions_ids
        GROUP BY
            f_session_id
    )
    SELECT 
        gs.f_player_id,
        s.f_session_ended_stamp::DATE AS f_date,
        s.f_session_started_stamp,
        s.f_session_ended_stamp,
        s.f_games_count,
        s.f_session_id
    FROM
        t_sessions_info AS s,
        t_player_games_with_sessions_ids AS gs
    WHERE 
        gs.f_session_id = s.f_session_id AND
        gs.f_started_stamp = s.f_session_started_stamp 

);
