CREATE TABLE t_game
(
    f_id BIGINT DEFAULT 0 PRIMARY KEY NOT NULL,
    f_table_id BIGINT DEFAULT 0 NOT NULL,
    f_started_stamp TIMESTAMP NOT NULL,
    f_ended_stamp TIMESTAMP NOT NULL,
    f_table_cards VARCHAR(255) DEFAULT ''::character varying NOT NULL,
    f_table_cards_lower_row VARCHAR(255) DEFAULT ''::character varying NOT NULL,
    f_rake BIGINT DEFAULT 0 NOT NULL,
    f_ff_real_table_id BIGINT DEFAULT 0 NOT NULL
);
