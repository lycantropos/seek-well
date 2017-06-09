CREATE OR REPLACE VIEW v_registration AS (

    SELECT
        f_id AS f_player_id,
        f_register_stamp::DATE AS f_date,
        f_register_stamp
    FROM 
        t_player
);