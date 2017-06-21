CREATE TABLE t_temp_tables
(
    f_id INTEGER DEFAULT nextval('t_temp_tables_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_table VARCHAR(255) DEFAULT ''::character varying NOT NULL,
    f_time INTEGER DEFAULT 0 NOT NULL
);
