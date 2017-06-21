CREATE TABLE t_temp_tables
(
  f_id    INTEGER PRIMARY KEY                          NOT NULL,
  f_table VARCHAR(255) DEFAULT '' :: CHARACTER VARYING NOT NULL,
  f_time  INTEGER DEFAULT 0                            NOT NULL
);
