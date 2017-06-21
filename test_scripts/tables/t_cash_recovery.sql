CREATE TABLE t_cash_recovery
(
    f_id INTEGER DEFAULT nextval('t_cash_recovery_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_table_id INTEGER NOT NULL,
    f_player_id INTEGER NOT NULL,
    f_start_amount BIGINT NOT NULL,
    f_last_amount BIGINT NOT NULL,
    f_money_type CHAR NOT NULL,
    f_player_entry_idx BIGINT DEFAULT 0 NOT NULL
);
