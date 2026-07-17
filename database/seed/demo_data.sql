-- =============================================================================
-- Starchitex — Demo/Testing Dataset
-- Layers on top of seed_data.sql (the minimal production bootstrap) to give
-- an instructor or reviewer a fully populated system to click through with
-- zero manual setup. NOT meant for a real production deploy — only
-- docker-compose.yml's local stack loads this file; a real deploy (Render,
-- etc.) applies schema.sql + seed_data.sql only, by hand, per README.md.
--
-- All dates below are relative to CURRENT_DATE so this stays valid no matter
-- when it's actually loaded. See README.md's "Testing Guide" for exactly
-- which reservation demonstrates which trigger/feature.
--
-- All logins here use the password 'demo1234' (same BCrypt hash as
-- seed_data.sql's admin.sys — see that file's header for why the cost
-- factor doesn't need to match the encoder's configured strength).
SET app.is_super_admin = 'true';
-- =============================================================================

BEGIN;

-- ---------- Second branch (demonstrates branch-level RLS isolation) ----------
INSERT INTO Branch (name, address, city, province, postal_code, email, phone, status) VALUES
 ('Starchitex Riverside','99 Charoen Krung Rd','Bangkok','Bangkok','10500','riverside@starchitex.com','+66-2-100-1001','Active');
-- branch_id 2 (Main Branch from seed_data.sql is 1)

-- ---------- Room types ----------
INSERT INTO RoomType (type_name, description, base_price, capacity) VALUES
 ('Standard','Standard double room',1500,2),
 ('Deluxe','Deluxe room with city view',2500,2),
 ('Suite','Suite with living area',4500,4);
-- room_type_id: 1=Standard, 2=Deluxe, 3=Suite

-- ---------- Rooms (4 in Main Branch, 3 in Riverside) ----------
INSERT INTO Room (room_number, floor, branch_id, room_type_id) VALUES
 ('101',1,1,1),  -- room_id 1, branch 1, Standard
 ('102',1,1,1),  -- room_id 2, branch 1, Standard
 ('201',2,1,2),  -- room_id 3, branch 1, Deluxe
 ('301',3,1,3),  -- room_id 4, branch 1, Suite
 ('101',1,2,1),  -- room_id 5, branch 2, Standard
 ('102',1,2,1),  -- room_id 6, branch 2, Standard
 ('201',2,2,2);  -- room_id 7, branch 2, Deluxe — left unreserved, see maintenance ticket below

-- ---------- Services ----------
INSERT INTO Service (service_name, category, price, description) VALUES
 ('Breakfast Buffet','Food',350,'All-you-can-eat breakfast buffet'),
 ('Airport Transfer','Transport',800,'One-way airport pickup/drop-off'),
 ('Spa Massage','Wellness',1200,'60-minute Thai massage');
-- service_id: 1=Breakfast, 2=Airport Transfer, 3=Spa

-- ---------- Facility ----------
INSERT INTO Facility (branch_id, facility_name, description, capacity, location) VALUES
 (1,'Rooftop Pool','Outdoor pool with skyline view',40,'Level 8');

-- ---------- Staff, one per role, spread across both branches ----------
INSERT INTO Employee (branch_id, first_name, last_name, position, gender, date_of_birth, phone, email, hire_date, salary, employment_status) VALUES
 (1,'Prapaporn','Srisuk','Hotel Owner','Female','1975-07-30','+66-81-111-0002','owner.hq@starchitex.com','2020-06-01',150000,'Active'),           -- employee_id 2
 (1,'Anan','Chaiyo','Sales Executive','Male','1985-11-02','+66-81-111-0003','sales.bkk@starchitex.com','2021-04-15',85000,'Active'),               -- 3
 (1,'Wanida','Boonmee','Branch Manager','Female','1982-02-18','+66-81-111-0004','manager.bkk@starchitex.com','2021-01-05',90000,'Active'),         -- 4
 (1,'Malee','Suksawat','Front Desk Receptionist','Female','1996-05-09','+66-81-111-0005','reception.bkk@starchitex.com','2023-03-01',32000,'Active'), -- 5
 (2,'Nattapong','Silpakorn','Housekeeping Staff','Male','1992-08-14','+66-81-111-0006','housekeeping.riv@starchitex.com','2022-07-11',26000,'Active'), -- 6
 (2,'Chai','Anantasin','Maintenance Technician','Male','1989-12-01','+66-81-111-0007','maintenance.riv@starchitex.com','2021-09-20',30000,'Active'),  -- 7
 (2,'Siriporn','Ngamwong','Finance Manager','Female','1984-04-23','+66-81-111-0008','finance.riv@starchitex.com','2020-11-02',75000,'Active');        -- 8

INSERT INTO EmployeeCredentials (employee_id, username, password_hash, role_id) VALUES
 (2,'owner.hq',        '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',2),
 (3,'sales.bkk',       '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',3),
 (4,'manager.bkk',     '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',4),
 (5,'reception.bkk',   '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',5),
 (6,'housekeeping.riv','$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',6),
 (7,'maintenance.riv', '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',7),
 (8,'finance.riv',     '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',8);

-- ---------- Guests (Demo Guest has a login; the other 3 don't, to leave
-- room for testing self-registration and the "book while logged in" flow) ----------
INSERT INTO Guest (first_name, last_name, gender, date_of_birth, nationality, passport_number, phone_number, email, address, created_at) VALUES
 ('Hannah','Miller','Female','1991-04-05','USA','US9412345','+1-202-555-0101','hannah.miller@example.com','12 Elm St, Boston',now() - interval '60 days'),   -- guest_id 1
 ('Kenji','Tanaka','Male','1985-09-21','Japan','JP7765432','+81-90-1234-5678','kenji.tanaka@example.jp','3-2-1 Shibuya, Tokyo',now() - interval '45 days'),  -- 2
 ('Li','Wei','Male','1993-12-11','China','CN5523891','+86-138-0000-1111','li.wei@example.cn','88 Nanjing Rd, Shanghai',now() - interval '30 days'),          -- 3
 ('Demo','Guest','Female','1995-07-07','Thailand','TH9988776','+66-89-999-0000','demo.guest@example.com','1 Demo Rd, Bangkok',now() - interval '10 days');   -- 4

INSERT INTO GuestCredentials (guest_id, username, password_hash, role_id) VALUES
 (4,'demo.guest','$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',10);

-- ---------- Reservations ----------
-- R1: Hannah, branch 1 room 101, a completed & fully-paid past stay — gives
-- Billing something real to look at immediately (no live action needed).
INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, actual_checkin_time, actual_checkout_time, num_of_guests, status)
VALUES (1, 1, CURRENT_DATE - 4, CURRENT_DATE - 1, (CURRENT_DATE - 4) + interval '15 hours', (CURRENT_DATE - 1) + interval '11 hours', 2, 'Checked Out');
INSERT INTO ReservationRoom (reservation_id, room_id) VALUES (1, 1);
INSERT INTO Invoice (reservation_id, payer_guest_id, sub_total, tax_amount, discount, total_amount, status) VALUES (1, 1, 0, 0, 0, 0, 'Unpaid');
INSERT INTO InvoiceItem (invoice_id, room_id, item_type, quantity, amount) VALUES (1, 1, 'Room', 3, 0); -- 3 nights x 1500 = 4500, tax 7% -> total 4815
INSERT INTO Payment (invoice_id, amount, payment_method, transaction_ref) VALUES (1, 4815.00, 'Credit Card', 'TXN-DEMO-0001');

-- R2: Kenji, branch 1 room 102, currently Checked In — check them out from
-- staff Reservations to watch the room flip to Dirty and a cleaning
-- RoomTask get auto-created, then complete that task on Housekeeping to
-- watch it flip back to Clean.
INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, actual_checkin_time, num_of_guests, status, special_requests)
VALUES (1, 2, CURRENT_DATE, CURRENT_DATE + 3, now(), 1, 'Checked In', 'Late checkout if possible');
INSERT INTO ReservationRoom (reservation_id, room_id) VALUES (2, 2);

-- R3: Li Wei, branch 1 room 201 (Deluxe), Confirmed, checking in TOMORROW —
-- already has an invoice and a Pending service request. Complete the
-- service request from staff Service Requests to watch it auto-post to
-- this invoice; or cancel the reservation from staff Reservations to watch
-- the 24h cancellation-fee trigger post a Fee line item automatically.
INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests, status)
VALUES (1, 3, CURRENT_DATE + 1, CURRENT_DATE + 3, 1, 'Confirmed');
INSERT INTO ReservationRoom (reservation_id, room_id) VALUES (3, 3);
INSERT INTO Invoice (reservation_id, payer_guest_id, sub_total, tax_amount, discount, total_amount, status) VALUES (3, 3, 0, 0, 0, 0, 'Unpaid');
INSERT INTO InvoiceItem (invoice_id, room_id, item_type, quantity, amount) VALUES (2, 3, 'Room', 2, 0); -- 2 nights x 2500 = 5000
INSERT INTO ServiceRequest (reservation_id, service_id, description, status) VALUES (3, 1, 'Breakfast for one, room service', 'Pending');

-- R4: Demo Guest, branch 1 room 301 (Suite), Pending, far in the future —
-- confirm it, or cancel it and confirm NO fee is added (contrast with R3).
INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests, status)
VALUES (1, 4, CURRENT_DATE + 10, CURRENT_DATE + 12, 2, 'Pending');
INSERT INTO ReservationRoom (reservation_id, room_id) VALUES (4, 4);

-- R5: Demo Guest, branch 2 room 101, Confirmed — log in as branch-1 staff
-- and confirm you CANNOT see this reservation (RLS), then as owner.hq
-- (cross-branch role) and confirm you CAN.
INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, num_of_guests, status)
VALUES (2, 4, CURRENT_DATE + 5, CURRENT_DATE + 7, 1, 'Confirmed');
INSERT INTO ReservationRoom (reservation_id, room_id) VALUES (5, 5);

-- ---------- Maintenance ticket left OPEN on branch 2 room 201 (unreserved)
-- so you can try to book it (as demo.guest, or via staff) and watch
-- trg_prevent_booking_maintenance_room reject it. ----------
INSERT INTO RoomMaintenance (room_id, reported_by, priority, description, status)
VALUES (7, 7, 'High', 'AC unit not cooling', 'Reported');

-- ---------- A standalone, unassigned housekeeping task, unrelated to any
-- checkout, so the Housekeeping task list isn't empty before you check
-- anyone out. ----------
INSERT INTO RoomTask (room_id, description, status)
VALUES (4, 'Deep clean before next guest', 'Pending');

COMMIT;
