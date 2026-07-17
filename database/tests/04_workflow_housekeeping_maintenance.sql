
-- TEST 04: Housekeeping & maintenance workflows
-- Author: Min Linn Khant (QA)
-- Run:  psql "$DATABASE_URL" -f 04_workflow_housekeeping_maintenance.sql


\echo '=== TEST 04: housekeeping & maintenance ==='

SET app.is_super_admin = 'true';

DO $$
DECLARE
  v_branch INT; v_rtype INT; v_room INT; v_emp INT; v_task INT; v_maint INT;
  v_maint_open INT; v_guest INT; v_res_blocked INT; v_res INT; v_auto_task INT;
  v_ok BOOLEAN;
BEGIN
  -- ---------- SETUP ----------
  INSERT INTO Branch (name,address,city,province,postal_code,email,phone)
  VALUES ('ZZTEST Branch04','1 Test Rd','Testville','TestProv','00000','zztest04@test.com','000')
  RETURNING branch_id INTO v_branch;
  INSERT INTO RoomType (type_name, base_price, capacity) VALUES ('ZZTEST-Std-04', 1000, 2)
  RETURNING room_type_id INTO v_rtype;
  INSERT INTO Room (branch_id, room_number, floor, room_type_id) VALUES (v_branch,'ZT401',4,v_rtype)
  RETURNING room_id INTO v_room;
  INSERT INTO Employee (branch_id, first_name, last_name, position, date_of_birth, email, hire_date)
  VALUES (v_branch,'ZZTest','Housekeeper','Housekeeping','1995-05-05','zztesthk04@test.com','2025-01-01')
  RETURNING employee_id INTO v_emp;
  INSERT INTO Guest (first_name,last_name,date_of_birth,nationality,passport_number,email,address)
  VALUES ('ZZTest','Guest04','1990-01-01','TH','ZZTESTP04','zztestguest04@test.com','addr')
  RETURNING guest_id INTO v_guest;

  -- room starts life Clean (Room.housekeeping_status default)
  IF (SELECT housekeeping_status FROM Room WHERE room_id=v_room)='Clean'
  THEN RAISE NOTICE 'TEST 04-SETUP: PASS — new room defaults to Clean';
  ELSE RAISE NOTICE 'TEST 04-SETUP: FAIL'; END IF;

  -- ---------- 04-A: housekeeping task lifecycle ----------
  INSERT INTO RoomTask (room_id, assigned_employee_id, description)
  VALUES (v_room, v_emp, 'ZZTEST clean after checkout') RETURNING roomtask_id INTO v_task;

  IF (SELECT status FROM RoomTask WHERE roomtask_id=v_task)='Pending'
  THEN RAISE NOTICE 'TEST 04-A1: PASS — new task is Pending';
  ELSE RAISE NOTICE 'TEST 04-A1: FAIL'; END IF;

  UPDATE RoomTask SET status='Completed', completed_time=now() WHERE roomtask_id=v_task;
  IF (SELECT status FROM RoomTask WHERE roomtask_id=v_task)='Completed'
     AND (SELECT completed_time FROM RoomTask WHERE roomtask_id=v_task) IS NOT NULL
  THEN RAISE NOTICE 'TEST 04-A2: PASS — task completed with timestamp';
  ELSE RAISE NOTICE 'TEST 04-A2: FAIL'; END IF;

  -- ---------- 04-B: completed_time cannot precede assigned_time ----------
  v_ok := FALSE;
  BEGIN
    UPDATE RoomTask SET completed_time = assigned_time - interval '1 hour' WHERE roomtask_id=v_task;
    v_ok := TRUE;
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'TEST 04-B: PASS — completion before assignment rejected';
  END;
  IF v_ok THEN RAISE NOTICE 'TEST 04-B: FAIL — impossible completion time accepted'; END IF;

  -- ---------- 04-C: maintenance request lifecycle ----------
  INSERT INTO RoomMaintenance (room_id, reported_by, priority, description)
  VALUES (v_room, v_emp, 'High', 'ZZTEST broken AC') RETURNING room_maintenance_id INTO v_maint;
  UPDATE RoomMaintenance SET assigned_employee_id=v_emp, status='In Progress' WHERE room_maintenance_id=v_maint;
  UPDATE RoomMaintenance SET status='Completed', completion_date=CURRENT_DATE WHERE room_maintenance_id=v_maint;
  IF (SELECT status FROM RoomMaintenance WHERE room_maintenance_id=v_maint)='Completed'
  THEN RAISE NOTICE 'TEST 04-C: PASS — maintenance reported -> assigned -> completed';
  ELSE RAISE NOTICE 'TEST 04-C: FAIL'; END IF;

  -- ---------- 04-D: 'Maintenance' blocks the calendar ----------
  -- backend/schema.sql's chk_room_availability_status enum is
  -- ('Available','Occupied','Maintenance') — using the actual enum member.
  BEGIN
    INSERT INTO RoomAvailability (room_id, calendar_date, status)
    VALUES (v_room, '2026-10-10', 'Maintenance');
    IF (SELECT status FROM RoomAvailability WHERE room_id=v_room AND calendar_date='2026-10-10')='Maintenance'
    THEN RAISE NOTICE 'TEST 04-D: PASS — calendar date marked Maintenance';
    END IF;
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'TEST 04-D: FAIL — schema rejects the ''Maintenance'' status value';
  END;

  -- ---------- 04-E: an OPEN maintenance ticket blocks booking the room ----------
  -- trg_prevent_booking_maintenance_room (BEFORE INSERT/UPDATE ON
  -- ReservationRoom) rejects the link while any RoomMaintenance row for the
  -- room has status != 'Completed'.
  INSERT INTO RoomMaintenance (room_id, reported_by, priority, description)
  VALUES (v_room, v_emp, 'High', 'ZZTEST open ticket blocks booking') RETURNING room_maintenance_id INTO v_maint_open;

  INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests)
  VALUES (v_branch, v_guest, '2026-11-01', '2026-11-03', 2) RETURNING reservation_id INTO v_res_blocked;

  v_ok := FALSE;
  BEGIN
    INSERT INTO ReservationRoom VALUES (v_res_blocked, v_room);
    v_ok := TRUE;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'TEST 04-E: PASS — booking a room with an open maintenance ticket rejected (%).', SQLERRM;
  END;
  IF v_ok THEN RAISE NOTICE 'TEST 04-E: FAIL — room with an open maintenance ticket was booked'; END IF;

  -- close the ticket so the room is bookable again for 04-F below
  UPDATE RoomMaintenance SET status='Completed', completion_date=CURRENT_DATE WHERE room_maintenance_id=v_maint_open;

  -- ---------- 04-F: check-out marks the room Dirty and queues a cleaning task ----------
  -- trg_mark_room_dirty_on_checkout (AFTER UPDATE ON Reservation, when status
  -- transitions to 'Checked Out') sets Room.housekeeping_status='Dirty' and
  -- inserts a Pending RoomTask for every room on that reservation.
  INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests)
  VALUES (v_branch, v_guest, '2026-12-01', '2026-12-03', 2) RETURNING reservation_id INTO v_res;
  INSERT INTO ReservationRoom VALUES (v_res, v_room);

  -- enforce_reservation_state_machine only allows Pending -> Confirmed ->
  -- Checked In -> Checked Out, one step at a time.
  UPDATE Reservation SET status='Confirmed' WHERE reservation_id=v_res;
  UPDATE Reservation SET status='Checked In', actual_checkin_time='2026-12-01 15:00' WHERE reservation_id=v_res;
  UPDATE Reservation SET status='Checked Out', actual_checkout_time='2026-12-03 11:00' WHERE reservation_id=v_res;

  IF (SELECT housekeeping_status FROM Room WHERE room_id=v_room)='Dirty'
  THEN RAISE NOTICE 'TEST 04-F1: PASS — room marked Dirty on check-out';
  ELSE RAISE NOTICE 'TEST 04-F1: FAIL'; END IF;

  SELECT roomtask_id INTO v_auto_task FROM RoomTask
  WHERE room_id=v_room AND description='Post-checkout cleaning' AND status='Pending'
  ORDER BY roomtask_id DESC LIMIT 1;
  IF v_auto_task IS NOT NULL
  THEN RAISE NOTICE 'TEST 04-F2: PASS — post-checkout cleaning task auto-created';
  ELSE RAISE NOTICE 'TEST 04-F2: FAIL — no auto-created cleaning task found'; END IF;

  -- ---------- 04-G: completing the cleaning task marks the room Clean ----------
  -- trg_mark_room_clean_on_task_complete (AFTER UPDATE ON RoomTask, when
  -- status transitions to 'Completed') sets that room back to Clean.
  UPDATE RoomTask SET status='Completed', completed_time=now() WHERE roomtask_id=v_auto_task;
  IF (SELECT housekeeping_status FROM Room WHERE room_id=v_room)='Clean'
  THEN RAISE NOTICE 'TEST 04-G: PASS — room marked Clean once cleaning task completed';
  ELSE RAISE NOTICE 'TEST 04-G: FAIL'; END IF;

  -- ---------- 04-H: check-in blocked when room is Dirty ----------
  -- Deliberate v1 scope boundary (see plan): housekeeping_status governs
  -- display/reporting only and is not wired into check-in enforcement —
  -- front-desk staff still make the final call. Not a missing column/
  -- function anymore, so this is a documented decision, not a blocker.
  RAISE NOTICE 'TEST 04-H: SKIP — check-in is not blocked on a Dirty room by design (v1 scope decision, see plan)';

  -- ---------- CLEANUP ----------
  DELETE FROM RoomTask WHERE room_id=v_room;
  DELETE FROM ReservationRoom WHERE reservation_id IN (v_res_blocked, v_res);
  -- trg_sync_room_availability populated RoomAvailability for these stays;
  -- it must go before Room, which the availability rows still reference.
  DELETE FROM RoomAvailability WHERE room_id=v_room;
  DELETE FROM Reservation WHERE reservation_id IN (v_res_blocked, v_res);
  DELETE FROM RoomMaintenance WHERE room_id=v_room;
  DELETE FROM Guest WHERE guest_id=v_guest;
  DELETE FROM Employee WHERE employee_id=v_emp;
  DELETE FROM Room WHERE room_id=v_room;
  DELETE FROM RoomType WHERE room_type_id=v_rtype;
  DELETE FROM Branch WHERE branch_id=v_branch;
END $$;

\echo '=== TEST 04 done ==='
