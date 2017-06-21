CREATE TABLE t_payment_transactions
(
    f_id INTEGER DEFAULT nextval('t_payment_transactions_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_player_id INTEGER,
    f_amount BIGINT,
    f_payment_system VARCHAR,
    f_internal_id INTEGER
);
