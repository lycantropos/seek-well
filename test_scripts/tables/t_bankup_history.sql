CREATE TABLE t_bankup_history
(
    f_id INTEGER DEFAULT nextval('t_bankup_history_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_player_id BIGINT DEFAULT 0 NOT NULL,
    f_nick VARCHAR(32) DEFAULT ''::character varying NOT NULL,
    f_multiplier DOUBLE PRECISION DEFAULT 0.00 NOT NULL,
    f_jackpot_multiplier DOUBLE PRECISION DEFAULT 0.00 NOT NULL,
    f_prize_amount BIGINT DEFAULT 0 NOT NULL,
    f_time_stamp TIMESTAMP NOT NULL,
    f_game_id BIGINT DEFAULT 0 NOT NULL,
    f_money_type CHAR DEFAULT ''::character(1) NOT NULL,
    f_transaction_id BIGINT DEFAULT 0 NOT NULL,
    f_moneybox_rest BIGINT DEFAULT 0 NOT NULL,
    f_tournament_id BIGINT DEFAULT 0 NOT NULL,
    f_table_id BIGINT DEFAULT 0 NOT NULL
);
