-- =============================================================================
-- Starchitex Hotel Management System — Canonical Seed Data
-- Targets backend/src/main/resources/schema.sql (the RLS-enabled schema).
-- Role names here MUST exactly match the strings in @PreAuthorize annotations.
--
-- schema.sql enables Row-Level Security (with FORCE) on every tenant-scoped
-- table (Branch, Employee, Room, Facility, RoomAvailability, Reservation,
-- Guest, Invoice, Payment, etc.). A plain `psql -f` session has no branch or
-- guest context set, so without the line below any INSERT into one of those
-- tables is rejected with "new row violates row-level security policy" --
-- this applies to every seed/data-loading script, not just this file.
-- (Superuser sessions, e.g. Docker's docker-entrypoint-initdb.d, bypass RLS
-- entirely, but this is still required for a plain `psql -f` run against a
-- managed provider like Render, where the app role is not a superuser.)
SET app.is_super_admin = 'true';

-- All seeded logins use the password 'demo1234' (bcrypt, verified against
-- Spring Security's BCryptPasswordEncoder — the cost factor in the hash
-- doesn't need to match the encoder's configured strength; matches() reads
-- the cost from the hash itself).
-- =============================================================================

BEGIN;

-- ---------- Roles (10 canonical roles) ----------
INSERT INTO Role (role_id, role_name, description) VALUES
    (1,  'System Administrator',   'Full system access across all branches'),
    (2,  'Hotel Owner',            'Strategic oversight; cross-branch read/write'),
    (3,  'Sales Executive',        'Cross-branch reservations and guest management'),
    (4,  'Branch Manager',         'Full management of own branch'),
    (5,  'Front Desk Receptionist','Check-in/out, room assignment, guest lookup at own branch'),
    (6,  'Housekeeping Staff',     'Room tasks and maintenance at own branch'),
    (7,  'Maintenance Technician', 'Facility and room maintenance at own branch'),
    (8,  'Finance Manager',        'Invoice and payment management at own branch'),
    (9,  'HR Manager',             'Employee management at own branch'),
    (10, 'Guest',                  'Self-service: view own reservations and invoices')
ON CONFLICT (role_id) DO NOTHING;

-- ---------- Permissions ----------
INSERT INTO Permission (permission_id, permission_name, description) VALUES
    (1,  'VIEW_ALL_BRANCHES',   'Read data from any branch'),
    (2,  'MANAGE_EMPLOYEES',    'Create and update employee records'),
    (3,  'MANAGE_ROOMS',        'Create and update room records'),
    (4,  'MANAGE_RESERVATIONS', 'Create, confirm, check-in, check-out reservations'),
    (5,  'VIEW_INVOICES',       'Read invoice records'),
    (6,  'MANAGE_INVOICES',     'Create invoice items and process payments'),
    (7,  'VIEW_GUESTS',         'Read guest profile data'),
    (8,  'MANAGE_GUESTS',       'Create and update guest profiles'),
    (9,  'VIEW_OWN_RESERVATION','Guest self-service: read own reservations'),
    (10, 'VIEW_AUDIT_LOGS',     'Read audit log entries'),
    (11, 'MANAGE_TASKS',        'Create and update room/facility tasks')
ON CONFLICT (permission_id) DO NOTHING;

-- ---------- RolePermission mappings ----------
INSERT INTO RolePermission (role_id, permission_id) SELECT 1, permission_id FROM Permission ON CONFLICT DO NOTHING;
INSERT INTO RolePermission (role_id, permission_id) VALUES (2,1),(2,2),(2,3),(2,4),(2,5),(2,6),(2,7),(2,8),(2,10) ON CONFLICT DO NOTHING;
INSERT INTO RolePermission (role_id, permission_id) VALUES (3,1),(3,4),(3,5),(3,7),(3,8) ON CONFLICT DO NOTHING;
INSERT INTO RolePermission (role_id, permission_id) VALUES (4,2),(4,3),(4,4),(4,5),(4,6),(4,7),(4,8),(4,10),(4,11) ON CONFLICT DO NOTHING;
INSERT INTO RolePermission (role_id, permission_id) VALUES (5,3),(5,4),(5,5),(5,6),(5,7),(5,8) ON CONFLICT DO NOTHING;
INSERT INTO RolePermission (role_id, permission_id) VALUES (6,11) ON CONFLICT DO NOTHING;
INSERT INTO RolePermission (role_id, permission_id) VALUES (7,11) ON CONFLICT DO NOTHING;
INSERT INTO RolePermission (role_id, permission_id) VALUES (8,5),(8,6) ON CONFLICT DO NOTHING;
INSERT INTO RolePermission (role_id, permission_id) VALUES (9,2),(9,7) ON CONFLICT DO NOTHING;
INSERT INTO RolePermission (role_id, permission_id) VALUES (10,9) ON CONFLICT DO NOTHING;

-- ---------- Branches (3) ----------
INSERT INTO Branch (branch_id, name, address, city, province, postal_code, email, phone, status) VALUES
 (1,'Starchitex Bangkok Riverside','99 Charoen Krung Rd','Bangkok','Bangkok','10500','riverside.bkk@starchitex.com','+66-2-100-1001','Active'),
 (2,'Starchitex Chiang Mai Old Town','45 Ratchadamnoen Rd','Chiang Mai','Chiang Mai','50200','oldtown.cnx@starchitex.com','+66-53-200-2002','Active'),
 (3,'Starchitex Phuket Beachfront','8 Patak Rd, Karon','Phuket','Phuket','83100','beach.hkt@starchitex.com','+66-76-300-3003','Active')
ON CONFLICT (branch_id) DO NOTHING;

-- ---------- Room types ----------
INSERT INTO RoomType (room_type_id, type_name, description, base_price, capacity) VALUES
 (1,'Standard','Standard double room',1500,2),
 (2,'Deluxe','Deluxe room with city view',2500,2),
 (3,'Suite','Suite with living area',4500,4)
ON CONFLICT (room_type_id) DO NOTHING;

-- ---------- Rooms (10 across the 3 branches) ----------
INSERT INTO Room (room_id, room_number, floor, branch_id, room_type_id) VALUES
 (1,'101',1,1,1),
 (2,'102',1,1,1),
 (3,'201',2,1,2),
 (4,'301',3,1,3),   -- kept free as the demo "available" room
 (5,'101',1,2,1),
 (6,'102',1,2,1),
 (7,'201',2,2,2),
 (8,'101',1,3,1),
 (9,'102',1,3,1),
 (10,'201',2,3,2)
ON CONFLICT (room_id) DO NOTHING;

-- ---------- Facilities ----------
INSERT INTO Facility (facility_id, branch_id, facility_name, description, capacity, location) VALUES
 (1,1,'Rooftop Pool','Outdoor pool with skyline view',40,'Level 8')
ON CONFLICT (facility_id) DO NOTHING;

-- ---------- Services ----------
INSERT INTO Service (service_id, service_name, category, price, description) VALUES
 (1,'Breakfast Buffet','Food',350,'All-you-can-eat breakfast buffet'),
 (2,'Airport Transfer','Transport',800,'One-way airport pickup/drop-off'),
 (3,'Spa Massage','Wellness',1200,'60-minute Thai massage')
ON CONFLICT (service_id) DO NOTHING;

-- ---------- Employees (one per staff role, spread across branches) ----------
INSERT INTO Employee (employee_id, branch_id, first_name, last_name, position, gender, date_of_birth, phone, email, hire_date, salary, employment_status) VALUES
 (1,1,'Somchai','Wattana','System Administrator','Male','1988-03-12','+66-81-111-0001','somchai.w@starchitex.com','2022-01-10',68000,'Active'),
 (2,1,'Prapaporn','Srisuk','Hotel Owner','Female','1975-07-30','+66-81-111-0002','prapaporn.s@starchitex.com','2020-06-01',150000,'Active'),
 (3,1,'Anan','Chaiyo','Sales Executive','Male','1985-11-02','+66-81-111-0003','anan.c@starchitex.com','2021-04-15',85000,'Active'),
 (4,1,'Wanida','Boonmee','Branch Manager','Female','1982-02-18','+66-81-111-0004','wanida.b@starchitex.com','2021-01-05',90000,'Active'),
 (5,1,'Malee','Suksawat','Front Desk Receptionist','Female','1996-05-09','+66-81-111-0005','malee.s@starchitex.com','2023-03-01',32000,'Active'),
 (6,2,'Nattapong','Silpakorn','Housekeeping Staff','Male','1992-08-14','+66-81-111-0006','nattapong.s@starchitex.com','2022-07-11',26000,'Active'),
 (7,2,'Chai','Anantasin','Maintenance Technician','Male','1989-12-01','+66-81-111-0007','chai.a@starchitex.com','2021-09-20',30000,'Active'),
 (8,2,'Siriporn','Ngamwong','Finance Manager','Female','1984-04-23','+66-81-111-0008','siriporn.n@starchitex.com','2020-11-02',75000,'Active'),
 (9,3,'Kanya','Thongchai','HR Manager','Female','1987-10-06','+66-81-111-0009','kanya.t@starchitex.com','2022-02-14',72000,'Active')
ON CONFLICT (employee_id) DO NOTHING;

-- ---------- Employee credentials (password 'demo1234') ----------
INSERT INTO EmployeeCredentials (employee_id, username, password_hash, role_id, last_login) VALUES
 (1,'admin.sys',        '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',1, now() - interval '1 day'),
 (2,'owner.hq',         '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',2, now() - interval '2 day'),
 (3,'sales.bkk',        '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',3, now() - interval '3 day'),
 (4,'manager.bkk',      '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',4, now() - interval '1 day'),
 (5,'reception.bkk',    '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',5, now()),
 (6,'housekeeping.cnx', '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',6, now() - interval '1 day'),
 (7,'maintenance.cnx',  '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',7, now() - interval '5 day'),
 (8,'finance.cnx',      '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',8, now() - interval '2 day'),
 (9,'hr.hkt',           '$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',9, now() - interval '4 day')
ON CONFLICT (employee_id) DO NOTHING;

-- ---------- Guests (6; #6 = Demo Guest with a login) ----------
INSERT INTO Guest (guest_id, first_name, last_name, gender, date_of_birth, nationality, passport_number, phone_number, email, address, created_at) VALUES
 (1,'Hannah','Miller','Female','1991-04-05','USA','US9412345','+1-202-555-0101','hannah.miller@example.com','12 Elm St, Boston','2026-05-05 10:00'),
 (2,'Kenji','Tanaka','Male','1985-09-21','Japan','JP7765432','+81-90-1234-5678','kenji.tanaka@example.jp','3-2-1 Shibuya, Tokyo','2026-05-18 09:30'),
 (3,'Li','Wei','Male','1993-12-11','China','CN5523891','+86-138-0000-1111','li.wei@example.cn','88 Nanjing Rd, Shanghai','2026-06-02 14:20'),
 (4,'Emma','Johansson','Female','1989-06-30','Sweden','SE3311224','+46-70-123-4567','emma.j@example.se','Storgatan 5, Stockholm','2026-06-14 16:45'),
 (5,'Somsak','Rakthai','Male','1990-01-22','Thailand','TH1122334','+66-89-222-3344','somsak.r@example.com','21 Sukhumvit Rd, Bangkok','2026-06-20 11:15'),
 (6,'Demo','Guest','Female','1995-07-07','Thailand','TH9988776','+66-89-999-0000','demo.guest@example.com','1 Demo Rd, Bangkok','2026-07-01 08:00')
ON CONFLICT (guest_id) DO NOTHING;

-- ---------- Guest credentials (password 'demo1234') ----------
INSERT INTO GuestCredentials (guest_cred_id, guest_id, username, password_hash, role_id, last_login) VALUES
 (1,6,'demo.guest','$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',10, now() - interval '1 day')
ON CONFLICT (guest_cred_id) DO NOTHING;

-- ---------- Reservations (8, spanning every lifecycle status) ----------
INSERT INTO Reservation (reservation_id, branch_id, guest_id, check_in_date, check_out_date, actual_checkin_time, actual_checkout_time, num_of_guests, status) VALUES
 (1,1,1,'2026-07-01','2026-07-05','2026-07-01 14:00','2026-07-05 11:00',2,'Checked Out'),
 (2,1,2,'2026-07-10','2026-07-14','2026-07-10 15:00',NULL,2,'Checked In'),
 (3,1,3,'2026-07-20','2026-07-23',NULL,NULL,1,'Confirmed'),
 (4,2,4,'2026-08-01','2026-08-03',NULL,NULL,2,'Pending'),
 (5,2,5,'2026-06-15','2026-06-18',NULL,NULL,2,'Cancelled'),
 (6,3,6,'2026-07-16','2026-07-19',NULL,NULL,1,'Confirmed'),
 (7,1,1,'2026-09-01','2026-09-04',NULL,NULL,2,'Pending'),
 (8,2,3,'2026-07-05','2026-07-07','2026-07-05 13:00','2026-07-07 10:00',1,'Checked Out')
ON CONFLICT (reservation_id) DO NOTHING;

-- Room assignments (drives trg_sync_room_availability -> auto-populates RoomAvailability).
-- Reservation 5 (Cancelled) intentionally has no room link, matching real
-- post-cancellation state (trg_cleanup_on_reservation_cancel would have removed it).
INSERT INTO ReservationRoom (reservation_id, room_id) VALUES
 (1,1),
 (2,2),
 (3,3),
 (4,5),
 (6,8),
 (7,1),
 (8,7)
ON CONFLICT DO NOTHING;

-- ---------- Invoices ----------
-- Inserted with placeholder totals; trg_recalculate_invoice_total_on_item_change
-- recomputes sub_total/tax_amount/total_amount as soon as InvoiceItem rows land.
INSERT INTO Invoice (invoice_id, reservation_id, payer_guest_id, sub_total, tax_amount, total_amount, status) VALUES
 (1,1,1,0,0,0,'Unpaid'),
 (2,8,3,0,0,0,'Unpaid'),
 (3,2,2,0,0,0,'Unpaid')
ON CONFLICT (invoice_id) DO NOTHING;

-- trg_enforce_invoice_item_price auto-fills `amount` from RoomType.base_price / Service.price.
INSERT INTO InvoiceItem (invoice_item_id, invoice_id, room_id, service_id, item_type, quantity, amount) VALUES
 (1,1,1,NULL,'Room',4,0),
 (2,1,NULL,1,'Service',2,0),
 (3,2,7,NULL,'Room',2,0),
 (4,3,2,NULL,'Room',4,0)
ON CONFLICT (invoice_item_id) DO NOTHING;

-- ---------- Payments ----------
-- Invoice 1 total after items: (1500*4 + 350*2) = 6700, tax 7% = 469, total 7169 -> paid in full.
-- Invoice 2 total after items: (2500*2) = 5000, tax 350, total 5350 -> partially paid.
-- Invoice 3 is left unpaid on purpose to show the "Unpaid" billing state.
INSERT INTO Payment (payment_id, invoice_id, amount, payment_method, transaction_ref) VALUES
 (1,1,7169.00,'Credit Card','TXN-DEMO-0001'),
 (2,2,2000.00,'Cash','TXN-DEMO-0002')
ON CONFLICT (payment_id) DO NOTHING;

-- ---------- Service request, room task, room maintenance (light coverage) ----------
INSERT INTO ServiceRequest (request_id, reservation_id, service_id, description, status) VALUES
 (1,2,1,'Breakfast for 2, room service','Pending')
ON CONFLICT (request_id) DO NOTHING;

INSERT INTO RoomTask (roomtask_id, room_id, description, status) VALUES
 (1,4,'Deep clean before next guest','Pending')
ON CONFLICT (roomtask_id) DO NOTHING;

INSERT INTO RoomMaintenance (room_maintenance_id, room_id, priority, description, status) VALUES
 (1,9,'Medium','AC unit noisy','Reported')
ON CONFLICT (room_maintenance_id) DO NOTHING;

INSERT INTO FacilityBooking (facility_booking_id, reservation_id, facility_id, start_date_time, end_date_time) VALUES
 (1,3,1,'2026-07-21 10:00','2026-07-21 12:00')
ON CONFLICT (facility_booking_id) DO NOTHING;

-- ---------- Advance every sequence past the explicit IDs above ----------
-- (Required because SERIAL PKs were bypassed with explicit values; without
-- this, the app's first real INSERT via the API would collide on nextval().)
SELECT setval('branch_branch_id_seq', (SELECT COALESCE(MAX(branch_id), 1) FROM Branch));
SELECT setval('role_role_id_seq', (SELECT COALESCE(MAX(role_id), 1) FROM Role));
SELECT setval('permission_permission_id_seq', (SELECT COALESCE(MAX(permission_id), 1) FROM Permission));
SELECT setval('roomtype_room_type_id_seq', (SELECT COALESCE(MAX(room_type_id), 1) FROM RoomType));
SELECT setval('service_service_id_seq', (SELECT COALESCE(MAX(service_id), 1) FROM Service));
SELECT setval('guest_guest_id_seq', (SELECT COALESCE(MAX(guest_id), 1) FROM Guest));
SELECT setval('facility_facility_id_seq', (SELECT COALESCE(MAX(facility_id), 1) FROM Facility));
SELECT setval('room_room_id_seq', (SELECT COALESCE(MAX(room_id), 1) FROM Room));
SELECT setval('employee_employee_id_seq', (SELECT COALESCE(MAX(employee_id), 1) FROM Employee));
SELECT setval('guestcredentials_guest_cred_id_seq', (SELECT COALESCE(MAX(guest_cred_id), 1) FROM GuestCredentials));
SELECT setval('reservation_reservation_id_seq', (SELECT COALESCE(MAX(reservation_id), 1) FROM Reservation));
SELECT setval('invoice_invoice_id_seq', (SELECT COALESCE(MAX(invoice_id), 1) FROM Invoice));
SELECT setval('invoiceitem_invoice_item_id_seq', (SELECT COALESCE(MAX(invoice_item_id), 1) FROM InvoiceItem));
SELECT setval('payment_payment_id_seq', (SELECT COALESCE(MAX(payment_id), 1) FROM Payment));
SELECT setval('servicerequest_request_id_seq', (SELECT COALESCE(MAX(request_id), 1) FROM ServiceRequest));
SELECT setval('roomtask_roomtask_id_seq', (SELECT COALESCE(MAX(roomtask_id), 1) FROM RoomTask));
SELECT setval('roommaintenance_room_maintenance_id_seq', (SELECT COALESCE(MAX(room_maintenance_id), 1) FROM RoomMaintenance));
SELECT setval('facilitybooking_facility_booking_id_seq', (SELECT COALESCE(MAX(facility_booking_id), 1) FROM FacilityBooking));

COMMIT;
