DROP SCHEMA IF EXISTS replication CASCADE;
CREATE SCHEMA replication;
CREATE TABLE replication.work_table (
    id BIGSERIAL PRIMARY KEY,
    int_field INTEGER,
    text_field TEXT,
    date_field TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE replication.repl_work_table (
    id BIGINT,
    int_field INTEGER,
    text_field TEXT,
    date_field TIMESTAMPTZ,
    __unique_id BIGSERIAL PRIMARY KEY
);
CREATE TABLE replication.replication_queue (
    id BIGSERIAL PRIMARY KEY,
    xact_id TEXT DEFAULT pg_current_xact_id()::TEXT,
    op_time TIMESTAMPTZ DEFAULT clock_timestamp(),
    table_name TEXT,
    repl_unique_id BIGINT,
    change_type CHAR(1) CHECK (change_type IN ('I', 'U', 'D'))
);
CREATE OR REPLACE FUNCTION replication.process_work_table()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    new_uid BIGINT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO replication.repl_work_table (id, int_field, text_field, date_field)
        VALUES (NEW.id, NEW.int_field, NEW.text_field, NEW.date_field)
        RETURNING __unique_id INTO new_uid;
        INSERT INTO replication.replication_queue (table_name, repl_unique_id, change_type)
        VALUES ('replication.work_table', new_uid, 'I');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD IS NOT DISTINCT FROM NEW THEN
            RETURN NEW;
        END IF;
        INSERT INTO replication.repl_work_table (id, int_field, text_field, date_field)
        VALUES (NEW.id, NEW.int_field, NEW.text_field, NEW.date_field)
        RETURNING __unique_id INTO new_uid;
        INSERT INTO replication.replication_queue (table_name, repl_unique_id, change_type)
        VALUES ('replication.work_table', new_uid, 'U');
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO replication.repl_work_table (id, int_field, text_field, date_field)
        VALUES (OLD.id, OLD.int_field, OLD.text_field, OLD.date_field)
        RETURNING __unique_id INTO new_uid;
        INSERT INTO replication.replication_queue (table_name, repl_unique_id, change_type)
        VALUES ('replication.work_table', new_uid, 'D');
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;
DROP TRIGGER IF EXISTS work_table_repl_trigger ON replication.work_table;
CREATE TRIGGER work_table_repl_trigger
AFTER INSERT OR UPDATE OR DELETE ON replication.work_table
FOR EACH ROW EXECUTE FUNCTION replication.process_work_table();