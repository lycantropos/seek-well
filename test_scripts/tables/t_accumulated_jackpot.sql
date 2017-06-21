CREATE TABLE t_accumulated_jackpot
(
  f_id     INTEGER PRIMARY KEY             NOT NULL,
  f_type   CHAR DEFAULT '' :: CHARACTER(1) NOT NULL,
  f_amount BIGINT DEFAULT 0                NOT NULL
);
