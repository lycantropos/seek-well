CREATE TABLE t_cooperative_block
(
    f_id INTEGER DEFAULT nextval('t_cooperative_block_f_id_seq'::regclass) PRIMARY KEY NOT NULL,
    f_player1_id BIGINT NOT NULL,
    f_player2_id BIGINT NOT NULL,
    f_block_cash BOOLEAN DEFAULT false NOT NULL,
    f_block_sng BOOLEAN DEFAULT false NOT NULL,
    f_block_mtt BOOLEAN DEFAULT false NOT NULL,
    f_block_transfer BOOLEAN DEFAULT false NOT NULL
);
