CREATE TABLE t_group_activity
(
  f_id          INTEGER PRIMARY KEY                          NOT NULL,
  f_name        VARCHAR(255) DEFAULT '' :: CHARACTER VARYING NOT NULL,
  f_can_observe SMALLINT DEFAULT 0                           NOT NULL,
  f_can_play    SMALLINT DEFAULT 0                           NOT NULL
);
