CREATE TABLE t_balance
(
  f_id         BIGINT DEFAULT 0 PRIMARY KEY    NOT NULL,
  f_player_id  BIGINT DEFAULT 0                NOT NULL,
  f_money_type CHAR DEFAULT '' :: CHARACTER(1) NOT NULL,
  f_balance    BIGINT DEFAULT 0                NOT NULL,
  f_in_play    BIGINT DEFAULT 0                NOT NULL
);
