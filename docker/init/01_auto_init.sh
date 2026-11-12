#!/bin/bash
set -e
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

echo "================================================================="
echo "[INIT] Dang khoi tao Schema EWALLET_APP tren Oracle 23ai FREEPDB1..."
echo "================================================================="

run_sql_as_sys() {
  local file="$1"
  echo "[SYS] Dang chay $file ..."
  {
    echo "WHENEVER SQLERROR EXIT SQL.SQLCODE;"
    echo "SET DEFINE OFF;"
    cat "$file"
    echo ""
    echo "EXIT;"
  } | sqlplus -s "sys/${ORACLE_PWD:-Oracle23ai}@//localhost:1521/FREEPDB1 as sysdba"
}

run_sql_as_app() {
  local file="$1"
  echo "[EWALLET_APP] Dang chay $file ..."
  {
    echo "WHENEVER SQLERROR EXIT SQL.SQLCODE;"
    echo "SET DEFINE OFF;"
    cat "$file"
    echo ""
    echo "EXIT;"
  } | sqlplus -s "EWALLET_APP/Ewallet2026@//localhost:1521/FREEPDB1"
}

run_sql_as_sys "/opt/oracle/user_sql/00_docker_sys_setup.sql"
run_sql_as_app "/opt/oracle/user_sql/01_drop_objects.sql"
run_sql_as_app "/opt/oracle/user_sql/02_tables_constraints.sql"
run_sql_as_app "/opt/oracle/user_sql/03_sequences_indexes.sql"
run_sql_as_app "/opt/oracle/user_sql/04_seed_data.sql"
run_sql_as_app "/opt/oracle/user_sql/05_pkg_ngoai_le_vi.sql"
run_sql_as_app "/opt/oracle/user_sql/06_functions.sql"
run_sql_as_app "/opt/oracle/user_sql/07_pkg_quan_ly_vi.sql"
run_sql_as_app "/opt/oracle/user_sql/08_triggers.sql"

echo "================================================================="
echo "[INIT] Hoan tat khoi tao EWALLET_APP tren Oracle Database 23ai!"
echo "================================================================="
