CREATE OR REPLACE VIEW v_mtt_registrations AS (
    WITH
    tournaments_registrations AS (
        SELECT
            f_id,
            f_type,
            f_stamp,
            f_player_id,
            f_param_tournament_id
        FROM t_money_transactions 
        WHERE f_type = 66 
    ),
    tournaments AS (
        SELECT
            f_id,
            f_name,
            f_start_date
        FROM t_tournament
    ),
    registrations_with_bot_flag AS (
        SELECT
            f_id,
            f_stamp,
            f_player_id,
            f_param_tournament_id AS tournament_id,
            (CASE 
                WHEN f_house_flag = 1 THEN TRUE 
                ELSE FALSE 
            END) AS is_bot
        FROM tournaments_registrations
        LEFT OUTER JOIN t_house_flag USING(f_player_id)
        
    ),
    registration_with_participation AS (
        SELECT
            * ,
            COUNT (*) FILTER(WHERE is_bot IS TRUE) OVER w AS bot_participation_count,
            COUNT (*) FILTER(WHERE is_bot IS FALSE) OVER w AS human_participation_count
        FROM registrations_with_bot_flag
        WINDOW w AS (
            PARTITION BY tournament_id ORDER BY f_stamp
        )
    )
    SELECT
        f_name AS tournament_name,
        f_start_date AS tournament_start,
        f_stamp AS latest_registration,
        human_participation_count,
        bot_participation_count
    FROM registration_with_participation
    LEFT OUTER JOIN tournaments ON registration_with_participation.tournament_id = tournaments.f_id
);