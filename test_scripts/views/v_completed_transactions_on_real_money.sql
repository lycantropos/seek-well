CREATE OR REPLACE VIEW v_completed_transactions_on_real_money AS (
    
    SELECT *
    FROM t_money_transactions
    WHERE
        f_pended IN (0, 4) AND
        f_money_type = 'R'
        
);