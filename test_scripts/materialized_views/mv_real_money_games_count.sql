CREATE MATERIALIZED VIEW mv_real_money_games_count AS (

    SELECT
        f_player_id,
        f_date,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'H') AS f_games_count_cash_texas,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'O') AS f_games_count_cash_omaha,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'P') AS f_games_count_cash_omaha_hi_lo,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'X') AS f_games_count_cash_omaha_five_card,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'Y') AS f_games_count_cash_courchevel,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'S') AS f_games_count_cash_stud,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'T') AS f_games_count_cash_stud_hi_lo,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'R') AS f_games_count_cash_razz,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'D') AS f_games_count_cash_draw,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'B') AS f_games_count_cash_badugi,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'E') AS f_games_count_cash_baduci,
        COUNT(f_game_type) FILTER (WHERE f_money_type = 'R' AND f_game_type = 'C') AS f_games_count_cash_badacey,
        
        COUNT(f_game_type) FILTER (WHERE f_tournament_type = 'G' AND f_game_type = 'H') AS f_games_count_sng_texas,
        COUNT(f_game_type) FILTER (WHERE f_tournament_type = 'G' AND f_game_type = 'O') AS f_games_count_sng_omaha,
        
        COUNT(f_game_type) FILTER (WHERE f_tournament_type = 'S' AND f_game_type = 'H') AS f_games_count_mtt_texas,
        COUNT(f_game_type) FILTER (WHERE f_tournament_type = 'S' AND f_game_type = 'O') AS f_games_count_mtt_omaha
    FROM
        mv_real_money_games
    GROUP BY
        f_player_id,
        f_date

);