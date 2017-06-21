CREATE TABLE t_server
(
    f_id BIGINT DEFAULT 0 PRIMARY KEY NOT NULL,
    f_ip VARCHAR(255) DEFAULT ''::character varying NOT NULL,
    f_slot_id VARCHAR(255) DEFAULT ''::character varying NOT NULL,
    f_started_stamp TIMESTAMP NOT NULL,
    f_ended_stamp TIMESTAMP NOT NULL,
    f_closed SMALLINT DEFAULT 0 NOT NULL,
    f_close_reason VARCHAR(255) DEFAULT ''::character varying NOT NULL,
    f_server_type CHAR DEFAULT ''::character(1) NOT NULL
);
