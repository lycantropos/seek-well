CREATE TABLE t_table_events
(
  f_id               INTEGER PRIMARY KEY NOT NULL,
  f_table_id         BIGINT DEFAULT 0    NOT NULL,
  f_chunk_start      TIMESTAMP           NOT NULL,
  f_events           TEXT                NOT NULL,
  f_ff_real_table_id BIGINT DEFAULT 0    NOT NULL
);
