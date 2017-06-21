CREATE TABLE t_bad_nicks
(
    f_id INTEGER DEFAULT nextval('t_bad_nicks_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_nick VARCHAR(255) NOT NULL
);
