
-- TEST 01: Double-booking prevention
-- Author: Min Linn Khant (QA)
-- Expected final state: TEST reports PASS once the
-- double-booking prevention trigger is implemented.



\echo '=== TEST 01: double-booking prevention ==='

-- Required under FORCE ROW LEVEL SECURITY for a plain psql session with no
-- branch/guest context set (see database/seed/seed_data.sql header).
SET app.is_super_admin = 'true';

DO $$
DECLARE
  v_branch INT; v_rtype INT; v_room INT; v_guest INT;
  v_res1 INT; v_res2 INT;
  v_second_link_ok BOOLEAN := FALSE;
BEGIN
  INSERT INTO Branch (name,address,city,province,postal_code,email,phone)
  VALUES ('ZZTEST Branch','1 Test Rd','Testville','TestProv','00000','zztest01@test.com','000')
  RETURNING branch_id INTO v_branch;

  INSERT INTO RoomType (type_name, base_price, capacity)
  VALUES ('ZZTEST-Std-01', 1000, 2)
  RETURNING room_type_id INTO v_rtype;

  INSERT INTO Room (branch_id, room_number, floor, room_type_id)
  VALUES (v_branch, 'ZT101', 1, v_rtype)
  RETURNING room_id INTO v_room;

  INSERT INTO Guest (first_name,last_name,date_of_birth,nationality,passport_number,email,address)
  VALUES ('ZZTest','Guest01','1990-01-01','TH','ZZTESTP01','zztestguest01@test.com','test addr')
  RETURNING guest_id INTO v_guest;

  -- Reservation 1: Aug 1-5, gets the room
  INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests, status)
  VALUES (v_branch, v_guest, '2026-08-01', '2026-08-05', 1, 'Confirmed')
  RETURNING reservation_id INTO v_res1;
  INSERT INTO ReservationRoom VALUES (v_res1, v_room);

  -- Reservation 2: Aug 3-6 — OVERLAPS reservation 1 on the SAME room
  INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests, status)
  VALUES (v_branch, v_guest, '2026-08-03', '2026-08-06', 1, 'Confirmed')
  RETURNING reservation_id INTO v_res2;

  -- ---------- TEST 01-A: the overlapping link must be REJECTED ----------
  BEGIN
    INSERT INTO ReservationRoom VALUES (v_res2, v_room);
    v_second_link_ok := TRUE;   -- reached only if the insert succeeded
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'TEST 01-A: PASS — overlapping booking rejected (%).', SQLERRM;
  END;

  IF v_second_link_ok THEN
    RAISE NOTICE 'TEST 01-A: FAIL — overlapping booking for the same room was ACCEPTED.';
  END IF;

  -- ---------- CLEANUP ----------
  DELETE FROM ReservationRoom WHERE reservation_id IN (v_res1, v_res2);
  -- trg_sync_room_availability populated RoomAvailability for v_res1's stay;
  -- it must go before Room, which the availability rows still reference.
  DELETE FROM RoomAvailability WHERE room_id = v_room;
  DELETE FROM Reservation WHERE reservation_id IN (v_res1, v_res2);
  DELETE FROM Room WHERE room_id = v_room;
  DELETE FROM RoomType WHERE room_type_id = v_rtype;
  DELETE FROM Guest WHERE guest_id = v_guest;
  DELETE FROM Branch WHERE branch_id = v_branch;
END $$;

\echo '=== TEST 01 done ==='
