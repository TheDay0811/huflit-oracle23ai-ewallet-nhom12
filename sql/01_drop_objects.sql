-- ============================================================================
-- 01_drop_objects.sql
-- Don dep toan bo doi tuong trong schema EWALLET_APP de chay lai tu dau an toan
-- Tuong thich DBeaver (Alt+X) va SQL*Plus
-- ============================================================================

DECLARE
    PROCEDURE safe_drop(p_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;
BEGIN
    -- 1. Drop Triggers
    FOR r IN (SELECT trigger_name FROM user_triggers) LOOP
        safe_drop('DROP TRIGGER ' || r.trigger_name);
    END LOOP;

    -- 2. Drop Packages
    FOR r IN (SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE') LOOP
        safe_drop('DROP PACKAGE ' || r.object_name);
    END LOOP;

    -- 3. Drop Procedures and Functions
    FOR r IN (SELECT object_name, object_type FROM user_objects WHERE object_type IN ('PROCEDURE', 'FUNCTION')) LOOP
        safe_drop('DROP ' || r.object_type || ' ' || r.object_name);
    END LOOP;

    -- 4. Drop Views
    FOR r IN (SELECT view_name FROM user_views) LOOP
        safe_drop('DROP VIEW ' || r.view_name);
    END LOOP;

    -- 5. Drop Tables
    FOR r IN (SELECT table_name FROM user_tables) LOOP
        safe_drop('DROP TABLE ' || r.table_name || ' CASCADE CONSTRAINTS PURGE');
    END LOOP;

    -- 6. Drop Sequences
    FOR r IN (SELECT sequence_name FROM user_sequences) LOOP
        safe_drop('DROP SEQUENCE ' || r.sequence_name);
    END LOOP;
END;
/
