CREATE TABLE t_achievements
(
  f_id        INTEGER PRIMARY KEY NOT NULL,
  f_player_id BIGINT DEFAULT 0    NOT NULL,
  f_type      BIGINT DEFAULT 0    NOT NULL,
  f_value     BIGINT DEFAULT 0    NOT NULL,
  f_stamp     TIMESTAMP           NOT NULL
);
