CREATE TABLE t_table_group_activity_assignement
(
    f_id INTEGER DEFAULT nextval('t_table_group_activity_assignement_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_table_id BIGINT NOT NULL,
    f_group_activity_id BIGINT NOT NULL
);
