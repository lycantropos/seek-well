CREATE TABLE t_temp_lost_money
(
  f_id             INTEGER PRIMARY KEY NOT NULL,
  f_player_id      INTEGER DEFAULT 0   NOT NULL,
  f_transaction_id INTEGER,
  f_sum_bet        BIGINT,
  f_sum_pot        BIGINT,
  f_sum_diff       BIGINT
);
