CREATE TABLE t_cooperative_block
(
  f_id             INTEGER PRIMARY KEY   NOT NULL,
  f_player1_id     BIGINT                NOT NULL,
  f_player2_id     BIGINT                NOT NULL,
  f_block_cash     BOOLEAN DEFAULT FALSE NOT NULL,
  f_block_sng      BOOLEAN DEFAULT FALSE NOT NULL,
  f_block_mtt      BOOLEAN DEFAULT FALSE NOT NULL,
  f_block_transfer BOOLEAN DEFAULT FALSE NOT NULL
);
