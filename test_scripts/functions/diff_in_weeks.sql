CREATE OR REPLACE FUNCTION diff_in_weeks(max_date DATE, min_date DATE)
  RETURNS DOUBLE PRECISION AS $$
BEGIN
  RETURN (max_date - min_date) :: NUMERIC / 7;
END;
$$ LANGUAGE PLPGSQL;