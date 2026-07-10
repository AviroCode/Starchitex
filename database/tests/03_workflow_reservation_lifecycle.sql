
-- TEST 03: Full reservation lifecycle 
-- Author: Min Linn Khant (QA)
-- Run:  psql "$DATABASE_URL" -f 03_workflow_reservation_lifecycle.sql
-- Flow: reserve -> confirm -> check-in -> service charge ->
--       partial payment -> full payment -> check-out
-- (create_reservation, check_in, record_payment, check_out, ...).
-- Asserts state after every transition.


\echo '=== TEST 03: reservation lifecycle ==='

DO $$
DECLARE
  v_branch INT; v_rtype INT; v_room INT; v_guest INT; v_res INT;
  v_svc INT; v_req INT; v_inv INT;
  v_status TEXT; v_inv_status TEXT; v_paid NUMERIC;
BEGIN
  -- ---------- SETUP ----------
  INSERT INTO branch (name,address,city,province,postal_code,email,phone)
  VALUES ('ZZTEST Branch03','1 Test Rd','Testville','TestProv','00000','zztest03@test.com','000')
  RETURNING branch_id INTO v_branch;
  INSERT INTO room_type (type_name, base_price, capacity) VALUES ('ZZTEST-Std-03', 1500, 2)
  RETURNING room_type_id INTO v_rtype;
  INSERT INTO room (branch_id, room_number, floor, room_type_id) VALUES (v_branch,'ZT301',3,v_rtype)
  RETURNING room_id INTO v_room;
  INSERT INTO guest (first_name,last_name,date_of_birth,nationality,passport_number,email,address)
  VALUES ('ZZTest','Guest03','1990-01-01','TH','ZZTESTP03','zztestguest03@test.com','addr')
  RETURNING guest_id INTO v_guest;
  INSERT INTO service (service_name, category, price) VALUES ('ZZTEST Room Service','Room Service',200)
  RETURNING service_id INTO v_svc;

  -- ---------- STEP 1: reserve (default status must be Pending) ----------
  -- TODO replace with: SELECT create_reservation(...)
  INSERT INTO reservation (guest_id, check_in_date, check_out_date, num_of_guests)
  VALUES (v_guest,'2026-10-01','2026-10-03',2) RETURNING reservation_id INTO v_res;
  INSERT INTO reservation_room VALUES (v_res, v_room);

  SELECT status INTO v_status FROM reservation WHERE reservation_id = v_res;
  IF v_status = 'Pending' THEN RAISE NOTICE 'TEST 03-1: PASS — new reservation is Pending';
  ELSE RAISE NOTICE 'TEST 03-1: FAIL — expected Pending, got %', v_status; END IF;

  -- ---------- STEP 2: confirm ----------
  UPDATE reservation SET status='Confirmed' WHERE reservation_id = v_res;
  SELECT status INTO v_status FROM reservation WHERE reservation_id = v_res;
  IF v_status = 'Confirmed' THEN RAISE NOTICE 'TEST 03-2: PASS — reservation Confirmed';
  ELSE RAISE NOTICE 'TEST 03-2: FAIL — got %', v_status; END IF;

  -- ---------- STEP 3: check-in ----------
  -- TODO replace with: SELECT check_in(v_res, <employee>)
  UPDATE reservation SET status='Checked In', actual_checkin_time=now() WHERE reservation_id = v_res;
  SELECT status INTO v_status FROM reservation WHERE reservation_id = v_res;
  IF v_status = 'Checked In'
     AND (SELECT actual_checkin_time FROM reservation WHERE reservation_id=v_res) IS NOT NULL
  THEN RAISE NOTICE 'TEST 03-3: PASS — checked in with timestamp';
  ELSE RAISE NOTICE 'TEST 03-3: FAIL'; END IF;

  -- ---------- STEP 4: service request during stay ----------
  INSERT INTO service_request (reservation_id, service_id, description)
  VALUES (v_res, v_svc, 'ZZTEST late-night snack') RETURNING request_id INTO v_req;
  UPDATE service_request SET status='Completed' WHERE request_id = v_req;
  IF (SELECT status FROM service_request WHERE request_id=v_req) = 'Completed'
  THEN RAISE NOTICE 'TEST 03-4: PASS — service request completed';
  ELSE RAISE NOTICE 'TEST 03-4: FAIL'; END IF;

  -- ---------- STEP 5: invoice (2 nights x 1500 + 200 service, 7%% tax) ----------
  -- TODO replace with: SELECT generate_invoice(v_res)
  INSERT INTO invoice (reservation_id, payer_guest_id, sub_total, tax_amount, discount, total_amount)
  VALUES (v_res, v_guest, 3200, 224, 0, 3424) RETURNING invoice_id INTO v_inv;
  INSERT INTO invoice_item (invoice_id, item_type, quantity, amount) VALUES
    (v_inv, 'Room Charge', 2, 3000),
    (v_inv, 'Room Service', 1, 200);

  -- invoice items must sum to sub_total
  IF (SELECT SUM(amount) FROM invoice_item WHERE invoice_id=v_inv) = 3200
  THEN RAISE NOTICE 'TEST 03-5: PASS — invoice items sum to sub_total';
  ELSE RAISE NOTICE 'TEST 03-5: FAIL — items do not sum to sub_total'; END IF;

  -- ---------- STEP 6: partial payment ----------
  -- TODO replace with: SELECT record_payment(v_inv, 1000, 'Cash')
  INSERT INTO payment (invoice_id, amount, payment_method) VALUES (v_inv, 1000, 'Cash');
  UPDATE invoice SET status='Partially Paid' WHERE invoice_id = v_inv;
  SELECT SUM(amount) INTO v_paid FROM payment WHERE invoice_id = v_inv;
  IF v_paid = 1000 AND (SELECT status FROM invoice WHERE invoice_id=v_inv)='Partially Paid'
  THEN RAISE NOTICE 'TEST 03-6: PASS — partial payment recorded (1000/3424)';
  ELSE RAISE NOTICE 'TEST 03-6: FAIL'; END IF;

  -- ---------- STEP 7: remaining payment; invoice fully paid ----------
  INSERT INTO payment (invoice_id, amount, payment_method) VALUES (v_inv, 2424, 'Credit Card');
  UPDATE invoice SET status='Paid' WHERE invoice_id = v_inv;
  SELECT SUM(amount) INTO v_paid FROM payment WHERE invoice_id = v_inv;
  IF v_paid = (SELECT total_amount FROM invoice WHERE invoice_id=v_inv)
     AND (SELECT status FROM invoice WHERE invoice_id=v_inv)='Paid'
  THEN RAISE NOTICE 'TEST 03-7: PASS — payments equal total, invoice Paid';
  ELSE RAISE NOTICE 'TEST 03-7: FAIL — paid % vs total', v_paid; END IF;

  -- ---------- STEP 8: check-out ----------
  -- TODO replace with: SELECT check_out(v_res, <employee>)
  UPDATE reservation SET status='Checked Out', actual_checkout_time=now() WHERE reservation_id = v_res;
  IF (SELECT status FROM reservation WHERE reservation_id=v_res)='Checked Out'
  THEN RAISE NOTICE 'TEST 03-8: PASS — checked out';
  ELSE RAISE NOTICE 'TEST 03-8: FAIL'; END IF;


  -- ---------- CLEANUP ----------
  DELETE FROM payment WHERE invoice_id=v_inv;
  DELETE FROM invoice_item WHERE invoice_id=v_inv;
  DELETE FROM invoice WHERE invoice_id=v_inv;
  DELETE FROM service_request WHERE request_id=v_req;
  DELETE FROM service WHERE service_id=v_svc;
  DELETE FROM reservation_room WHERE reservation_id=v_res;
  DELETE FROM reservation WHERE reservation_id=v_res;
  DELETE FROM room WHERE room_id=v_room;
  DELETE FROM room_type WHERE room_type_id=v_rtype;
  DELETE FROM guest WHERE guest_id=v_guest;
  DELETE FROM branch WHERE branch_id=v_branch;
END $$;

\echo '=== TEST 03 done ==='
