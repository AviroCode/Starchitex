-- TEST 06: Row-Level Security isolation
-- Formalizes the manual scenarios Documentation.md (Phase 12/13) describes
-- running by hand against a throwaway Postgres 16 container. This is the
-- single biggest architectural feature in the schema (RLS on 19 tables) and
-- previously had no committed, repeatable test at all.
--
-- IMPORTANT: real Postgres superusers bypass RLS/FORCE ROW LEVEL SECURITY
-- unconditionally, so these scenarios are meaningless run as a superuser
-- (e.g. Docker's default POSTGRES_USER, or Render's owner role). This script
-- creates a throwaway NON-superuser role and switches into it with
-- `SET ROLE` for the actual assertions — CREATE ROLE / GRANT / SET ROLE /
-- DROP ROLE are utility statements and can't run inside a PL/pgSQL DO block,
-- so setup/tear-down are plain top-level statements, with `\gset` used to
-- carry generated IDs between them and into the small DO blocks used only
-- for the pass/fail assertions.
-- Run: psql "$DATABASE_URL" -f 06_rls_isolation.sql

\echo '=== TEST 06: RLS isolation ==='

-- The whole script runs as one explicit transaction: CREATE ROLE / GRANT /
-- SET ROLE / DROP ROLE are all transactional in Postgres, so if anything
-- errors partway through (ON_ERROR_STOP disconnects psql), the aborted
-- transaction — and everything this script created — is discarded
-- automatically instead of leaving orphaned test data behind.
BEGIN;

-- ---------- SETUP (still the connecting superuser) ----------
SET app.is_super_admin = 'true';

INSERT INTO Branch (name,address,city,province,postal_code,email,phone,status)
VALUES ('ZZTEST RLS Branch1','1 Test Rd','Testville','TestProv','00000','zzrls1@test.com','000','Active')
RETURNING branch_id AS v_b1 \gset

INSERT INTO Branch (name,address,city,province,postal_code,email,phone,status)
VALUES ('ZZTEST RLS Branch2','2 Test Rd','Testville','TestProv','00000','zzrls2@test.com','000','Active')
RETURNING branch_id AS v_b2 \gset

INSERT INTO RoomType (type_name, base_price, capacity) VALUES ('ZZTEST-RLS-Std', 1000, 2)
RETURNING room_type_id AS v_rtype \gset

INSERT INTO Room (branch_id, room_number, floor, room_type_id) VALUES (:v_b1,'RLS1',1,:v_rtype)
RETURNING room_id AS v_room1 \gset

INSERT INTO Room (branch_id, room_number, floor, room_type_id) VALUES (:v_b2,'RLS1',1,:v_rtype)
RETURNING room_id AS v_room2 \gset

INSERT INTO Guest (first_name,last_name,date_of_birth,nationality,passport_number,email,address)
VALUES ('ZZTest','RLSGuest','1990-01-01','TH','ZZTESTRLS01','zzrlsguest@test.com','addr')
RETURNING guest_id AS v_guest \gset

INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests, status)
VALUES (:v_b1, :v_guest, '2026-11-01','2026-11-03',1,'Confirmed') RETURNING reservation_id AS v_res1 \gset

INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests, status)
VALUES (:v_b2, :v_guest, '2026-11-01','2026-11-03',1,'Confirmed') RETURNING reservation_id AS v_res2 \gset

INSERT INTO Invoice (reservation_id, payer_guest_id, sub_total, tax_amount, discount, total_amount)
VALUES (:v_res1, :v_guest, 100, 7, 0, 107) RETURNING invoice_id AS v_inv1 \gset

INSERT INTO Invoice (reservation_id, payer_guest_id, sub_total, tax_amount, discount, total_amount)
VALUES (:v_res2, :v_guest, 100, 7, 0, 107) RETURNING invoice_id AS v_inv2 \gset

INSERT INTO InvoiceItem (invoice_id, room_id, item_type, quantity, amount) VALUES (:v_inv1, :v_room1, 'Room', 1, 100);
INSERT INTO InvoiceItem (invoice_id, room_id, item_type, quantity, amount) VALUES (:v_inv2, :v_room2, 'Room', 1, 100);

-- psql does NOT perform :variable substitution inside $$ ... $$ bodies (by
-- design — PL/pgSQL code routinely contains literal colons unrelated to
-- psql variables). Stash the IDs the DO blocks below need into ordinary
-- session GUCs instead, readable via current_setting() from anywhere.
SELECT set_config('app.tmp_res2', :'v_res2', false);
SELECT set_config('app.tmp_inv1', :'v_inv1', false);

RESET app.is_super_admin;

-- ---------- create a throwaway non-superuser role to test through ----------
DROP ROLE IF EXISTS zztest_rls_role;
CREATE ROLE zztest_rls_role NOSUPERUSER NOLOGIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO zztest_rls_role;
-- Table-level INSERT doesn't imply sequence USAGE for SERIAL columns — the
-- audit triggers (log_reservation_audit, etc.) run as this role and need
-- nextval() on e.g. auditlog_log_id_seq to fire at all.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO zztest_rls_role;
SET ROLE zztest_rls_role;

-- ---------- 06-A: branch-1 staff sees only branch-1's room ----------
SELECT set_config('app.is_super_admin', 'false', false);
SELECT set_config('app.current_branch_id', :'v_b1', false);
SELECT set_config('app.current_guest_id', '', false);
DO $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM Room;
  IF v_count = 1 THEN RAISE NOTICE 'TEST 06-A: PASS — branch-1 staff sees exactly 1 room (their own)';
  ELSE RAISE NOTICE 'TEST 06-A: FAIL — expected 1 room, saw %', v_count; END IF;
END $$;

-- ---------- 06-B: a guest session sees all rooms (browsing to book) ----------
SELECT set_config('app.current_branch_id', '', false);
SELECT set_config('app.current_guest_id', :'v_guest', false);
DO $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM Room;
  IF v_count >= 2 THEN RAISE NOTICE 'TEST 06-B: PASS — guest session sees rooms across branches (%)', v_count;
  ELSE RAISE NOTICE 'TEST 06-B: FAIL — expected >=2 rooms, saw %', v_count; END IF;
END $$;

-- ---------- 06-C: super-admin sees everything ----------
SELECT set_config('app.is_super_admin', 'true', false);
SELECT set_config('app.current_branch_id', '', false);
SELECT set_config('app.current_guest_id', '', false);
DO $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM Room;
  IF v_count >= 2 THEN RAISE NOTICE 'TEST 06-C: PASS — super-admin sees all % rooms', v_count;
  ELSE RAISE NOTICE 'TEST 06-C: FAIL — expected >=2 rooms, saw %', v_count; END IF;
END $$;

-- ---------- 06-D: a non-admin cancel still writes an audit row ----------
-- The UPDATE itself must run as non-admin (to prove the trigger fires under
-- RLS restriction, not just for a bypassing session). Confirming the write
-- happened requires reading AuditLog back, which audit_log_read restricts
-- to is_super_admin() — so that one confirmation SELECT briefly flips to
-- admin, then flips back before TEST 06-E (which needs non-admin context).
SELECT set_config('app.is_super_admin', 'false', false);
SELECT set_config('app.current_branch_id', :'v_b2', false);
SELECT set_config('app.current_guest_id', '', false);
UPDATE Reservation SET status = 'Cancelled' WHERE reservation_id = :v_res2;
SELECT set_config('app.is_super_admin', 'true', false);
DO $$
DECLARE v_log INT;
BEGIN
  SELECT log_id INTO v_log FROM AuditLog
    WHERE table_name = 'Reservation' AND pk_of_table = current_setting('app.tmp_res2')
    ORDER BY log_id DESC LIMIT 1;
  IF v_log IS NOT NULL THEN RAISE NOTICE 'TEST 06-D: PASS — non-admin cancel wrote an audit row (log_id %)', v_log;
  ELSE RAISE NOTICE 'TEST 06-D: FAIL — no audit row written for the cancellation'; END IF;
END $$;
SELECT set_config('app.is_super_admin', 'false', false);

-- ---------- 06-E: that same non-admin session reads 0 AuditLog rows ----------
DO $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM AuditLog;
  IF v_count = 0 THEN RAISE NOTICE 'TEST 06-E: PASS — non-admin reads 0 AuditLog rows';
  ELSE RAISE NOTICE 'TEST 06-E: FAIL — non-admin saw % AuditLog rows', v_count; END IF;
END $$;

-- ---------- 06-F: an admin session CAN read that same row ----------
SELECT set_config('app.is_super_admin', 'true', false);
DO $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM AuditLog
    WHERE table_name = 'Reservation' AND pk_of_table = current_setting('app.tmp_res2');
  IF v_count >= 1 THEN RAISE NOTICE 'TEST 06-F: PASS — admin session reads the audit row(s)';
  ELSE RAISE NOTICE 'TEST 06-F: FAIL — admin session could not see the audit row'; END IF;
END $$;

-- ---------- 06-G: branch-2 staff cannot see branch-1's InvoiceItem ----------
SELECT set_config('app.is_super_admin', 'false', false);
SELECT set_config('app.current_branch_id', :'v_b2', false);
SELECT set_config('app.current_guest_id', '', false);
DO $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM InvoiceItem WHERE invoice_id = current_setting('app.tmp_inv1')::int;
  IF v_count = 0 THEN RAISE NOTICE 'TEST 06-G: PASS — branch-2 staff sees 0 rows of branch-1''s InvoiceItem';
  ELSE RAISE NOTICE 'TEST 06-G: FAIL — branch-2 staff saw % rows of branch-1''s InvoiceItem', v_count; END IF;
END $$;

-- ---------- 06-H: AuditLog is append-only even for this non-superuser role ----------
-- Look up a real log_id as admin (audit_log_read is admin-only), then flip
-- back to non-admin before attempting the tamper. Note: under FORCE ROW
-- LEVEL SECURITY, an UPDATE with no matching policy is silently filtered —
-- it affects 0 rows rather than raising an exception — so "no exception"
-- alone would NOT prove the tamper failed. The real check is re-reading the
-- row as admin afterward and confirming new_value is unchanged.
SELECT set_config('app.is_super_admin', 'true', false);
SELECT set_config('app.tmp_log_id', (SELECT log_id::text FROM AuditLog WHERE table_name = 'Reservation' AND pk_of_table = current_setting('app.tmp_res2') LIMIT 1), false);
SELECT set_config('app.is_super_admin', 'false', false);
DO $$
DECLARE v_log INT := current_setting('app.tmp_log_id')::int;
BEGIN
  BEGIN
    UPDATE AuditLog SET new_value = 'TAMPERED' WHERE log_id = v_log;
  EXCEPTION WHEN OTHERS THEN
    NULL; -- fall through to the definitive check below either way
  END;
END $$;
SELECT set_config('app.is_super_admin', 'true', false);
DO $$
DECLARE v_log INT := current_setting('app.tmp_log_id')::int; v_new_value TEXT;
BEGIN
  SELECT new_value INTO v_new_value FROM AuditLog WHERE log_id = v_log;
  IF v_new_value IS DISTINCT FROM 'TAMPERED' THEN
    RAISE NOTICE 'TEST 06-H: PASS — audit row unchanged after a non-superuser role attempted to tamper with it (new_value=%)', v_new_value;
  ELSE
    RAISE NOTICE 'TEST 06-H: FAIL — a non-superuser role was able to modify an audit row';
  END IF;
END $$;
SELECT set_config('app.is_super_admin', 'false', false);

-- ---------- CLEANUP (back to the real superuser) ----------
RESET ROLE;
SET app.is_super_admin = 'true';
DELETE FROM AuditLog WHERE table_name = 'Reservation' AND pk_of_table IN ((:v_res1)::text, (:v_res2)::text);
DELETE FROM InvoiceItem WHERE invoice_id IN (:v_inv1, :v_inv2);
DELETE FROM Invoice WHERE invoice_id IN (:v_inv1, :v_inv2);
DELETE FROM Reservation WHERE reservation_id IN (:v_res1, :v_res2);
DELETE FROM Room WHERE room_id IN (:v_room1, :v_room2);
DELETE FROM RoomType WHERE room_type_id = :v_rtype;
DELETE FROM Guest WHERE guest_id = :v_guest;
DELETE FROM Branch WHERE branch_id IN (:v_b1, :v_b2);
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM zztest_rls_role;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM zztest_rls_role;
DROP ROLE zztest_rls_role;
RESET app.is_super_admin;

COMMIT;

\echo '=== TEST 06 done ==='
