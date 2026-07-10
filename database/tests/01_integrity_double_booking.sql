
-- TEST 01: Double-booking prevention
-- Author: Min Linn Khant (QA)
-- Expected final state: TEST reports PASS once the
-- double-booking prevention trigger is implemented.



\echo '=== TEST 01: double-booking prevention ==='


DO $$
DECLARE
  v_branch INT; v_rtype INT; v_room INT; v_guest INT;
  v_res1 INT; v_res2 INT;
  v_second_link_ok BOOLEAN := FALSE;
BEGIN
  INSERT INTO branch (name,address,city,province,postal_code,email,phone)
  VALUES ('ZZTEST Branch','1 Test Rd','Testville','TestProv','00000','zztest01@test.com','000')
  RETURNING branch_id INTO v_branch;

  INSERT INTO room_type (type_name, base_price, capacity)
  VALUES ('ZZTEST-Std-01', 1000, 2)
  RETURNING room_type_id INTO v_rtype;

  INSERT INTO room (branch_id, room_number, floor, room_type_id)
  VALUES (v_branch, 'ZT101', 1, v_rtype)
  RETURNING room_id INTO v_room;

  INSERT INTO guest (first_name,last_name,date_of_birth,nationality,passport_number,email,address)
  VALUES ('ZZTest','Guest01','1990-01-01','TH','ZZTESTP01','zztestguest01@test.com','test addr')
  RETURNING guest_id INTO v_guest;

  -- Reservation 1: Aug 1-5, gets the room
  INSERT INTO reservation (guest_id, check_in_date, check_out_date, num_of_guests, status)
  VALUES (v_guest, '2026-08-01', '2026-08-05', 1, 'Confirmed')
  RETURNING reservation_id INTO v_res1;
  INSERT INTO reservation_room VALUES (v_res1, v_room);

  -- Reservation 2: Aug 3-6 — OVERLAPS reservation 1 on the SAME room
  INSERT INTO reservation (guest_id, check_in_date, check_out_date, num_of_guests, status)
  VALUES (v_guest, '2026-08-03', '2026-08-06', 1, 'Confirmed')
  RETURNING reservation_id INTO v_res2;

  -- ---------- TEST 01-A: the overlapping link must be REJECTED ----------
  BEGIN
    INSERT INTO reservation_room VALUES (v_res2, v_room);
    v_second_link_ok := TRUE;   -- reached only if the insert succeeded
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'TEST 01-A: PASS — overlapping booking rejected (%).', SQLERRM;
  END;

  IF v_second_link_ok THEN
    RAISE NOTICE 'TEST 01-A: FAIL — overlapping booking for the same room was ACCEPTED. (KNOWN-FAIL until double-booking trigger is implemented.)';
  END IF;

  -- ---------- CLEANUP ----------
  DELETE FROM reservation_room WHERE reservation_id IN (v_res1, v_res2);
  DELETE FROM reservation WHERE reservation_id IN (v_res1, v_res2);
  DELETE FROM room WHERE room_id = v_room;
  DELETE FROM room_type WHERE room_type_id = v_rtype;
  DELETE FROM guest WHERE guest_id = v_guest;
  DELETE FROM branch WHERE branch_id = v_branch;
END $$;

\echo '=== TEST 01 done ==='
