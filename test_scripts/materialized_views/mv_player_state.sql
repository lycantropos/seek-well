CREATE MATERIALIZED VIEW mv_player_state AS (
    
    WITH
    t_state AS (
        SELECT 
            f_player_id,
            f_date,
            
            v_avg_stake.f_avg_stake,
            v_avg_buy_in.f_sng_avg_buy_in,
            v_avg_buy_in.f_mtt_avg_buy_in,

            COALESCE(v_profit_balances.f_balance_profit, 0) AS f_balance_profit,
            COALESCE(v_profit_balances.f_cashout_profit, 0) AS f_cashout_profit,

            COALESCE(v_freerolls_games_count.f_freerolls_games_count, 0) AS f_freerolls_games_count,

            COALESCE(mv_real_money_games_count.f_games_count_cash_texas, 0) AS f_games_count_cash_texas,
            COALESCE(mv_real_money_games_count.f_games_count_cash_omaha, 0) AS f_games_count_cash_omaha,
            COALESCE(mv_real_money_games_count.f_games_count_cash_omaha_hi_lo, 0) AS f_games_count_cash_omaha_hi_lo,
            COALESCE(mv_real_money_games_count.f_games_count_cash_omaha_five_card, 0) AS f_games_count_cash_omaha_five_card,
            COALESCE(mv_real_money_games_count.f_games_count_cash_courchevel, 0) AS f_games_count_cash_courchevel,
            COALESCE(mv_real_money_games_count.f_games_count_cash_stud, 0) AS f_games_count_cash_stud,
            COALESCE(mv_real_money_games_count.f_games_count_cash_stud_hi_lo, 0) AS f_games_count_cash_stud_hi_lo,
            COALESCE(mv_real_money_games_count.f_games_count_cash_razz, 0) AS f_games_count_cash_razz,
            COALESCE(mv_real_money_games_count.f_games_count_cash_draw, 0) AS f_games_count_cash_draw,
            COALESCE(mv_real_money_games_count.f_games_count_cash_badugi, 0) AS f_games_count_cash_badugi,
            COALESCE(mv_real_money_games_count.f_games_count_cash_baduci, 0) AS f_games_count_cash_baduci,
            COALESCE(mv_real_money_games_count.f_games_count_cash_badacey, 0) AS f_games_count_cash_badacey,
            
            COALESCE(mv_real_money_games_count.f_games_count_sng_texas, 0) AS f_games_count_sng_texas,
            COALESCE(mv_real_money_games_count.f_games_count_sng_omaha, 0) AS f_games_count_sng_omaha,
            
            COALESCE(mv_real_money_games_count.f_games_count_mtt_texas, 0) AS f_games_count_mtt_texas,
            COALESCE(mv_real_money_games_count.f_games_count_mtt_omaha, 0) AS f_games_count_mtt_omaha,

            v_registration.f_register_stamp,
            v_last_login.f_last_login_stamp,

            COALESCE(v_player_profit.f_cash_profit, 0) AS f_cash_profit,
            COALESCE(v_player_profit.f_sng_profit, 0) AS f_sng_profit,
            COALESCE(v_player_profit.f_mtt_profit, 0) AS f_mtt_profit,
            COALESCE(v_player_profit.f_total_profit, 0) AS f_total_profit,

            COALESCE(v_balance.f_balance, 0) AS f_balance,
            COALESCE(mv_deposit.f_deposit, 0) AS f_deposit,
            COALESCE(v_last_deposit.f_last_deposit, 0) AS f_last_deposit,
            COALESCE(mv_deposit.f_deposit_count, 0) AS f_deposit_count,
            COALESCE(v_cashouts.f_cashouts, 0) AS f_cashouts,

            COALESCE(v_net_rake.f_loyalty, 0) AS f_loyalty,
            COALESCE(v_net_rake.f_cash_rake, 0) AS f_cash_rake,
            COALESCE(v_net_rake.f_sng_rake, 0) AS f_sng_rake,
            COALESCE(v_net_rake.f_mtt_rake, 0) AS f_mtt_rake,
            COALESCE(v_net_rake.f_total_rake, 0) AS f_total_rake,
            COALESCE(v_net_rake.f_net_rake, 0) AS f_net_rake,
            
            COALESCE(v_session_count.f_session_count, 0) AS f_session_count,
            v_session_avg_length.f_session_avg_length_in_minutes,
            v_session_avg_game_count.f_session_avg_game_count,
            
            mv_minutes_between_first_login_and_real_money_hand.f_minutes AS f_minutes_between_first_login_and_real_money_hand
            
        FROM mv_deposit

        FULL JOIN v_last_deposit USING (f_player_id, f_date)
        FULL JOIN v_profit_balances USING (f_player_id, f_date)
        FULL JOIN v_balance USING (f_player_id, f_date)
        FULL JOIN v_cashouts USING (f_player_id, f_date)
        FULL JOIN v_avg_stake USING (f_player_id, f_date)
        FULL JOIN v_avg_buy_in USING (f_player_id, f_date)
        FULL JOIN v_registration USING (f_player_id, f_date)
        FULL JOIN v_last_login USING (f_player_id, f_date)
        FULL JOIN v_freerolls_games_count USING (f_player_id, f_date)
        FULL JOIN mv_real_money_games_count USING (f_player_id, f_date)
        FULL JOIN v_player_profit USING (f_player_id, f_date)
        FULL JOIN v_net_rake USING (f_player_id, f_date)
        FULL JOIN v_session_count USING (f_player_id, f_date)
        FULL JOIN v_session_avg_length USING (f_player_id, f_date)
        FULL JOIN v_session_avg_game_count USING (f_player_id, f_date)
        FULL JOIN mv_minutes_between_first_login_and_real_money_hand USING (f_player_id, f_date)
        
        ORDER BY
            f_player_id,
            f_date
    ),
    room_player AS (
        SELECT 
            *
        FROM
            t_house_flag
        WHERE
            f_house_flag = 4
    ),
    t_filtered_player_state AS (
        SELECT s.*
        FROM t_state AS s
        LEFT JOIN room_player AS p
        ON s.f_player_id = p.f_player_id
        WHERE p.f_player_id IS NULL
    ),
    t_cumulative_player_state AS (
        SELECT DISTINCT
            f_player_id,
            f_date,

            f_register_stamp,
            f_last_login_stamp,

            f_avg_stake,
            f_sng_avg_buy_in,
            f_mtt_avg_buy_in,

            f_balance_profit,
            f_cashout_profit,

            SUM(f_freerolls_games_count) OVER w AS f_freerolls_games_count,

            SUM(f_games_count_cash_texas) OVER w AS f_games_count_cash_texas,
            SUM(f_games_count_cash_omaha) OVER w AS f_games_count_cash_omaha,
            SUM(f_games_count_cash_omaha_hi_lo) OVER w AS f_games_count_cash_omaha_hi_lo,
            SUM(f_games_count_cash_omaha_five_card) OVER w AS f_games_count_cash_omaha_five_card,
            SUM(f_games_count_cash_courchevel) OVER w AS f_games_count_cash_courchevel,
            SUM(f_games_count_cash_stud) OVER w AS f_games_count_cash_stud,
            SUM(f_games_count_cash_stud_hi_lo) OVER w AS f_games_count_cash_stud_hi_lo,
            SUM(f_games_count_cash_razz) OVER w AS f_games_count_cash_razz,
            SUM(f_games_count_cash_draw) OVER w AS f_games_count_cash_draw,
            SUM(f_games_count_cash_badugi) OVER w AS f_games_count_cash_badugi,
            SUM(f_games_count_cash_baduci) OVER w AS f_games_count_cash_baduci,
            SUM(f_games_count_cash_badacey) OVER w AS f_games_count_cash_badacey,

            SUM(f_games_count_sng_texas) OVER w AS f_games_count_sng_texas,
            SUM(f_games_count_sng_omaha) OVER w AS f_games_count_sng_omaha,

            SUM(f_games_count_mtt_texas) OVER w AS f_games_count_mtt_texas,
            SUM(f_games_count_mtt_omaha) OVER w AS f_games_count_mtt_omaha,


            SUM(f_cash_profit) OVER w AS f_cumulative_cash_profit,
            SUM(f_sng_profit) OVER w AS f_cumulative_sng_profit,

            SUM(f_mtt_profit) OVER w AS f_cumulative_mtt_profit,
            SUM(f_total_profit) OVER w AS f_cumulative_total_profit,

            SUM(f_balance) OVER w AS f_cumulative_balance,
            
            f_last_deposit,
            SUM(f_deposit) OVER w AS f_cumulative_deposit,
            SUM(f_deposit_count) OVER w AS f_cumulative_deposit_count,

            SUM(f_cashouts) OVER w AS f_cumulative_cashouts,

            SUM(f_loyalty) OVER w AS f_cumulative_loyalty,

            SUM(f_cash_rake) OVER w AS f_cumulative_cash_rake,
            SUM(f_sng_rake) OVER w AS f_cumulative_sng_rake,
            SUM(f_mtt_rake) OVER w AS f_cumulative_mtt_rake,
            SUM(f_total_rake) OVER w AS f_cumulative_total_rake,
            SUM(f_net_rake) OVER w AS f_cumulative_net_rake,

            SUM(f_session_count) OVER w AS f_cumulative_session_count,

            f_session_avg_length_in_minutes,
            f_session_avg_game_count,
            f_minutes_between_first_login_and_real_money_hand
        FROM 
            t_filtered_player_state
        WINDOW w AS (
            PARTITION BY 
                f_player_id
            ORDER BY 
                f_player_id,
                f_date
        )
        ORDER BY
            f_player_id,
            f_date
    ),
    t_max_date AS (
        SELECT 
            MAX(f_date) AS f_max_date
        FROM 
            t_cumulative_player_state
    ),
    t_player_all_days AS (
        SELECT
            f_player_id, 
            generate_series(min(f_date), max(f_max_date), '1 day')::DATE AS f_date
        FROM 
            t_cumulative_player_state,
            t_max_date
        GROUP BY
            f_player_id
    ),
    t_with_metric_ids AS (
        SELECT
            ad.f_player_id,
            ad.f_date,
            

            cps.f_register_stamp,
            COUNT(cps.f_register_stamp) OVER w AS f_register_stamp_id,

            cps.f_last_login_stamp,
            COUNT(cps.f_last_login_stamp) OVER w AS f_last_login_stamp_id,

            cps.f_avg_stake,
            COUNT(cps.f_avg_stake) OVER w AS f_avg_stake_id,


            cps.f_sng_avg_buy_in,
            COUNT(cps.f_sng_avg_buy_in) OVER w AS f_sng_avg_buy_in_id,

            cps.f_mtt_avg_buy_in,
            COUNT(cps.f_mtt_avg_buy_in) OVER w AS f_mtt_avg_buy_in_id,


            cps.f_balance_profit,
            COUNT(cps.f_balance_profit) OVER w AS f_balance_profit_id,

            cps.f_cashout_profit,
            COUNT(cps.f_cashout_profit) OVER w AS f_cashout_profit,


            cps.f_freerolls_games_count,
            COUNT(cps.f_freerolls_games_count) OVER w AS f_freerolls_games_count_id,

            cps.f_games_count_cash_texas,
            COUNT(cps.f_games_count_cash_texas) OVER w AS f_games_count_cash_texas_id,
            
            cps.f_games_count_cash_omaha,
            COUNT(cps.f_games_count_cash_omaha) OVER w AS f_games_count_cash_omaha_id,

            cps.f_games_count_cash_omaha_hi_lo,
            COUNT(cps.f_games_count_cash_omaha_hi_lo) OVER w AS f_games_count_cash_omaha_hi_lo_id,
            
            cps.f_games_count_cash_omaha_five_card,
            COUNT(cps.f_games_count_cash_omaha_five_card) OVER w AS f_games_count_cash_omaha_five_card_id,
            
            cps.f_games_count_cash_courchevel,
            COUNT(cps.f_games_count_cash_courchevel) OVER w AS f_games_count_cash_courchevel_id,
            
            cps.f_games_count_cash_stud,
            COUNT(cps.f_games_count_cash_stud) OVER w AS f_games_count_cash_stud_id,
            
            cps.f_games_count_cash_stud_hi_lo,
            COUNT(cps.f_games_count_cash_stud_hi_lo) OVER w AS f_games_count_cash_stud_hi_lo_id,
            
            cps.f_games_count_cash_razz,
            COUNT(cps.f_games_count_cash_razz) OVER w AS f_games_count_cash_razz_id,
        
            cps.f_games_count_cash_draw,
            COUNT(cps.f_games_count_cash_draw) OVER w AS f_games_count_cash_draw_id,

            cps.f_games_count_cash_badugi,
            COUNT(cps.f_games_count_cash_badugi) OVER w AS f_games_count_cash_badugi_id,

            cps.f_games_count_cash_baduci,
            COUNT(cps.f_games_count_cash_baduci) OVER w AS f_games_count_cash_baduci_id,

            cps.f_games_count_cash_badacey,
            COUNT(cps.f_games_count_cash_badacey) OVER w AS f_games_count_cash_badacey_id,
            

            cps.f_games_count_sng_texas,
            COUNT(cps.f_games_count_sng_texas) OVER w AS f_games_count_sng_texas_id,
            
            cps.f_games_count_sng_omaha,
            COUNT(cps.f_games_count_sng_omaha) OVER w AS f_games_count_sng_omaha_id,
            

            cps.f_games_count_mtt_texas,
            COUNT(cps.f_games_count_mtt_texas) OVER w AS f_games_count_mtt_texas_id,
            
            cps.f_games_count_mtt_omaha,
            COUNT(cps.f_games_count_mtt_omaha) OVER w AS f_games_count_mtt_omaha_id,
            

            cps.f_cumulative_cash_profit,
            COUNT(cps.f_cumulative_cash_profit) OVER w AS f_cumulative_cash_profit_id,
            
            cps.f_cumulative_sng_profit,
            COUNT(cps.f_cumulative_sng_profit) OVER w AS f_cumulative_sng_profit_id,
            
            cps.f_cumulative_mtt_profit,
            COUNT(cps.f_cumulative_mtt_profit) OVER w AS f_cumulative_mtt_profit_id,
            
            cps.f_cumulative_total_profit,
            COUNT(cps.f_cumulative_total_profit) OVER w AS f_cumulative_total_profit_id,
            

            cps.f_cumulative_balance,
            COUNT(cps.f_cumulative_balance) OVER w AS f_cumulative_balance_id,


            cps.f_last_deposit,
            COUNT(cps.f_last_deposit) OVER w AS f_last_deposit_id,

            cps.f_cumulative_deposit,
            COUNT(cps.f_cumulative_deposit) OVER w AS f_cumulative_deposit_id,

            cps.f_cumulative_deposit_count,
            COUNT(cps.f_cumulative_deposit_count) OVER w AS f_cumulative_deposit_count_id,


            cps.f_cumulative_cashouts,
            COUNT(cps.f_cumulative_cashouts) OVER w AS f_cumulative_cashouts_id,


            cps.f_cumulative_loyalty,
            COUNT(cps.f_cumulative_loyalty) OVER w AS f_cumulative_loyalty_id,

            cps.f_cumulative_cash_rake,
            COUNT(cps.f_cumulative_cash_rake) OVER w AS f_cumulative_cash_rake_id,

            cps.f_cumulative_sng_rake,
            COUNT(cps.f_cumulative_sng_rake) OVER w AS f_cumulative_sng_rake_id,

            cps.f_cumulative_mtt_rake,
            COUNT(cps.f_cumulative_mtt_rake) OVER w AS f_cumulative_mtt_rake_id,

            cps.f_cumulative_total_rake,
            COUNT(cps.f_cumulative_total_rake) OVER w AS f_cumulative_total_rake_id,

            cps.f_cumulative_net_rake,
            COUNT(cps.f_cumulative_net_rake) OVER w AS f_cumulative_net_rake_id,


            cps.f_cumulative_session_count,
            COUNT(cps.f_cumulative_session_count) OVER w AS f_cumulative_session_count_id,
            
            cps.f_session_avg_length_in_minutes,
            COUNT(cps.f_session_avg_length_in_minutes) OVER w AS f_session_avg_length_in_minutes_id,
            
            cps.f_session_avg_game_count,
            COUNT(cps.f_session_avg_game_count) OVER w AS f_session_avg_game_count_id,


            cps.f_minutes_between_first_login_and_real_money_hand,
            COUNT(cps.f_minutes_between_first_login_and_real_money_hand) OVER w AS f_minutes_between_first_login_and_real_money_hand_id
        FROM 
            t_player_all_days AS ad
        LEFT JOIN 
            t_cumulative_player_state AS cps
            ON 
                ad.f_player_id = cps.f_player_id AND
                ad.f_date = cps.f_date
        WINDOW w AS (
            PARTITION BY 
                ad.f_player_id 
            ORDER BY
                ad.f_date
        )
    ),
    t_cumulative_fin_state_by_day_with_null AS (
        SELECT
            f_player_id,
            f_date,
            

            COALESCE(f_register_stamp, first_value(f_register_stamp) 
                OVER (PARTITION BY f_player_id, f_register_stamp_id ORDER BY f_date)
            ) AS f_register_stamp,

            COALESCE(f_last_login_stamp, first_value(f_last_login_stamp) 
                OVER (PARTITION BY f_player_id, f_last_login_stamp_id ORDER BY f_date)
            ) AS f_last_login_stamp,
            

            COALESCE(f_avg_stake, first_value(f_avg_stake) 
                OVER (PARTITION BY f_player_id, f_avg_stake_id ORDER BY f_date)
            ) AS f_avg_stake,
            
            
            COALESCE(f_sng_avg_buy_in, first_value(f_sng_avg_buy_in) 
                OVER (PARTITION BY f_player_id, f_sng_avg_buy_in_id ORDER BY f_date)
            ) AS f_sng_avg_buy_in,
            
            COALESCE(f_mtt_avg_buy_in, first_value(f_mtt_avg_buy_in) 
                OVER (PARTITION BY f_player_id, f_mtt_avg_buy_in_id ORDER BY f_date)
            ) AS f_mtt_avg_buy_in,
            

            COALESCE(f_balance_profit, first_value(f_balance_profit) 
                OVER (PARTITION BY f_player_id, f_balance_profit_id ORDER BY f_date)
            ) AS f_balance_profit,
            
            COALESCE(f_cashout_profit, first_value(f_cashout_profit) 
                OVER (PARTITION BY f_player_id, f_mtt_avg_buy_in_id ORDER BY f_date)
            ) AS f_cashout_profit,
            

            COALESCE(f_freerolls_games_count, first_value(f_freerolls_games_count) 
                OVER (PARTITION BY f_player_id, f_freerolls_games_count_id ORDER BY f_date)
            ) AS f_freerolls_games_count,
            
            
            COALESCE(f_games_count_cash_texas, first_value(f_games_count_cash_texas) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_texas_id ORDER BY f_date)
            ) AS f_games_count_cash_texas,
        
            COALESCE(f_games_count_cash_omaha, first_value(f_games_count_cash_omaha) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_omaha_id ORDER BY f_date)
            ) AS f_games_count_cash_omaha,
            
            COALESCE(f_games_count_cash_omaha_hi_lo, first_value(f_games_count_cash_omaha_hi_lo) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_omaha_hi_lo_id ORDER BY f_date)
            ) AS f_games_count_cash_omaha_hi_lo,
            
            COALESCE(f_games_count_cash_omaha_five_card, first_value(f_games_count_cash_omaha_five_card) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_omaha_five_card_id ORDER BY f_date)
            ) AS f_games_count_cash_omaha_five_card,
            
            COALESCE(f_games_count_cash_courchevel, first_value(f_games_count_cash_courchevel) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_courchevel_id ORDER BY f_date)
            ) AS f_games_count_cash_courchevel,
            
            COALESCE(f_games_count_cash_stud, first_value(f_games_count_cash_stud) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_stud_id ORDER BY f_date)
            ) AS f_games_count_cash_stud,
            
            COALESCE(f_games_count_cash_stud_hi_lo, first_value(f_games_count_cash_stud_hi_lo) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_stud_hi_lo_id ORDER BY f_date)
            ) AS f_games_count_cash_stud_hi_lo,
            
            COALESCE(f_games_count_cash_razz, first_value(f_games_count_cash_razz) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_razz_id ORDER BY f_date)
            ) AS f_games_count_cash_razz,
            
            COALESCE(f_games_count_cash_draw, first_value(f_games_count_cash_draw) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_draw_id ORDER BY f_date)
            ) AS f_games_count_cash_draw,
            
            COALESCE(f_games_count_cash_badugi, first_value(f_games_count_cash_badugi) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_badugi_id ORDER BY f_date)
            ) AS f_games_count_cash_badugi,
            
            COALESCE(f_games_count_cash_baduci, first_value(f_games_count_cash_baduci) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_baduci_id ORDER BY f_date)
            ) AS f_games_count_cash_baduci,
            
            COALESCE(f_games_count_cash_badacey, first_value(f_games_count_cash_badacey) 
                OVER (PARTITION BY f_player_id, f_games_count_cash_badacey_id ORDER BY f_date)
            ) AS f_games_count_cash_badacey,
            
            
            COALESCE(f_games_count_sng_texas, first_value(f_games_count_sng_texas) 
                OVER (PARTITION BY f_player_id, f_games_count_sng_texas_id ORDER BY f_date)
            ) AS f_games_count_sng_texas,
        
            COALESCE(f_games_count_sng_omaha, first_value(f_games_count_sng_omaha) 
                OVER (PARTITION BY f_player_id, f_games_count_sng_omaha_id ORDER BY f_date)
            ) AS f_games_count_sng_omaha,
            

            COALESCE(f_games_count_mtt_texas, first_value(f_games_count_mtt_texas) 
                OVER (PARTITION BY f_player_id, f_games_count_mtt_texas_id ORDER BY f_date)
            ) AS f_games_count_mtt_texas,
        
            COALESCE(f_games_count_mtt_omaha, first_value(f_games_count_mtt_omaha) 
                OVER (PARTITION BY f_player_id, f_games_count_mtt_omaha_id ORDER BY f_date)
            ) AS f_games_count_mtt_omaha,
            
            
            COALESCE(f_cumulative_cash_profit, first_value(f_cumulative_cash_profit) 
                OVER (PARTITION BY f_player_id, f_cumulative_cash_profit_id ORDER BY f_date)
            ) AS f_cumulative_cash_profit,
            
            COALESCE(f_cumulative_sng_profit, first_value(f_cumulative_sng_profit) 
                OVER (PARTITION BY f_player_id, f_cumulative_sng_profit_id ORDER BY f_date)
            ) AS f_cumulative_sng_profit,
            
            COALESCE(f_cumulative_mtt_profit, first_value(f_cumulative_mtt_profit) 
                OVER (PARTITION BY f_player_id, f_cumulative_mtt_profit_id ORDER BY f_date)
            ) AS f_cumulative_mtt_profit,
            
            COALESCE(f_cumulative_total_profit, first_value(f_cumulative_total_profit) 
                OVER (PARTITION BY f_player_id, f_cumulative_total_profit_id ORDER BY f_date)
            ) AS f_cumulative_total_profit,
            

            COALESCE(f_cumulative_balance, first_value(f_cumulative_balance) 
                OVER (PARTITION BY f_player_id, f_cumulative_balance_id ORDER BY f_date)
            ) AS f_cumulative_balance,


            COALESCE(f_last_deposit, first_value(f_last_deposit) 
                OVER (PARTITION BY f_player_id, f_last_deposit_id ORDER BY f_date)
            ) AS f_last_deposit,

            COALESCE(f_cumulative_deposit, first_value(f_cumulative_deposit) 
                OVER (PARTITION BY f_player_id, f_cumulative_deposit_id ORDER BY f_date)
            ) AS f_cumulative_deposit,

            COALESCE(f_cumulative_deposit_count, first_value(f_cumulative_deposit_count) 
                OVER (PARTITION BY f_player_id, f_cumulative_deposit_count_id ORDER BY f_date)
            ) AS f_cumulative_deposit_count,


            COALESCE(f_cumulative_cashouts, first_value(f_cumulative_cashouts) 
                OVER (PARTITION BY f_player_id, f_cumulative_cashouts_id ORDER BY f_date)
            ) AS f_cumulative_cashouts,

            
            COALESCE(f_cumulative_loyalty, first_value(f_cumulative_loyalty) 
                OVER (PARTITION BY f_player_id, f_cumulative_loyalty_id ORDER BY f_date)
            ) AS f_cumulative_loyalty,
            
            COALESCE(f_cumulative_cash_rake, first_value(f_cumulative_cash_rake) 
                OVER (PARTITION BY f_player_id, f_cumulative_cash_rake_id ORDER BY f_date)
            ) AS f_cumulative_cash_rake,
            
            COALESCE(f_cumulative_sng_rake, first_value(f_cumulative_sng_rake) 
                OVER (PARTITION BY f_player_id, f_cumulative_sng_rake_id ORDER BY f_date)
            ) AS f_cumulative_sng_rake,
            
            COALESCE(f_cumulative_mtt_rake, first_value(f_cumulative_mtt_rake)
                OVER (PARTITION BY f_player_id, f_cumulative_mtt_rake_id ORDER BY f_date)
            ) AS f_cumulative_mtt_rake,
            
            COALESCE(f_cumulative_total_rake, first_value(f_cumulative_total_rake)
                OVER (PARTITION BY f_player_id, f_cumulative_total_rake_id ORDER BY f_date)
            ) AS f_cumulative_total_rake,
            
            COALESCE(f_cumulative_net_rake, first_value(f_cumulative_net_rake)
                OVER (PARTITION BY f_player_id, f_cumulative_net_rake_id ORDER BY f_date)
            ) AS f_cumulative_net_rake,
            

            COALESCE(f_cumulative_session_count, first_value(f_cumulative_session_count)
                OVER (PARTITION BY f_player_id, f_cumulative_session_count_id ORDER BY f_date)
            ) AS f_cumulative_session_count,
            
            COALESCE(f_session_avg_length_in_minutes, first_value(f_session_avg_length_in_minutes)
                OVER (PARTITION BY f_player_id, f_session_avg_length_in_minutes_id ORDER BY f_date)
            ) AS f_session_avg_length_in_minutes,
            
            COALESCE(f_session_avg_game_count, first_value(f_session_avg_game_count)
                OVER (PARTITION BY f_player_id, f_session_avg_game_count_id ORDER BY f_date)
            ) AS f_session_avg_game_count,
            

            COALESCE(f_minutes_between_first_login_and_real_money_hand, first_value(f_minutes_between_first_login_and_real_money_hand)
                OVER (PARTITION BY f_player_id, f_minutes_between_first_login_and_real_money_hand_id ORDER BY f_date)
            ) AS f_minutes_between_first_login_and_real_money_hand
        FROM 
            t_with_metric_ids
        ORDER BY
            f_player_id,
            f_date
    )
    SELECT
        s.f_player_id,
        s.f_date,
        
        s.f_register_stamp,
        p.f_country,
        p.f_bonus_code,
        hf.f_house_flag,

        s.f_last_login_stamp,

        s.f_avg_stake,

        s.f_sng_avg_buy_in,
        s.f_mtt_avg_buy_in,

        s.f_balance_profit,
        s.f_cashout_profit,

        s.f_games_count_cash_texas,
        s.f_games_count_cash_omaha,
        s.f_games_count_cash_omaha_hi_lo,
        s.f_games_count_cash_omaha_five_card,
        s.f_games_count_cash_courchevel,
        s.f_games_count_cash_stud,
        s.f_games_count_cash_stud_hi_lo,
        s.f_games_count_cash_razz,
        s.f_games_count_cash_draw,
        s.f_games_count_cash_badugi,
        s.f_games_count_cash_baduci,
        s.f_games_count_cash_badacey,

        s.f_games_count_sng_texas,
        s.f_games_count_sng_omaha,
        
        s.f_games_count_mtt_texas,
        s.f_games_count_mtt_omaha,

        s.f_cumulative_cash_profit,
        s.f_cumulative_sng_profit,
        s.f_cumulative_mtt_profit,
        s.f_cumulative_total_profit,

        s.f_cumulative_balance,
        s.f_last_deposit,
        s.f_cumulative_deposit,
        s.f_cumulative_deposit_count,
        s.f_cumulative_cashouts,

        s.f_cumulative_loyalty,
        s.f_cumulative_cash_rake,
        s.f_cumulative_mtt_rake,
        s.f_cumulative_sng_rake,
        s.f_cumulative_total_rake,
        s.f_cumulative_net_rake,

        s.f_cumulative_session_count,
        (CASE 
            WHEN diff_in_weeks(s.f_date, s.f_register_stamp::DATE) > 0
            THEN s.f_cumulative_session_count / diff_in_weeks(s.f_date, s.f_register_stamp::DATE)
            ELSE 0
        END) AS f_session_count_by_week,
    
        s.f_session_avg_length_in_minutes,
        s.f_session_avg_game_count,
        
        s.f_minutes_between_first_login_and_real_money_hand
    FROM 
        t_cumulative_fin_state_by_day_with_null AS s,
        t_player AS p,
        t_house_flag AS hf
    WHERE
        p.f_id = s.f_player_id AND
        p.f_id = hf.f_player_id
    ORDER BY
        f_player_id,
        f_date
        
);
