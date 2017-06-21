CREATE TABLE t_chat_log
(
    f_id INTEGER DEFAULT nextval('t_chat_log_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_table_id BIGINT DEFAULT 0,
    f_tournament_id BIGINT DEFAULT 0,
    f_player_id BIGINT DEFAULT 0,
    f_stamp TIMESTAMP,
    f_text VARCHAR(4095) DEFAULT ''::character varying NOT NULL,
    f_ff_real_table_id BIGINT DEFAULT 0 NOT NULL
);
