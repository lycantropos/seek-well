CREATE TABLE t_financial_limits
(
  f_id                          INTEGER PRIMARY KEY NOT NULL,
  f_player_id                   BIGINT              NOT NULL,
  f_limit_cash                  BIGINT DEFAULT 0    NOT NULL,
  f_limit_sng                   BIGINT DEFAULT 0    NOT NULL,
  f_limit_mtt                   BIGINT DEFAULT 0    NOT NULL,
  f_limit_p2p                   BIGINT DEFAULT 0    NOT NULL,
  f_limit_withdraw              BIGINT DEFAULT 0    NOT NULL,
  f_limit_all                   BIGINT DEFAULT 0    NOT NULL,
  f_info_transfer_money_limit   BIGINT DEFAULT 0    NOT NULL,
  f_info_tournament_money_limit BIGINT DEFAULT 0    NOT NULL
);
