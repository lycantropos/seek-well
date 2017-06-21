CREATE TABLE t_announce
(
  f_id          BIGINT PRIMARY KEY                            NOT NULL,
  f_author_id   BIGINT DEFAULT 0                              NOT NULL,
  f_comment     VARCHAR(255) DEFAULT '' :: CHARACTER VARYING  NOT NULL,
  f_text        VARCHAR(4095) DEFAULT '' :: CHARACTER VARYING NOT NULL,
  f_action      VARCHAR(255) DEFAULT '' :: CHARACTER VARYING  NOT NULL,
  f_show_time   BIGINT DEFAULT 15                             NOT NULL,
  f_start_stamp TIMESTAMP                                     NOT NULL,
  f_end_stamp   TIMESTAMP                                     NOT NULL,
  f_period      BIGINT DEFAULT 300                            NOT NULL,
  f_last_posted TIMESTAMP                                     NOT NULL,
  f_num_posts   BIGINT DEFAULT 0                              NOT NULL,
  f_active      SMALLINT DEFAULT 1                            NOT NULL
);
