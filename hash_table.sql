CREATE OR REPLACE FUNCTION get_table_hash_sum(_table_name TEXT)
RETURNS BIGINT
LANGUAGE plpgsql AS $$
DECLARE
    cols_expr TEXT;
    hash_sum  BIGINT;
    mod_val   CONSTANT BIGINT := 1000000000000000000; -- 10^18
BEGIN
    SELECT string_agg(
        CASE 
            WHEN is_nullable = 'YES' THEN 
                format('coalesce(format(''(%s)%%s'', %I::text), ''(%s)<null>'')', data_type, column_name, data_type)
            ELSE 
                format('format(''(%s)%%s'', %I::text)', data_type, column_name)
        END, 
        ' || '
    )
    INTO cols_expr
    FROM information_schema.columns
    WHERE table_name = _table_name 
      AND table_schema = current_schema()
    ORDER BY ordinal_position;
    IF cols_expr IS NULL THEN
        RETURN 0;
    END IF;
   EXECUTE format($sql$
        SELECT COALESCE(
            SUM(ABS(hashtextextended(%s || %L, 0) %% %s)) %% %s, 
            0
        )::BIGINT
        FROM %I
    $sql$, 
    cols_expr, _table_name, mod_val, mod_val, _table_name) 
    INTO hash_sum;
    RETURN hash_sum;
END;
$$;