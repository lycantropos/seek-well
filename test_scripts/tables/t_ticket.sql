CREATE TABLE t_ticket
(
  f_id                  INTEGER PRIMARY KEY                          NOT NULL,
  f_is_template         SMALLINT DEFAULT 0                           NOT NULL,
  f_name                VARCHAR(255) DEFAULT '' :: CHARACTER VARYING NOT NULL,
  f_ticket_ttl_in_hours BIGINT DEFAULT 0                             NOT NULL,
  f_expiration_date     TIMESTAMP,
  f_status              CHAR DEFAULT '' :: CHARACTER(1)              NOT NULL,
  f_amount              BIGINT DEFAULT 0                             NOT NULL,
  f_money_type          CHAR DEFAULT '' :: CHARACTER(1)              NOT NULL,
  f_is_convertible      SMALLINT DEFAULT 0                           NOT NULL,
  f_player_id           BIGINT DEFAULT 0                             NOT NULL,
  f_hidden              SMALLINT DEFAULT 0                           NOT NULL
);
