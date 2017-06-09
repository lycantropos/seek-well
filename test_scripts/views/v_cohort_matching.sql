CREATE OR REPLACE VIEW v_cohort_matching AS (

    SELECT
        f_player_id,
        f_group_activity_id
    FROM
        t_player_group_activity_assignement
    
);