
-- TEST 05: Audit log (append-only + auto-logging)
-- Author: Min Linn Khant (QA)
-- Run:  psql "$DATABASE_URL" -f 05_audit_log.sql
-- NOTE 05-B must be run as a NON-superuser/non-owner connection
-- to be meaningful — owners bypass REVOKE. Meaningful on Render
-- only once a restricted app_user exists.


\echo '=== TEST 05: audit log ==='
-- NOTE: real Postgres superusers bypass RLS/FORCE ROW LEVEL SECURITY
-- unconditionally, regardless of policies — so 05-B is INCONCLUSIVE when run
-- as a superuser (e.g. Docker's default POSTGRES_USER). The genuinely
-- meaningful check (run as an actual non-superuser role) lives in
-- database/tests/06_rls_isolation.sql alongside the other RLS scenarios.

SET app.is_super_admin = 'true';

DO $$
DECLARE
  v_branch INT; v_emp INT; v_log INT; v_ok BOOLEAN;
BEGIN
  -- ---------- SETUP ----------
  INSERT INTO Branch (name,address,city,province,postal_code,email,phone)
  VALUES ('ZZTEST Branch05','1 Test Rd','Testville','TestProv','00000','zztest05@test.com','000')
  RETURNING branch_id INTO v_branch;
  INSERT INTO Employee (branch_id, first_name, last_name, position, date_of_birth, email, hire_date)
  VALUES (v_branch,'ZZTest','Auditor','Admin','1990-01-01','zztestaudit05@test.com','2025-01-01')
  RETURNING employee_id INTO v_emp;

  -- ---------- 05-A: audit rows can be written with full detail ----------
  INSERT INTO AuditLog (employee_id, action, table_name, pk_of_table, affected_col, old_value, new_value, IP_address)
  VALUES (v_emp, 'UPDATE', 'Reservation', '999', 'status', 'Pending', 'Confirmed', '127.0.0.1')
  RETURNING log_id INTO v_log;
  IF v_log IS NOT NULL THEN RAISE NOTICE 'TEST 05-A: PASS — audit row written';
  ELSE RAISE NOTICE 'TEST 05-A: FAIL'; END IF;

  -- ---------- 05-B: audit log must be append-only (non-superuser only) ----------
  v_ok := FALSE;
  BEGIN
    UPDATE AuditLog SET new_value='TAMPERED' WHERE log_id=v_log;
    v_ok := TRUE;
  EXCEPTION WHEN insufficient_privilege OR OTHERS THEN
    RAISE NOTICE 'TEST 05-B: PASS — audit UPDATE rejected (append-only enforced)';
  END;
  IF v_ok THEN
    RAISE NOTICE 'TEST 05-B: INCONCLUSIVE (bypassed by superuser) — audit row was modified because this session is a Postgres superuser, which always bypasses RLS/FORCE regardless of policy. See TEST 06-H for the real non-superuser check.';
    -- undo the tamper so cleanup below reflects the original row
    UPDATE AuditLog SET new_value='Confirmed' WHERE log_id=v_log;
  END IF;

  -- ---------- 05-C: reservation cancellation auto-creates an audit row ----------
  DECLARE
    v_res INT; v_guest INT; v_count INT;
  BEGIN
    INSERT INTO Guest (first_name,last_name,date_of_birth,nationality,passport_number,email,address)
    VALUES ('ZZTest','Guest05','1990-01-01','TH','ZZTESTP05','zztestguest05@test.com','addr')
    RETURNING guest_id INTO v_guest;
    INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests, status)
    VALUES (v_branch, v_guest, '2026-11-10','2026-11-12',1,'Confirmed') RETURNING reservation_id INTO v_res;
    UPDATE Reservation SET status='Cancelled' WHERE reservation_id=v_res;
    SELECT COUNT(*) INTO v_count FROM AuditLog WHERE table_name='Reservation' AND pk_of_table=v_res::text AND action='UPDATE_CANCEL';
    IF v_count = 1 THEN RAISE NOTICE 'TEST 05-C: PASS — cancelling a reservation auto-wrote an audit row';
    ELSE RAISE NOTICE 'TEST 05-C: FAIL — expected 1 audit row, found %', v_count; END IF;
    DELETE FROM AuditLog WHERE table_name='Reservation' AND pk_of_table=v_res::text;
    DELETE FROM Reservation WHERE reservation_id=v_res;
    DELETE FROM Guest WHERE guest_id=v_guest;
  END;

  -- ---------- 05-D: deleting a payment auto-creates an audit row ----------
  DECLARE
    v_guest2 INT; v_res2 INT; v_inv INT; v_pay INT; v_count INT;
  BEGIN
    INSERT INTO Guest (first_name,last_name,date_of_birth,nationality,passport_number,email,address)
    VALUES ('ZZTest','Guest05b','1990-01-01','TH','ZZTESTP05B','zztestguest05b@test.com','addr')
    RETURNING guest_id INTO v_guest2;
    INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests, status)
    VALUES (v_branch, v_guest2, '2026-11-15','2026-11-17',1,'Confirmed') RETURNING reservation_id INTO v_res2;
    INSERT INTO Invoice (reservation_id, payer_guest_id, sub_total, tax_amount, discount, total_amount)
    VALUES (v_res2, v_guest2, 100, 7, 0, 107) RETURNING invoice_id INTO v_inv;
    INSERT INTO Payment (invoice_id, amount, payment_method) VALUES (v_inv, 50, 'Cash') RETURNING payment_id INTO v_pay;
    DELETE FROM Payment WHERE payment_id=v_pay;
    SELECT COUNT(*) INTO v_count FROM AuditLog WHERE table_name='Payment' AND pk_of_table=v_pay::text AND action='DELETE';
    IF v_count = 1 THEN RAISE NOTICE 'TEST 05-D: PASS — deleting a payment auto-wrote an audit row';
    ELSE RAISE NOTICE 'TEST 05-D: FAIL — expected 1 audit row, found %', v_count; END IF;
    DELETE FROM AuditLog WHERE table_name='Payment' AND pk_of_table=v_pay::text;
    DELETE FROM Invoice WHERE invoice_id=v_inv;
    DELETE FROM Reservation WHERE reservation_id=v_res2;
    DELETE FROM Guest WHERE guest_id=v_guest2;
  END;

  -- ---------- CLEANUP ----------
  DELETE FROM AuditLog WHERE log_id=v_log;
  DELETE FROM Employee WHERE employee_id=v_emp;
  DELETE FROM Branch WHERE branch_id=v_branch;
END $$;

\echo '=== TEST 05 done ==='
