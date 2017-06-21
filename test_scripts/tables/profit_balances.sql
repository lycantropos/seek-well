CREATE TABLE profit_balances
(
    id BIGINT DEFAULT nextval('profit_balances_id_seq'::regclass) NOT NULL,
    player_id BIGINT,
    transaction_id BIGINT,
    transaction_type BIGINT,
    transaction_value BIGINT,
    stamp TIMESTAMP,
    increment_value BIGINT,
    increment_type VARCHAR,
    balance BIGINT,
    total_profit BIGINT,
    balance_profit BIGINT,
    deposit_profit BIGINT,
    cashout_profit BIGINT
);
