CREATE TABLE t_accumulated_jackpot
(
    f_id INTEGER DEFAULT nextval('t_accumulated_jackpot_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_type CHAR DEFAULT ''::character(1) NOT NULL,
    f_amount BIGINT DEFAULT 0 NOT NULL
);
