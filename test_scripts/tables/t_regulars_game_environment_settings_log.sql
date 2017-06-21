CREATE TABLE t_regulars_game_environment_settings_log
(
  f_id        INTEGER PRIMARY KEY NOT NULL,
  f_player_id BIGINT,
  f_name      VARCHAR,
  f_value     SMALLINT,
  f_stamp     TIMESTAMP
);
