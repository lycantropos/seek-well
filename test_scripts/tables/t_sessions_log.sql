CREATE TABLE t_sessions_log
(
  f_id              INTEGER PRIMARY KEY                          NOT NULL,
  f_ip              VARCHAR(100) DEFAULT '' :: CHARACTER VARYING NOT NULL,
  f_int_ip          BIGINT DEFAULT 0                             NOT NULL,
  f_player_id       BIGINT DEFAULT 0                             NOT NULL,
  f_connected_stamp TIMESTAMP                                    NOT NULL,
  f_start_stamp     TIMESTAMP                                    NOT NULL,
  f_end_stamp       TIMESTAMP                                    NOT NULL,
  f_channel         VARCHAR(100) DEFAULT '' :: CHARACTER VARYING NOT NULL,
  f_session_id      BIGINT DEFAULT 0                             NOT NULL,
  f_auth            VARCHAR(100) DEFAULT '' :: CHARACTER VARYING NOT NULL,
  f_device_label    VARCHAR(255) DEFAULT '' :: CHARACTER VARYING NOT NULL,
  f_regular_close   SMALLINT DEFAULT 0                           NOT NULL
);
