CREATE MATERIALIZED VIEW mv_real_money_games AS (

    SELECT 
        p.f_player_id,
        g.f_ended_stamp::DATE AS f_date,
        t.f_money_type,
        t.f_game_type,
        tour.f_tournament_type
    FROM 
        t_game AS g,
        t_participation AS p,
        v_real_money_tables AS t
    LEFT JOIN 
        t_tournament AS tour ON t.f_tournament_id = tour.f_id
    WHERE
        g.f_id = p.f_game_id AND
        p.f_table_id = t.f_id
        
);