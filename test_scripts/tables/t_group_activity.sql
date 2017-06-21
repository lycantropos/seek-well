CREATE TABLE t_group_activity
(
    f_id INTEGER DEFAULT nextval('t_group_activity_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_name VARCHAR(255) DEFAULT ''::character varying NOT NULL,
    f_can_observe SMALLINT DEFAULT 0 NOT NULL,
    f_can_play SMALLINT DEFAULT 0 NOT NULL
);
