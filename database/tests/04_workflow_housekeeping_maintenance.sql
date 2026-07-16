
-- TEST 04: Housekeeping & maintenance workflows
-- Author: Min Linn Khant (QA)
-- Run:  psql "$DATABASE_URL" -f 04_workflow_housekeeping_maintenance.sql


\echo '=== TEST 04: housekeeping & maintenance ==='

SET app.is_super_admin = 'true';

DO $$
DECLARE
  v_branch INT; v_rtype INT; v_room INT; v_emp INT; v_task INT; v_maint INT;
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

  -- ---------- 04-E..G: BLOCKED on schema decision ----------
  RAISE NOTICE 'TEST 04-E: SKIP — checkout sets room Dirty (needs room.housekeeping_status column)';
  RAISE NOTICE 'TEST 04-F: SKIP — completing task sets room Clean (needs room.housekeeping_status column)';
  RAISE NOTICE 'TEST 04-G: SKIP — check-in blocked when room Dirty (needs column + check_in function)';

  -- ---------- CLEANUP ----------
  DELETE FROM RoomAvailability WHERE room_id=v_room;
  DELETE FROM RoomMaintenance WHERE room_maintenance_id=v_maint;
  DELETE FROM RoomTask WHERE roomtask_id=v_task;
  DELETE FROM Employee WHERE employee_id=v_emp;
  DELETE FROM Room WHERE room_id=v_room;
  DELETE FROM RoomType WHERE room_type_id=v_rtype;
  DELETE FROM Branch WHERE branch_id=v_branch;
END $$;

\echo '=== TEST 04 done ==='
