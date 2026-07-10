
-- TEST 02: Data-integrity constraints (all expected-fail probes)
-- Author: Min Linn Khant (QA)
-- Run:  psql "$DATABASE_URL" -f 02_integrity_constraints.sql
-- Every sub-test attempts an INVALID insert; PASS = database rejects it.


\echo '=== TEST 02: integrity constraints ==='

DO $$
DECLARE
  v_branch INT; v_rtype INT; v_room INT; v_guest INT; v_res INT; v_inv INT;
  v_ok BOOLEAN;
BEGIN
  -- ---------- SETUP ----------
  INSERT INTO branch (name,address,city,province,postal_code,email,phone)
  VALUES ('ZZTEST Branch02','1 Test Rd','Testville','TestProv','00000','zztest02@test.com','000')
  RETURNING branch_id INTO v_branch;
  INSERT INTO room_type (type_name, base_price, capacity) VALUES ('ZZTEST-Std-02', 1000, 2)
  RETURNING room_type_id INTO v_rtype;
  INSERT INTO room (branch_id, room_number, floor, room_type_id) VALUES (v_branch,'ZT201',2,v_rtype)
  RETURNING room_id INTO v_room;
  INSERT INTO guest (first_name,last_name,date_of_birth,nationality,passport_number,email,address)
  VALUES ('ZZTest','Guest02','1990-01-01','TH','ZZTESTP02','zztestguest02@test.com','addr')
  RETURNING guest_id INTO v_guest;
  INSERT INTO reservation (guest_id, check_in_date, check_out_date, num_of_guests)
  VALUES (v_guest,'2026-09-01','2026-09-03',1) RETURNING reservation_id INTO v_res;
  INSERT INTO invoice (reservation_id, payer_guest_id, sub_total, tax_amount, discount, total_amount)
  VALUES (v_res, v_guest, 100, 7, 0, 107) RETURNING invoice_id INTO v_inv;

  -- ---------- 02-A: check_out_date <= check_in_date ----------
  v_ok := FALSE;
  BEGIN
    INSERT INTO reservation (guest_id, check_in_date, check_out_date, num_of_guests)
    VALUES (v_guest,'2026-09-05','2026-09-05',1);
    v_ok := TRUE;
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'TEST 02-A: PASS — checkout<=checkin rejected';
  END;
  IF v_ok THEN RAISE NOTICE 'TEST 02-A: FAIL — same-day checkout accepted'; END IF;

  -- ---------- 02-B: num_of_guests = 0 ----------
  v_ok := FALSE;
  BEGIN
    INSERT INTO reservation (guest_id, check_in_date, check_out_date, num_of_guests)
    VALUES (v_guest,'2026-09-05','2026-09-06',0);
    v_ok := TRUE;
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'TEST 02-B: PASS — zero guests rejected';
  END;
  IF v_ok THEN RAISE NOTICE 'TEST 02-B: FAIL — zero guests accepted'; END IF;

  -- ---------- 02-C: invoice math must balance ----------
  v_ok := FALSE;
  BEGIN
    INSERT INTO invoice (reservation_id, payer_guest_id, sub_total, tax_amount, discount, total_amount)
    VALUES (v_res, v_guest, 100, 7, 0, 999);
    v_ok := TRUE;
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'TEST 02-C: PASS — unbalanced invoice rejected';
  END;
  IF v_ok THEN RAISE NOTICE 'TEST 02-C: FAIL — total != sub+tax-discount accepted'; END IF;

  -- ---------- 02-D: negative payment amount ----------
  v_ok := FALSE;
  BEGIN
    INSERT INTO payment (invoice_id, amount, payment_method) VALUES (v_inv, -50, 'Cash');
    v_ok := TRUE;
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'TEST 02-D: PASS — negative payment rejected';
  END;
  IF v_ok THEN RAISE NOTICE 'TEST 02-D: FAIL — negative payment accepted'; END IF;

  -- ---------- 02-E: invalid payment method ----------
  v_ok := FALSE;
  BEGIN
    INSERT INTO payment (invoice_id, amount, payment_method) VALUES (v_inv, 10, 'Bitcoin');
    v_ok := TRUE;
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'TEST 02-E: PASS — invalid payment method rejected';
  END;
  IF v_ok THEN RAISE NOTICE 'TEST 02-E: FAIL — invalid payment method accepted'; END IF;

  -- ---------- 02-F: duplicate room_number in the same branch ----------
  v_ok := FALSE;
  BEGIN
    INSERT INTO room (branch_id, room_number, floor, room_type_id) VALUES (v_branch,'ZT201',3,v_rtype);
    v_ok := TRUE;
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'TEST 02-F: PASS — duplicate room number per branch rejected';
  END;
  IF v_ok THEN RAISE NOTICE 'TEST 02-F: FAIL — duplicate room number accepted'; END IF;

  -- ---------- 02-G: duplicate room_availability (room+date) ----------
  v_ok := FALSE;
  INSERT INTO room_availability (room_id, calendar_date, status) VALUES (v_room,'2026-09-01','Available');
  BEGIN
    INSERT INTO room_availability (room_id, calendar_date, status) VALUES (v_room,'2026-09-01','Reserved');
    v_ok := TRUE;
  EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'TEST 02-G: PASS — duplicate availability row rejected';
  END;
  IF v_ok THEN RAISE NOTICE 'TEST 02-G: FAIL — duplicate room+date accepted'; END IF;

  -- ---------- 02-H: facility booking end before start ----------
  v_ok := FALSE;
  DECLARE v_fac INT;
  BEGIN
    INSERT INTO facility (branch_id, facility_name, capacity, location)
    VALUES (v_branch,'ZZTEST Pool',10,'L1') RETURNING facility_id INTO v_fac;
    BEGIN
      INSERT INTO facility_booking (reservation_id, facility_id, start_time, end_time)
      VALUES (v_res, v_fac, '2026-09-01 15:00', '2026-09-01 14:00');
      v_ok := TRUE;
    EXCEPTION WHEN check_violation THEN
      RAISE NOTICE 'TEST 02-H: PASS — end-before-start facility booking rejected';
    END;
    IF v_ok THEN RAISE NOTICE 'TEST 02-H: FAIL — invalid time range accepted'; END IF;
    DELETE FROM facility WHERE facility_id = v_fac;
  END;

  -- ---------- CLEANUP ----------
  DELETE FROM room_availability WHERE room_id = v_room;
  DELETE FROM payment WHERE invoice_id = v_inv;
  DELETE FROM invoice WHERE invoice_id = v_inv;
  DELETE FROM reservation WHERE reservation_id = v_res;
  DELETE FROM room WHERE room_id = v_room;
  DELETE FROM room_type WHERE room_type_id = v_rtype;
  DELETE FROM guest WHERE guest_id = v_guest;
  DELETE FROM branch WHERE branch_id = v_branch;
END $$;

\echo '=== TEST 02 done ==='
