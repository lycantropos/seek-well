CREATE TABLE t_regulars_game_environment_settings_log
(
    f_id INTEGER DEFAULT nextval('t_regulars_game_environment_settings_log_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_player_id BIGINT,
    f_name VARCHAR,
    f_value SMALLINT,
    f_stamp TIMESTAMP
);
