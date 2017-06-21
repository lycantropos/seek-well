CREATE TABLE t_temp_funds
(
    f_id INTEGER DEFAULT nextval('t_temp_funds_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_player_id INTEGER DEFAULT 0 NOT NULL,
    f_hold BIGINT,
    f_omah BIGINT,
    f_omah_hi BIGINT,
    f_7stud BIGINT,
    f_7stud_hi BIGINT,
    f_tour BIGINT,
    f_sitngo BIGINT,
    f_deposit BIGINT,
    f_withdrawal BIGINT,
    f_total BIGINT
);
