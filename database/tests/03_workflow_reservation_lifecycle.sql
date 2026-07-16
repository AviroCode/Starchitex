
-- TEST 03: Full reservation lifecycle 
-- Author: Min Linn Khant (QA)
-- Run:  psql "$DATABASE_URL" -f 03_workflow_reservation_lifecycle.sql
-- Flow: reserve -> confirm -> check-in -> service charge ->
--       partial payment -> full payment -> check-out
-- (create_reservation, check_in, record_payment, check_out, ...).
-- Asserts state after every transition.


\echo '=== TEST 03: reservation lifecycle ==='

SET app.is_super_admin = 'true';

DO $$
DECLARE
  v_branch INT; v_rtype INT; v_room INT; v_guest INT; v_res INT;
  v_svc INT; v_req INT; v_inv INT;
  v_status TEXT; v_inv_status TEXT; v_paid NUMERIC;
BEGIN
  -- ---------- SETUP ----------
  INSERT INTO Branch (name,address,city,province,postal_code,email,phone)
  VALUES ('ZZTEST Branch03','1 Test Rd','Testville','TestProv','00000','zztest03@test.com','000')
  RETURNING branch_id INTO v_branch;
  INSERT INTO RoomType (type_name, base_price, capacity) VALUES ('ZZTEST-Std-03', 1500, 2)
  RETURNING room_type_id INTO v_rtype;
  INSERT INTO Room (branch_id, room_number, floor, room_type_id) VALUES (v_branch,'ZT301',3,v_rtype)
  RETURNING room_id INTO v_room;
  INSERT INTO Guest (first_name,last_name,date_of_birth,nationality,passport_number,email,address)
  VALUES ('ZZTest','Guest03','1990-01-01','TH','ZZTESTP03','zztestguest03@test.com','addr')
  RETURNING guest_id INTO v_guest;
  INSERT INTO Service (service_name, category, price) VALUES ('ZZTEST Room Service','Room Service',200)
  RETURNING service_id INTO v_svc;

  -- ---------- STEP 1: reserve (default status must be Pending) ----------
  INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests)
  VALUES (v_branch, v_guest,'2026-10-01','2026-10-03',2) RETURNING reservation_id INTO v_res;
  INSERT INTO ReservationRoom VALUES (v_res, v_room);

  SELECT status INTO v_status FROM Reservation WHERE reservation_id = v_res;
  IF v_status = 'Pending' THEN RAISE NOTICE 'TEST 03-1: PASS — new reservation is Pending';
  ELSE RAISE NOTICE 'TEST 03-1: FAIL — expected Pending, got %', v_status; END IF;

  -- ---------- STEP 2: confirm ----------
  UPDATE Reservation SET status='Confirmed' WHERE reservation_id = v_res;
  SELECT status INTO v_status FROM Reservation WHERE reservation_id = v_res;
  IF v_status = 'Confirmed' THEN RAISE NOTICE 'TEST 03-2: PASS — reservation Confirmed';
  ELSE RAISE NOTICE 'TEST 03-2: FAIL — got %', v_status; END IF;

  -- ---------- STEP 3: check-in ----------
  -- chk_reservation_times requires actual_checkin_time to fall within
  -- [check_in_date, check_out_date] — an explicit in-range timestamp is used
  -- instead of now(), since the reservation's dates are fixed far-future values.
  UPDATE Reservation SET status='Checked In', actual_checkin_time='2026-10-01 15:00' WHERE reservation_id = v_res;
  SELECT status INTO v_status FROM Reservation WHERE reservation_id = v_res;
  IF v_status = 'Checked In'
     AND (SELECT actual_checkin_time FROM Reservation WHERE reservation_id=v_res) IS NOT NULL
  THEN RAISE NOTICE 'TEST 03-3: PASS — checked in with timestamp';
  ELSE RAISE NOTICE 'TEST 03-3: FAIL'; END IF;

  -- ---------- STEP 4: service request during stay ----------
  INSERT INTO ServiceRequest (reservation_id, service_id, description)
  VALUES (v_res, v_svc, 'ZZTEST late-night snack') RETURNING request_id INTO v_req;
  UPDATE ServiceRequest SET status='Completed' WHERE request_id = v_req;
  IF (SELECT status FROM ServiceRequest WHERE request_id=v_req) = 'Completed'
  THEN RAISE NOTICE 'TEST 03-4: PASS — service request completed';
  ELSE RAISE NOTICE 'TEST 03-4: FAIL'; END IF;

  -- ---------- STEP 5: invoice (2 nights x room_type base_price 1500 + 1x
  -- service @ 200, 7%% tax) — amount is auto-filled by
  -- trg_enforce_invoice_item_price from RoomType.base_price / Service.price,
  -- and sub_total/tax/total are auto-recalculated by
  -- trg_recalculate_invoice_total_on_item_change once the items land, so the
  -- placeholder totals below get overwritten to the same numbers.
  -- ----------
  INSERT INTO Invoice (reservation_id, payer_guest_id, sub_total, tax_amount, discount, total_amount)
  VALUES (v_res, v_guest, 0, 0, 0, 0) RETURNING invoice_id INTO v_inv;
  INSERT INTO InvoiceItem (invoice_id, room_id, item_type, quantity, amount) VALUES
    (v_inv, v_room, 'Room', 2, 0);
  INSERT INTO InvoiceItem (invoice_id, service_id, item_type, quantity, amount) VALUES
    (v_inv, v_svc, 'Service', 1, 0);

  -- invoice items must sum to sub_total
  IF (SELECT SUM(amount) FROM InvoiceItem WHERE invoice_id=v_inv) = 3200
  THEN RAISE NOTICE 'TEST 03-5: PASS — invoice items sum to sub_total';
  ELSE RAISE NOTICE 'TEST 03-5: FAIL — items do not sum to sub_total (got %)', (SELECT SUM(amount) FROM InvoiceItem WHERE invoice_id=v_inv); END IF;

  -- ---------- STEP 6: partial payment ----------
  -- trg_update_invoice_status_on_payment recalculates Invoice.status
  -- automatically after each Payment insert/delete.
  INSERT INTO Payment (invoice_id, amount, payment_method) VALUES (v_inv, 1000, 'Cash');
  SELECT SUM(amount) INTO v_paid FROM Payment WHERE invoice_id = v_inv;
  IF v_paid = 1000 AND (SELECT status FROM Invoice WHERE invoice_id=v_inv)='Partially Paid'
  THEN RAISE NOTICE 'TEST 03-6: PASS — partial payment recorded (1000/3424)';
  ELSE RAISE NOTICE 'TEST 03-6: FAIL — paid % status %', v_paid, (SELECT status FROM Invoice WHERE invoice_id=v_inv); END IF;

  -- ---------- STEP 7: remaining payment; invoice fully paid ----------
  INSERT INTO Payment (invoice_id, amount, payment_method) VALUES (v_inv, 2424, 'Credit Card');
  SELECT SUM(amount) INTO v_paid FROM Payment WHERE invoice_id = v_inv;
  IF v_paid = (SELECT total_amount FROM Invoice WHERE invoice_id=v_inv)
     AND (SELECT status FROM Invoice WHERE invoice_id=v_inv)='Paid'
  THEN RAISE NOTICE 'TEST 03-7: PASS — payments equal total, invoice Paid';
  ELSE RAISE NOTICE 'TEST 03-7: FAIL — paid % vs total', v_paid; END IF;

  -- ---------- STEP 8: check-out ----------
  UPDATE Reservation SET status='Checked Out', actual_checkout_time='2026-10-03 11:00' WHERE reservation_id = v_res;
  IF (SELECT status FROM Reservation WHERE reservation_id=v_res)='Checked Out'
  THEN RAISE NOTICE 'TEST 03-8: PASS — checked out';
  ELSE RAISE NOTICE 'TEST 03-8: FAIL'; END IF;


  -- ---------- CLEANUP ----------
  DELETE FROM Payment WHERE invoice_id=v_inv;
  DELETE FROM InvoiceItem WHERE invoice_id=v_inv;
  DELETE FROM Invoice WHERE invoice_id=v_inv;
  DELETE FROM ServiceRequest WHERE request_id=v_req;
  DELETE FROM Service WHERE service_id=v_svc;
  DELETE FROM ReservationRoom WHERE reservation_id=v_res;
  -- trg_sync_room_availability populated RoomAvailability for this stay; it
  -- must go before Room, which the availability rows still reference.
  DELETE FROM RoomAvailability WHERE room_id=v_room;
  DELETE FROM Reservation WHERE reservation_id=v_res;
  DELETE FROM Room WHERE room_id=v_room;
  DELETE FROM RoomType WHERE room_type_id=v_rtype;
  DELETE FROM Guest WHERE guest_id=v_guest;
  DELETE FROM Branch WHERE branch_id=v_branch;
END $$;

\echo '=== TEST 03 done ==='
