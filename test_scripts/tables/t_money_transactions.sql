CREATE TABLE t_money_transactions
(
    f_id BIGINT DEFAULT 0 PRIMARY KEY NOT NULL,
    f_type BIGINT DEFAULT 0 NOT NULL,
    f_stamp TIMESTAMP NOT NULL,
    f_player_id BIGINT DEFAULT 0 NOT NULL,
    f_param_table_id BIGINT DEFAULT 0 NOT NULL,
    f_value BIGINT DEFAULT 0 NOT NULL,
    f_param_tournament_id BIGINT DEFAULT 0 NOT NULL,
    f_money_type CHAR DEFAULT ''::character(1) NOT NULL,
    f_param_player_id BIGINT DEFAULT 0 NOT NULL,
    f_param_game_id BIGINT DEFAULT 0 NOT NULL,
    f_restore SMALLINT DEFAULT 0 NOT NULL,
    f_param_money_type CHAR DEFAULT ''::character(1) NOT NULL,
    f_param_value DOUBLE PRECISION DEFAULT 0 NOT NULL,
    f_param_notes VARCHAR(255) DEFAULT ''::character varying NOT NULL,
    f_param_transaction_id BIGINT DEFAULT 0 NOT NULL,
    f_param_server_id BIGINT DEFAULT 0 NOT NULL,
    f_pended SMALLINT DEFAULT 0 NOT NULL,
    f_subtype INTEGER DEFAULT 0 NOT NULL,
    f_param_fee_transaction_id INTEGER DEFAULT 0 NOT NULL,
    f_param_player_entry_idx BIGINT DEFAULT 0 NOT NULL
);
