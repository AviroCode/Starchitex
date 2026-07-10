
-- TEST 05: Audit log (append-only + auto-logging)
-- Author: Min Linn Khant (QA)
-- Run:  psql "$DATABASE_URL" -f 05_audit_log.sql
-- NOTE 05-B must be run as a NON-superuser/non-owner connection
-- to be meaningful — owners bypass REVOKE. Meaningful on Render
-- only once a restricted app_user exists.


\echo '=== TEST 05: audit log ==='

DO $$
DECLARE
  v_branch INT; v_emp INT; v_log INT; v_ok BOOLEAN;
BEGIN
  -- ---------- SETUP ----------
  INSERT INTO branch (name,address,city,province,postal_code,email,phone)
  VALUES ('ZZTEST Branch05','1 Test Rd','Testville','TestProv','00000','zztest05@test.com','000')
  RETURNING branch_id INTO v_branch;
  INSERT INTO employee (branch_id, first_name, last_name, position, date_of_birth, email, hire_date)
  VALUES (v_branch,'ZZTest','Auditor','Admin','1990-01-01','zztestaudit05@test.com','2025-01-01')
  RETURNING employee_id INTO v_emp;

  -- ---------- 05-A: audit rows can be written with full detail ----------
  INSERT INTO audit_log (employee_id, action, table_name, pk_of_table, affected_col, old_value, new_value, IP_address)
  VALUES (v_emp, 'UPDATE', 'reservation', '999', 'status', 'Pending', 'Confirmed', '127.0.0.1')
  RETURNING log_id INTO v_log;
  IF v_log IS NOT NULL THEN RAISE NOTICE 'TEST 05-A: PASS — audit row written';
  ELSE RAISE NOTICE 'TEST 05-A: FAIL'; END IF;

  -- ---------- 05-B: audit log must be append-only ----------
  v_ok := FALSE;
  BEGIN
    UPDATE audit_log SET new_value='TAMPERED' WHERE log_id=v_log;
    v_ok := TRUE;
  EXCEPTION WHEN insufficient_privilege OR OTHERS THEN
    RAISE NOTICE 'TEST 05-B: PASS — audit UPDATE rejected (append-only enforced)';
  END;
  IF v_ok THEN
    RAISE NOTICE 'TEST 05-B: FAIL — audit row was modified. (KNOWN-FAIL until REVOKE UPDATE/DELETE is applied; also run as non-owner to be meaningful.)';
  END IF;

  -- ---------- 05-C..D: stubs until audit triggers exist ----------
  RAISE NOTICE 'TEST 05-C: SKIP — reservation status change auto-creates audit row (needs trigger)';
  RAISE NOTICE 'TEST 05-D: SKIP — payment insert auto-creates audit row (needs trigger)';

  -- ---------- CLEANUP ----------
  DELETE FROM audit_log WHERE log_id=v_log;
  DELETE FROM employee WHERE employee_id=v_emp;
  DELETE FROM branch WHERE branch_id=v_branch;
END $$;

\echo '=== TEST 05 done ==='
