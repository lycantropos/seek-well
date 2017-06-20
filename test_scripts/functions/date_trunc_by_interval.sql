CREATE OR REPLACE FUNCTION date_trunc_by_interval(f_stamp TIMESTAMP WITHOUT TIME ZONE, f_interval INTERVAL) RETURNS TIMESTAMP WITHOUT TIME ZONE AS $$
DECLARE
    epoch_interval DOUBLE PRECISION:= EXTRACT('epoch' FROM f_interval);
BEGIN
RETURN TO_TIMESTAMP(
        FLOOR(EXTRACT('epoch' FROM f_stamp) / epoch_interval)
        * epoch_interval
    ) AT TIME ZONE 'UTC';
END;
$$ LANGUAGE PLPGSQL
IMMUTABLE;
