CREATE TABLE t_ticket_ticket_activity_assignement
(
    f_id INTEGER DEFAULT nextval('t_ticket_ticket_activity_assignement_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_ticket_id BIGINT NOT NULL,
    f_ticket_activity_id BIGINT NOT NULL
);
