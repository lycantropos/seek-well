CREATE OR REPLACE VIEW v_freerolls_games_count AS (
    
    SELECT 
        p.f_player_id,
        g.f_ended_stamp::DATE AS f_date,
        COUNT(*) AS f_freerolls_games_count
    FROM 
        t_game AS g,
        t_participation AS p,
        t_table AS t, 
        t_tournament AS tour
    WHERE
        g.f_id = p.f_game_id AND
        p.f_table_id = t.f_id AND
        t.f_tournament_id = tour.f_id AND
        tour.f_money_type = 'R' AND
        tour.f_buy_in = 0
    GROUP BY 
        f_player_id,
        f_date

);