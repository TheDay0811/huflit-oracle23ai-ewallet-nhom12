-- ============================================================================
-- 00_docker_sys_setup.sql
-- Chay voi quyen SYS AS SYSDBA tren Oracle Database 23ai (FREEPDB1)
-- Tuong thich DBeaver (Alt+X) va SQL*Plus / Docker
-- ============================================================================

ALTER SESSION SET CONTAINER = FREEPDB1;

DECLARE
    v_count NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM dba_users
     WHERE username = 'EWALLET_APP';

    IF v_count = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE USER ewallet_app IDENTIFIED BY "Ewallet2026"
            DEFAULT TABLESPACE USERS
            TEMPORARY TABLESPACE TEMP
            QUOTA UNLIMITED ON USERS';
    ELSE
        EXECUTE IMMEDIATE 'ALTER USER ewallet_app IDENTIFIED BY "Ewallet2026" ACCOUNT UNLOCK';
        EXECUTE IMMEDIATE 'ALTER USER ewallet_app QUOTA UNLIMITED ON USERS';
    END IF;
END;
/

GRANT CONNECT, RESOURCE TO ewallet_app;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE SYNONYM, CREATE TYPE TO ewallet_app;
GRANT SELECT_CATALOG_ROLE TO ewallet_app;
