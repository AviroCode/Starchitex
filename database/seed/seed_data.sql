-- ============================================================
-- Starchitex seed data (schema v3)
-- ~10+ coherent rows per table · 3 operating branches (+7 registered)
-- Demo anchors: guest_id 12 "Demo Guest" · room_id 4 (BKK 104, kept free)
--               receptionist logins reception.bkk / reception.cnx / reception.hkt
--               all seeded passwords = 'demo1234' (bcrypt via pgcrypto)
-- Run AFTER schema.sql + trigger_release_availability.sql:
--   psql "$DATABASE_URL" -f seed_data.sql
-- ============================================================

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------- 1. branch (10) ----------
INSERT INTO branch (branch_id, name, address, city, province, postal_code, email, phone, status) VALUES
 (1,'Starchitex Bangkok Riverside','99 Charoen Krung Rd','Bangkok','Bangkok','10500','riverside.bkk@starchitex.com','+66-2-100-1001','Active'),
 (2,'Starchitex Chiang Mai Old Town','45 Ratchadamnoen Rd','Chiang Mai','Chiang Mai','50200','oldtown.cnx@starchitex.com','+66-53-200-2002','Active'),
 (3,'Starchitex Phuket Beachfront','8 Patak Rd, Karon','Phuket','Phuket','83100','beach.hkt@starchitex.com','+66-76-300-3003','Active'),
 (4,'Starchitex Ayutthaya Heritage','12 U-Thong Rd','Ayutthaya','Ayutthaya','13000','heritage.ayy@starchitex.com','+66-35-400-4004','Active'),
 (5,'Starchitex Khon Kaen Central','300 Mittraphap Rd','Khon Kaen','Khon Kaen','40000','central.kkc@starchitex.com','+66-43-500-5005','Active'),
 (6,'Starchitex Hua Hin Seaside','77 Naresdamri Rd','Hua Hin','Prachuap Khiri Khan','77110','seaside.hhq@starchitex.com','+66-32-600-6006','Active'),
 (7,'Starchitex Krabi Cliffside','21 Ao Nang Rd','Krabi','Krabi','81180','cliff.kbv@starchitex.com','+66-75-700-7007','Under Construction'),
 (8,'Starchitex Udon Grand','5 Prajak Rd','Udon Thani','Udon Thani','41000','grand.uth@starchitex.com','+66-42-800-8008','Under Construction'),
 (9,'Starchitex Pattaya Bay','404 Beach Rd','Pattaya','Chonburi','20150','bay.pyx@starchitex.com','+66-38-900-9009','Active'),
 (10,'Starchitex Samui Palm (legacy)','1 Chaweng Rd','Ko Samui','Surat Thani','84320','palm.usm@starchitex.com','+66-77-101-0010','Closed');
SELECT setval('branch_branch_id_seq', 10);

-- ---------- 2. role (10) ----------
INSERT INTO role (role_id, role_name, description) VALUES
 (1,'System Administrator','Oversees entire system configuration and security.'),
 (2,'Branch Manager','Oversees branch operations, occupancy, and reports.'),
 (3,'Front Desk Receptionist','Manages guest registrations and reservations.'),
 (4,'Housekeeping Staff','Manages room cleaning and status updates.'),
 (5,'Maintenance Staff','Manages room repairs and facility maintenance.'),
 (6,'Room Service Staff','Manages food orders and room service.'),
 (7,'Sales Executive','Handles corporate bookings and promotions.'),
 (8,'Accountant / Cashier','Processes payments and financial records.'),
 (9,'Hotel Owner / Regional Director','Monitors cross-branch performance and reports.'),
 (10,'Guest','Manages personal profile and bookings.');
SELECT setval('role_role_id_seq', 10);

-- ---------- 3. permission (Elbin's v2 catalog incl. branch perms; gaps 15/31/32 as in his doc) ----------
INSERT INTO permission (permission_id, permission_name, description) VALUES
 (1,'VIEW_GUEST','View guest information'),(2,'CREATE_GUEST','Register a new guest'),
 (3,'UPDATE_GUEST','Edit guest information'),(4,'DELETE_GUEST','Remove guest record'),
 (5,'VIEW_RESERVATION','View reservations'),(6,'CREATE_RESERVATION','Create a reservation'),
 (7,'UPDATE_RESERVATION','Modify reservation'),(8,'CANCEL_RESERVATION','Cancel reservation'),
 (9,'CHECK_IN','Check guest in'),(10,'CHECK_OUT','Check guest out'),
 (11,'VIEW_ROOM','View room details'),(12,'UPDATE_ROOM_STATUS','Change room status'),
 (13,'VIEW_PAYMENT','View payment records'),(14,'PROCESS_PAYMENT','Record a payment'),
 (16,'VIEW_INVOICE','View invoices'),(17,'CREATE_INVOICE','Generate invoices'),
 (18,'VIEW_SERVICE_REQUEST','View service requests'),(19,'CREATE_SERVICE_REQUEST','Create service requests'),
 (20,'UPDATE_SERVICE_REQUEST','Update service request status'),
 (21,'VIEW_ROOM_TASK','View cleaning tasks'),(22,'ASSIGN_ROOM_TASK','Assign cleaning tasks'),
 (23,'COMPLETE_ROOM_TASK','Mark cleaning complete'),
 (24,'VIEW_MAINTENANCE','View maintenance requests'),(25,'CREATE_MAINTENANCE','Report maintenance issue'),
 (26,'UPDATE_MAINTENANCE','Update maintenance status'),
 (27,'VIEW_EMPLOYEE','View employee records'),(28,'CREATE_EMPLOYEE','Add employee'),
 (29,'UPDATE_EMPLOYEE','Edit employee'),(30,'DELETE_EMPLOYEE','Remove employee'),
 (33,'CREATE_USERS','Create user accounts'),(34,'UPDATE_USERS','Update user accounts'),
 (35,'CREATE_ROLES','Create roles'),(36,'UPDATE_ROLE','Update roles'),(37,'DELETE_ROLE','Delete roles'),
 (38,'VIEW_AUDIT_LOG','View audit logs'),
 (39,'VIEW_BRANCH','View branches'),(40,'CREATE_BRANCH','Create branch'),
 (41,'UPDATE_BRANCH','Update branch'),(42,'DELETE_BRANCH','Delete branch');
SELECT setval('permission_permission_id_seq', 42);

-- ---------- 4. role_permission (Elbin's matrix + the 5 agreed bug-fixes*) ----------
-- *fixes applied: Housekeeping gets 12 & 23; Room Service gets 18,19,20;
--  Maintenance gets 26; Accountant gets 14 & 16; Guest gets 16 (own invoices).
INSERT INTO role_permission (role_id, permission_id) VALUES
 -- 1 System Administrator
 (1,11),(1,27),(1,28),(1,29),(1,30),(1,33),(1,34),(1,35),(1,36),(1,37),(1,38),(1,39),(1,40),(1,41),(1,42),
 -- 9 Hotel Owner
 (9,1),(9,5),(9,11),(9,13),(9,18),(9,21),(9,24),(9,27),(9,28),(9,29),(9,30),(9,39),(9,40),(9,41),(9,42),
 -- 2 Branch Manager
 (2,1),(2,2),(2,3),(2,4),(2,5),(2,11),(2,13),(2,18),(2,21),(2,22),(2,24),(2,25),(2,27),(2,28),(2,29),(2,30),(2,39),
 -- 3 Front Desk Receptionist
 (3,1),(3,2),(3,3),(3,4),(3,5),(3,6),(3,7),(3,8),(3,9),(3,10),(3,11),(3,13),(3,14),(3,16),(3,17),(3,18),(3,19),(3,20),(3,21),(3,39),
 -- 8 Accountant / Cashier
 (8,13),(8,14),(8,16),(8,39),(8,27),
 -- 4 Housekeeping Staff
 (4,11),(4,12),(4,21),(4,23),(4,25),(4,39),(4,27),
 -- 5 Maintenance Staff
 (5,11),(5,24),(5,25),(5,26),(5,39),(5,27),
 -- 6 Room Service Staff
 (6,11),(6,18),(6,19),(6,20),(6,39),(6,27),
 -- 7 Sales Executive (view-only pending team decision)
 (7,1),(7,39),(7,27),
 -- 10 Guest (own-scoped; enforcement in functions/views)
 (10,1),(10,2),(10,3),(10,5),(10,6),(10,7),(10,8),(10,13),(10,14),(10,16),(10,11),(10,19);

-- ---------- 5. room_type (10) ----------
INSERT INTO room_type (room_type_id, type_name, description, base_price, capacity) VALUES
 (1,'Standard','Cozy room, city view',1500.00,2),
 (2,'Deluxe','Larger room, premium bedding',2500.00,2),
 (3,'Twin','Two single beds',1800.00,2),
 (4,'Family','Connecting space for four',3200.00,4),
 (5,'Suite','Separate living area',4800.00,3),
 (6,'Executive','Work desk, lounge access',3800.00,2),
 (7,'Penthouse','Top floor, panoramic view',9500.00,4),
 (8,'Accessible','Step-free, roll-in shower',1700.00,2),
 (9,'King','King bed, corner unit',2200.00,2),
 (10,'Villa','Detached with plunge pool',7200.00,5);
SELECT setval('room_type_room_type_id_seq', 10);

-- ---------- 6. room (24 across branches 1–3; room 4 = demo room, kept free) ----------
INSERT INTO room (room_id, branch_id, room_number, floor, room_type_id, housekeeping_status) VALUES
 (1,1,'101',1,1,'Clean'),(2,1,'102',1,1,'Dirty'),(3,1,'103',1,3,'Cleaning'),(4,1,'104',1,2,'Clean'),
 (5,1,'201',2,2,'Clean'),(6,1,'202',2,5,'Inspected'),(7,1,'203',2,6,'Clean'),(8,1,'301',3,7,'Clean'),
 (9,2,'101',1,1,'Clean'),(10,2,'102',1,8,'Clean'),(11,2,'103',1,3,'Dirty'),(12,2,'201',2,2,'Clean'),
 (13,2,'202',2,9,'Clean'),(14,2,'203',2,4,'Cleaning'),(15,2,'301',3,5,'Clean'),(16,2,'302',3,6,'Clean'),
 (17,3,'101',1,9,'Clean'),(18,3,'102',1,1,'Clean'),(19,3,'103',1,2,'Dirty'),(20,3,'201',2,4,'Clean'),
 (21,3,'202',2,5,'Clean'),(22,3,'301',3,10,'Inspected'),(23,3,'302',3,7,'Clean'),(24,3,'303',3,2,'Clean');
SELECT setval('room_room_id_seq', 24);

-- ---------- 7. employee (16) ----------
INSERT INTO employee (employee_id, branch_id, first_name, last_name, position, gender, date_of_birth, phone, email, hire_date, salary, employee_status) VALUES
 (1,1,'Somchai','Wattana','System Administrator','Male','1988-03-12','+66-81-111-0001','somchai.w@starchitex.com','2022-01-10',68000,'Active'),
 (2,1,'Prapaporn','Srisuk','Hotel Owner / Regional Director','Female','1975-07-30','+66-81-111-0002','prapaporn.s@starchitex.com','2020-06-01',150000,'Active'),
 (3,1,'Anan','Chaiyo','Branch Manager','Male','1985-11-02','+66-81-111-0003','anan.c@starchitex.com','2021-04-15',85000,'Active'),
 (4,1,'Kanya','Phromma','Front Desk Receptionist','Female','1996-02-18','+66-81-111-0004','kanya.p@starchitex.com','2023-02-01',28000,'Active'),
 (5,1,'Nok','Saengthong','Housekeeping Staff','Female','1993-09-25','+66-81-111-0005','nok.s@starchitex.com','2022-08-20',19000,'Active'),
 (6,1,'Prasit','Kongkaew','Maintenance Staff','Male','1987-12-05','+66-81-111-0006','prasit.k@starchitex.com','2021-11-11',24000,'Active'),
 (7,1,'Malee','Thongdee','Accountant / Cashier','Female','1990-05-14','+66-81-111-0007','malee.t@starchitex.com','2022-03-03',35000,'Active'),
 (8,1,'Chai','Rungruang','Room Service Staff','Male','1998-08-08','+66-81-111-0008','chai.r@starchitex.com','2024-01-15',18000,'Active'),
 (9,2,'Duangjai','Nimman','Branch Manager','Female','1983-04-22','+66-81-222-0009','duangjai.n@starchitex.com','2021-07-01',80000,'Active'),
 (10,2,'Tanawat','Lersuk','Front Desk Receptionist','Male','1997-10-10','+66-81-222-0010','tanawat.l@starchitex.com','2023-05-12',26000,'Active'),
 (11,2,'Siriporn','Chomphu','Housekeeping Staff','Female','1992-01-30','+66-81-222-0011','siriporn.c@starchitex.com','2022-10-05',18500,'Active'),
 (12,2,'Wichai','Boonmee','Maintenance Staff','Male','1986-06-17','+66-81-222-0012','wichai.b@starchitex.com','2020-09-09',23500,'On Leave'),
 (13,3,'Pimchan','Talay','Branch Manager','Female','1984-08-28','+66-81-333-0013','pimchan.t@starchitex.com','2021-02-14',82000,'Active'),
 (14,3,'Krit','Andaman','Front Desk Receptionist','Male','1995-12-01','+66-81-333-0014','krit.a@starchitex.com','2023-09-01',27000,'Active'),
 (15,3,'Sunee','Kaewjai','Housekeeping Staff','Female','1994-03-03','+66-81-333-0015','sunee.k@starchitex.com','2023-01-20',18500,'Active'),
 (16,3,'Somsak','Naklua','Sales Executive','Male','1989-09-19','+66-81-333-0016','somsak.n@starchitex.com','2022-05-25',42000,'Terminated');
SELECT setval('employee_employee_id_seq', 16);

-- ---------- 8. employee_credentials (14; password 'demo1234') ----------
INSERT INTO employee_credentials (employee_id, username, password_hash, role_id, last_login)
SELECT e.employee_id, u.username, crypt('demo1234', gen_salt('bf')), u.role_id, now() - (u.days || ' days')::interval
FROM (VALUES
 (1,'admin.sys',1,1),(2,'owner.hq',9,2),(3,'manager.bkk',2,0),(4,'reception.bkk',3,0),
 (5,'housekeeping.bkk',4,1),(6,'maintenance.bkk',5,3),(7,'cashier.bkk',8,0),(8,'roomservice.bkk',6,2),
 (9,'manager.cnx',2,1),(10,'reception.cnx',3,0),(11,'housekeeping.cnx',4,2),(12,'maintenance.cnx',5,30),
 (13,'manager.hkt',2,1),(14,'reception.hkt',3,0)
) AS u(employee_id, username, role_id, days)
JOIN employee e ON e.employee_id = u.employee_id;

-- ---------- 9. guest (12; #12 = Demo Guest) ----------
INSERT INTO guest (guest_id, first_name, last_name, gender, date_of_birth, nationality, passport_number, phone_number, email, address, created_at) VALUES
 (1,'Hannah','Miller','Female','1991-04-05','USA','US9412345','+1-202-555-0101','hannah.miller@example.com','12 Elm St, Boston','2026-01-05 10:00'),
 (2,'Kenji','Tanaka','Male','1985-09-21','Japan','JP7765432','+81-90-1234-5678','kenji.tanaka@example.jp','3-2-1 Shibuya, Tokyo','2026-01-18 09:30'),
 (3,'Li','Wei','Male','1993-12-11','China','CN5523891','+86-138-0000-1111','li.wei@example.cn','88 Nanjing Rd, Shanghai','2026-02-02 14:20'),
 (4,'Emma','Johansson','Female','1989-06-30','Sweden','SE3311224','+46-70-123-4567','emma.j@example.se','Storgatan 5, Stockholm','2026-02-14 16:45'),
 (5,'Arjun','Patel','Male','1996-01-25','India','IN8899001','+91-98765-43210','arjun.patel@example.in','MG Road, Mumbai','2026-03-01 11:10'),
 (6,'Sophie','Dubois','Female','1994-08-17','France','FR4455667','+33-6-12-34-56-78','sophie.dubois@example.fr','10 Rue de Rivoli, Paris','2026-03-12 08:55'),
 (7,'Mohammed','Al-Rashid','Male','1982-02-09','UAE','AE1122334','+971-50-123-4567','m.alrashid@example.ae','Sheikh Zayed Rd, Dubai','2026-03-28 19:05'),
 (8,'Olivia','Brown','Female','1999-11-03','UK','GB6677889','+44-7700-900123','olivia.brown@example.uk','5 Baker St, London','2026-04-09 12:40'),
 (9,'Nattapong','Suksawat','Male','1990-07-07','Thailand','TH2233445','+66-89-123-4567','nattapong.s@example.co.th','Sukhumvit 21, Bangkok','2026-04-22 15:15'),
 (10,'Maria','Santos','Female','1987-10-19','Brazil','BR9988776','+55-11-91234-5678','maria.santos@example.br','Av. Paulista, Sao Paulo','2026-05-06 09:00'),
 (11,'Min-jun','Kim','Male','1992-05-27','South Korea','KR5544332','+82-10-1234-5678','minjun.kim@example.kr','Gangnam-gu, Seoul','2026-05-30 17:35'),
 (12,'Demo','Guest','Other','1990-01-01','Thailand','DEMO00001','+66-80-000-0000','demo.guest@starchitex.com','Demo Address, Salaya','2026-06-15 10:00');
SELECT setval('guest_guest_id_seq', 12);

-- ---------- 10. guest_credentials (10; password 'demo1234') ----------
INSERT INTO guest_credentials (guest_cred_id, guest_id, username, password_hash, role_id, last_login)
SELECT g.n, g.n, g.uname, crypt('demo1234', gen_salt('bf')), 10, now() - (g.n || ' days')::interval
FROM (VALUES (1,'hannah.m'),(2,'kenji.t'),(3,'li.wei'),(4,'emma.j'),(5,'arjun.p'),
             (6,'sophie.d'),(7,'m.alrashid'),(8,'olivia.b'),(9,'nattapong.s'),(12,'demo.guest')
) AS g(n, uname);
SELECT setval('guest_credentials_guest_cred_id_seq', 12);

-- ---------- 11. reservation (14; today = 2026-07-10) ----------
INSERT INTO reservation (reservation_id, guest_id, branch_id, check_in_date, check_out_date, actual_checkin_time, actual_checkout_time, booking_date, num_of_guests, status) VALUES
 -- past, checked out
 (1,1,1,'2026-06-01','2026-06-04','2026-06-01 14:05','2026-06-04 11:20','2026-05-20',2,'Checked Out'),
 (2,2,1,'2026-06-10','2026-06-12','2026-06-10 15:00','2026-06-12 10:45','2026-05-28',1,'Checked Out'),
 (3,3,2,'2026-06-05','2026-06-09','2026-06-05 13:40','2026-06-09 11:00','2026-05-15',2,'Checked Out'),
 (4,4,3,'2026-06-20','2026-06-25','2026-06-20 16:10','2026-06-25 10:30','2026-06-01',4,'Checked Out'),
 -- currently in-house (span today)
 (5,5,1,'2026-07-08','2026-07-12','2026-07-08 14:30',NULL,'2026-06-25',2,'Checked In'),
 (6,6,2,'2026-07-09','2026-07-13','2026-07-09 15:20',NULL,'2026-07-01',1,'Checked In'),
 (7,7,3,'2026-07-07','2026-07-14','2026-07-07 18:00',NULL,'2026-06-15',3,'Checked In'),
 -- confirmed, upcoming
 (8,8,1,'2026-07-20','2026-07-23',NULL,NULL,'2026-07-05',2,'Confirmed'),
 (9,9,2,'2026-07-25','2026-07-28',NULL,NULL,'2026-07-08',2,'Confirmed'),
 (10,10,3,'2026-08-01','2026-08-05',NULL,NULL,'2026-07-09',5,'Confirmed'),
 -- pending
 (11,11,1,'2026-08-10','2026-08-12',NULL,NULL,'2026-07-10',1,'Pending'),
 (12,1,2,'2026-08-15','2026-08-18',NULL,NULL,'2026-07-10',2,'Pending'),
 -- cancelled
 (13,2,1,'2026-07-15','2026-07-18',NULL,NULL,'2026-06-30',2,'Cancelled'),
 (14,3,3,'2026-07-22','2026-07-24',NULL,NULL,'2026-07-02',1,'Cancelled');
SELECT setval('reservation_reservation_id_seq', 14);

-- ---------- 12. reservation_room (16; price snapshot at booking) ----------
INSERT INTO reservation_room (reservation_id, room_id, price_per_night) VALUES
 (1,1,1500.00),(2,5,2500.00),(3,9,1500.00),(4,20,3200.00),(4,21,4800.00),
 (5,5,2500.00),(6,12,2500.00),(7,22,7200.00),
 (8,6,4800.00),(9,13,2200.00),(10,20,3200.00),(10,23,9500.00),
 (11,7,3800.00),(12,15,4800.00),(13,1,1500.00),(14,17,2200.00);

-- ---------- 13. room_availability (generated from live bookings + extras) ----------
-- Reserved/Occupied rows for Confirmed & Checked In reservations
INSERT INTO room_availability (room_id, calendar_date, status, reservation_id)
SELECT rr.room_id, d::date,
       CASE WHEN r.status = 'Checked In' THEN 'Occupied' ELSE 'Reserved' END,
       r.reservation_id
FROM reservation r
JOIN reservation_room rr ON rr.reservation_id = r.reservation_id
CROSS JOIN LATERAL generate_series(r.check_in_date, r.check_out_date - 1, interval '1 day') AS d
WHERE r.status IN ('Confirmed', 'Checked In');
-- Demo room (id 4): open for the next 14 days
INSERT INTO room_availability (room_id, calendar_date, status)
SELECT 4, d::date, 'Available'
FROM generate_series(DATE '2026-07-10', DATE '2026-07-23', interval '1 day') AS d;
-- Room 19 (HKT 103) blocked for repairs
INSERT INTO room_availability (room_id, calendar_date, status) VALUES
 (19,'2026-07-11','Under Maintenance'),(19,'2026-07-12','Under Maintenance'),(19,'2026-07-13','Under Maintenance');

-- ---------- 14. reservation_status_log ----------
INSERT INTO reservation_status_log (reservation_id, status, changed_by_employee_id, action_time, remarks)
SELECT r.reservation_id, 'Pending', NULL, r.booking_date::timestamp + interval '1 minute', 'Booking created'
FROM reservation r;
INSERT INTO reservation_status_log (reservation_id, status, changed_by_employee_id, action_time, remarks)
SELECT r.reservation_id, 'Confirmed',
       CASE r.branch_id WHEN 1 THEN 4 WHEN 2 THEN 10 ELSE 14 END,
       r.booking_date::timestamp + interval '1 day', 'Payment guarantee received'
FROM reservation r WHERE r.status IN ('Confirmed','Checked In','Checked Out');
INSERT INTO reservation_status_log (reservation_id, status, changed_by_employee_id, action_time, remarks)
SELECT r.reservation_id, 'Checked In',
       CASE r.branch_id WHEN 1 THEN 4 WHEN 2 THEN 10 ELSE 14 END,
       r.actual_checkin_time, 'Guest arrived'
FROM reservation r WHERE r.actual_checkin_time IS NOT NULL;
INSERT INTO reservation_status_log (reservation_id, status, changed_by_employee_id, action_time, remarks)
SELECT r.reservation_id, 'Checked Out',
       CASE r.branch_id WHEN 1 THEN 4 WHEN 2 THEN 10 ELSE 14 END,
       r.actual_checkout_time, 'Stay completed'
FROM reservation r WHERE r.actual_checkout_time IS NOT NULL;
INSERT INTO reservation_status_log (reservation_id, status, changed_by_employee_id, action_time, remarks)
SELECT r.reservation_id, 'Cancelled',
       CASE r.branch_id WHEN 1 THEN 4 WHEN 2 THEN 10 ELSE 14 END,
       r.booking_date::timestamp + interval '2 days', 'Cancelled by guest'
FROM reservation r WHERE r.status = 'Cancelled';

-- ---------- 15. service (10) ----------
INSERT INTO service (service_id, service_name, category, price, description) VALUES
 (1,'In-room Dining — Thai Set','Room Service',450.00,'Two-course Thai set delivered to room'),
 (2,'In-room Dining — Western Set','Room Service',520.00,'Continental set with dessert'),
 (3,'Laundry Express','Housekeeping',300.00,'Same-day wash and press'),
 (4,'Extra Bed Setup','Housekeeping',600.00,'Rollaway bed with linens'),
 (5,'Airport Transfer — Sedan','Transport',1200.00,'One-way private sedan'),
 (6,'Airport Transfer — Van','Transport',1800.00,'One-way van up to 8 pax'),
 (7,'Traditional Thai Massage 60min','Spa & Wellness',900.00,'In-spa treatment'),
 (8,'Aromatherapy 90min','Spa & Wellness',1600.00,'Signature oil massage'),
 (9,'Pool Cabana Half-day','Facility Access',800.00,'Reserved cabana with towels'),
 (10,'Gym Day Pass (visitor)','Facility Access',350.00,'Full gym access for guests'' visitors');
SELECT setval('service_service_id_seq', 10);

-- ---------- 16. service_request (12) ----------
INSERT INTO service_request (request_id, reservation_id, service_id, description, request_date, status, handled_by) VALUES
 (1,1,1,'Dinner for two, mild spice','2026-06-02','Completed',8),
 (2,1,3,'Two shirts, one dress','2026-06-02','Completed',5),
 (3,2,5,'Pickup 04:30 to BKK airport','2026-06-11','Completed',4),
 (4,3,7,'Evening slot preferred','2026-06-06','Completed',10),
 (5,4,8,'Anniversary treat','2026-06-21','Completed',14),
 (6,4,4,'Extra bed for child','2026-06-20','Completed',15),
 (7,5,1,'Late-night snack','2026-07-09','Completed',8),
 (8,5,3,'Laundry pickup at 9am','2026-07-10','In Progress',5),
 (9,6,7,'Post-hike recovery massage','2026-07-10','Pending',NULL),
 (10,7,9,'Cabana near kids pool','2026-07-08','Completed',14),
 (11,7,2,'Breakfast in room 301','2026-07-10','In Progress',14),
 (12,6,10,'Visitor gym pass Saturday','2026-07-11','Pending',NULL);
SELECT setval('service_request_request_id_seq', 12);

-- ---------- 17. invoice (10; math: total = sub + tax - discount) ----------
INSERT INTO invoice (invoice_id, reservation_id, payer_guest_id, invoice_date, sub_total, tax_amount, discount, total_amount, status) VALUES
 (1,1,1,'2026-06-04',5250.00,367.50,0.00,5617.50,'Paid'),          -- 3n x1500 + svc 450+300
 (2,2,2,'2026-06-12',6200.00,434.00,200.00,6434.00,'Paid'),        -- 2n x2500 + transfer 1200
 (3,3,3,'2026-06-09',6900.00,483.00,0.00,7383.00,'Paid'),          -- 4n x1500 + massage 900
 (4,4,4,'2026-06-25',42200.00,2954.00,2000.00,43154.00,'Paid'),    -- 5n x(3200+4800) + svc 1600+600
 (5,5,5,'2026-07-10',10450.00,731.50,0.00,11181.50,'Partially Paid'), -- 4n x2500 + svc 450
 (6,6,6,'2026-07-10',10000.00,700.00,0.00,10700.00,'Pending'),     -- 4n x2500
 (7,7,7,'2026-07-10',51200.00,3584.00,0.00,54784.00,'Partially Paid'), -- 7n x7200 + cabana 800
 (8,8,8,'2026-07-05',14400.00,1008.00,0.00,15408.00,'Pending'),    -- 3n x4800 (deposit invoice)
 (9,13,2,'2026-06-30',1500.00,105.00,0.00,1605.00,'Cancelled'),    -- cancellation fee, voided
 (10,4,7,'2026-06-25',1600.00,112.00,0.00,1712.00,'Paid');         -- split billing: spa on companion
SELECT setval('invoice_invoice_id_seq', 10);

-- ---------- 18. invoice_item (20; amount = quantity x unit_price) ----------
INSERT INTO invoice_item (invoice_id, item_type, quantity, unit_price, amount, reference_type, reference_id) VALUES
 (1,'Room Charge',3,1500.00,4500.00,'Room',1),
 (1,'Room Service',1,450.00,450.00,'ServiceRequest',1),
 (1,'Laundry',1,300.00,300.00,'ServiceRequest',2),
 (2,'Room Charge',2,2500.00,5000.00,'Room',5),
 (2,'Airport Transfer',1,1200.00,1200.00,'ServiceRequest',3),
 (3,'Room Charge',4,1500.00,6000.00,'Room',9),
 (3,'Spa',1,900.00,900.00,'ServiceRequest',4),
 (4,'Room Charge',5,3200.00,16000.00,'Room',20),
 (4,'Room Charge',5,4800.00,24000.00,'Room',21),
 (4,'Spa',1,1600.00,1600.00,'ServiceRequest',5),
 (4,'Extra Bed',1,600.00,600.00,'ServiceRequest',6),
 (5,'Room Charge',4,2500.00,10000.00,'Room',5),
 (5,'Room Service',1,450.00,450.00,'ServiceRequest',7),
 (6,'Room Charge',4,2500.00,10000.00,'Room',12),
 (7,'Room Charge',7,7200.00,50400.00,'Room',22),
 (7,'Facility',1,800.00,800.00,'FacilityBooking',4),
 (8,'Room Charge',3,4800.00,14400.00,'Room',6),
 (9,'Cancellation Fee',1,1500.00,1500.00,'Other',NULL),
 (10,'Spa',1,1600.00,1600.00,'ServiceRequest',5),
 (10,'Service Charge',1,0.00,0.00,'Other',NULL);

-- ---------- 19. payment (12; invoice 5 & 7 partial) ----------
INSERT INTO payment (payment_id, invoice_id, payment_date, amount, payment_method, transaction_ref) VALUES
 (1,1,'2026-06-04',5617.50,'Credit Card','TXN-2026-0604-0001'),
 (2,2,'2026-06-12',6434.00,'Mobile Payment','TXN-2026-0612-0002'),
 (3,3,'2026-06-09',7383.00,'Cash',NULL),
 (4,4,'2026-06-20',20000.00,'Bank Transfer','TXN-2026-0620-0004'),
 (5,4,'2026-06-25',23154.00,'Credit Card','TXN-2026-0625-0005'),
 (6,5,'2026-07-08',5000.00,'Credit Card','TXN-2026-0708-0006'),      -- partial 5000/11181.50
 (7,7,'2026-07-07',30000.00,'Bank Transfer','TXN-2026-0707-0007'),   -- partial 30000/54784
 (8,10,'2026-06-25',1712.00,'Credit Card','TXN-2026-0625-0008'),
 (9,2,'2026-06-11',0.00,'Cash','VOID-TEST'),                          -- zero-amount void record
 (10,1,'2026-06-01',0.00,'Cash','DEPOSIT-WAIVED'),
 (11,3,'2026-06-05',0.00,'Cash','DEPOSIT-WAIVED'),
 (12,4,'2026-06-01',0.00,'Cash','DEPOSIT-WAIVED');
SELECT setval('payment_payment_id_seq', 12);

-- ---------- 20. facility (10) ----------
INSERT INTO facility (facility_id, branch_id, facility_name, description, capacity, location) VALUES
 (1,1,'Riverside Infinity Pool','Rooftop pool over the Chao Phraya',40,'Rooftop, L8'),
 (2,1,'Grand Ballroom','Events up to 200 guests',200,'L2'),
 (3,1,'Fitness Centre BKK','24h gym',25,'L3'),
 (4,2,'Old Town Courtyard Pool','Garden pool',25,'Garden level'),
 (5,2,'Lanna Meeting Room','Boardroom for 16',16,'L1'),
 (6,2,'Fitness Centre CNX','Gym 06:00-22:00',15,'L1'),
 (7,3,'Beachfront Pool','Ocean-edge pool',50,'Beach level'),
 (8,3,'Sunset Rooftop Bar Deck','Private event deck',60,'Rooftop'),
 (9,3,'Kids Club','Supervised play area',20,'L1'),
 (10,3,'Dive Prep Room','Gear rinse and briefing room',12,'Beach level');
SELECT setval('facility_facility_id_seq', 10);

-- ---------- 21. facility_booking (10) ----------
INSERT INTO facility_booking (facility_booking_id, reservation_id, facility_id, booking_date, start_time, end_time) VALUES
 (1,1,3,'2026-06-02','2026-06-02 07:00','2026-06-02 08:00'),
 (2,2,1,'2026-06-11','2026-06-11 16:00','2026-06-11 18:00'),
 (3,3,5,'2026-06-07','2026-06-07 09:00','2026-06-07 12:00'),
 (4,7,7,'2026-07-08','2026-07-08 10:00','2026-07-08 14:00'),
 (5,7,9,'2026-07-09','2026-07-09 09:00','2026-07-09 12:00'),
 (6,5,3,'2026-07-09','2026-07-09 18:00','2026-07-09 19:30'),
 (7,6,4,'2026-07-10','2026-07-10 07:30','2026-07-10 09:00'),
 (8,8,2,'2026-07-21','2026-07-21 18:00','2026-07-21 23:00'),
 (9,10,8,'2026-08-02','2026-08-02 17:00','2026-08-02 21:00'),
 (10,9,6,'2026-07-26','2026-07-26 06:30','2026-07-26 07:30');
SELECT setval('facility_booking_facility_booking_id_seq', 10);

-- ---------- 22. room_task (10) ----------
INSERT INTO room_task (roomtask_id, room_id, assigned_employee_id, description, assigned_time, completed_time, status) VALUES
 (1,1,5,'Turnover after checkout res#1','2026-06-04 11:30','2026-06-04 12:40','Completed'),
 (2,5,5,'Turnover after checkout res#2','2026-06-12 11:00','2026-06-12 12:10','Completed'),
 (3,9,11,'Turnover after checkout res#3','2026-06-09 11:15','2026-06-09 12:30','Completed'),
 (4,20,15,'Turnover after checkout res#4','2026-06-25 10:45','2026-06-25 12:00','Completed'),
 (5,21,15,'Deep clean suite','2026-06-25 12:10','2026-06-25 14:00','Completed'),
 (6,2,5,'Turnover — guest departed early','2026-07-10 08:00',NULL,'Pending'),
 (7,3,5,'Deep clean twin room','2026-07-10 08:05',NULL,'In Progress'),
 (8,11,11,'Turnover room 103','2026-07-10 08:30',NULL,'Pending'),
 (9,14,11,'Family room reset','2026-07-10 09:00',NULL,'In Progress'),
 (10,19,15,'Post-repair full clean','2026-07-09 16:00',NULL,'Cancelled');
SELECT setval('room_task_roomtask_id_seq', 10);

-- ---------- 23. facility_task (10) ----------
INSERT INTO facility_task (facilitytask_id, facility_id, assigned_employee_id, description, assigned_time, completed_time, status) VALUES
 (1,1,5,'Morning pool deck reset','2026-07-10 06:00','2026-07-10 06:40','Completed'),
 (2,3,5,'Gym towel restock','2026-07-10 06:30','2026-07-10 06:50','Completed'),
 (3,4,11,'Courtyard pool skim','2026-07-10 06:15','2026-07-10 06:45','Completed'),
 (4,7,15,'Beach pool chlorine check','2026-07-10 06:00','2026-07-10 06:20','Completed'),
 (5,2,5,'Ballroom reset after event','2026-07-09 23:30',NULL,'In Progress'),
 (6,9,15,'Kids club toy sanitize','2026-07-10 08:00',NULL,'Pending'),
 (7,8,15,'Deck furniture arrangement','2026-07-10 09:00',NULL,'Pending'),
 (8,5,11,'Boardroom setup for 10:00','2026-07-10 08:30','2026-07-10 09:10','Completed'),
 (9,6,11,'Treadmill wipe-down rota','2026-07-10 07:00','2026-07-10 07:25','Completed'),
 (10,10,15,'Rinse tank refill','2026-07-09 17:00',NULL,'Cancelled');
SELECT setval('facility_task_facilitytask_id_seq', 10);

-- ---------- 24. room_maintenance (10) ----------
INSERT INTO room_maintenance (room_maintenance_id, room_id, reported_by, assigned_employee_id, report_date, priority, completion_date, description, status) VALUES
 (1,19,15,NULL,'2026-07-09','High',NULL,'Aircon leaking onto carpet','Pending'),
 (2,2,5,6,'2026-07-08','Medium',NULL,'Bathroom sink drains slowly','In Progress'),
 (3,11,11,12,'2026-07-05','Low','2026-07-07','Wardrobe door off track','Completed'),
 (4,7,4,6,'2026-06-28','Medium','2026-06-30','TV remote unresponsive','Completed'),
 (5,22,14,NULL,'2026-07-10','High',NULL,'Plunge pool pump noise','Pending'),
 (6,1,5,6,'2026-06-05','Low','2026-06-06','Bedside lamp flicker','Completed'),
 (7,13,10,12,'2026-06-18','Medium','2026-06-21','Balcony door seal worn','Completed'),
 (8,24,14,NULL,'2026-07-09','Low',NULL,'Scuffed wall near desk','Pending'),
 (9,6,4,6,'2026-07-01','High','2026-07-02','Safe lock error','Completed'),
 (10,16,10,12,'2026-06-25','Low','2026-06-25','Curtain hook missing','Completed');
SELECT setval('room_maintenance_room_maintenance_id_seq', 10);

-- ---------- 25. facility_maintenance (10) ----------
INSERT INTO facility_maintenance (facility_maintenance_id, facility_id, reported_by, assigned_employee_id, report_date, priority, completion_date, description, status) VALUES
 (1,1,5,6,'2026-07-06','High','2026-07-08','Pool filter pressure high','Completed'),
 (2,3,8,6,'2026-07-09','Medium',NULL,'Rowing machine belt slip','In Progress'),
 (3,4,11,12,'2026-07-02','Low','2026-07-04','Loose deck tile','Completed'),
 (4,7,15,NULL,'2026-07-10','High',NULL,'Underwater light out','Pending'),
 (5,2,3,6,'2026-06-20','Medium','2026-06-24','Stage step wobble','Completed'),
 (6,5,9,12,'2026-06-30','Low','2026-07-01','Projector remote pairing','Completed'),
 (7,8,13,NULL,'2026-07-09','Medium',NULL,'Deck rail repaint needed','Pending'),
 (8,9,13,NULL,'2026-07-08','Low',NULL,'Soft mat corner tear','Pending'),
 (9,6,9,12,'2026-06-15','Medium','2026-06-17','AC vent rattle','Completed'),
 (10,10,14,NULL,'2026-07-07','Low',NULL,'Hose nozzle replacement','Pending');
SELECT setval('facility_maintenance_facility_maintenance_id_seq', 10);

-- ---------- 26. audit_log (12; mixed employee & guest actors) ----------
INSERT INTO audit_log (employee_id, guest_id, action, table_name, pk_of_table, affected_col, action_time, old_value, new_value, IP_address) VALUES
 (4,NULL,'INSERT','reservation','5','*','2026-06-25 10:12','','guest 5, 2026-07-08..12','10.0.1.21'),
 (4,NULL,'UPDATE','reservation','5','status','2026-07-08 14:30','Confirmed','Checked In','10.0.1.21'),
 (10,NULL,'INSERT','reservation','6','*','2026-07-01 09:41','','guest 6, 2026-07-09..13','10.0.2.14'),
 (14,NULL,'UPDATE','reservation','7','status','2026-07-07 18:00','Confirmed','Checked In','10.0.3.18'),
 (7,NULL,'INSERT','payment','6','*','2026-07-08 16:02','','5000.00 Credit Card','10.0.1.33'),
 (5,NULL,'UPDATE','room','2','housekeeping_status','2026-07-10 08:01','Clean','Dirty','10.0.1.40'),
 (6,NULL,'UPDATE','room_maintenance','2','status','2026-07-09 09:15','Pending','In Progress','10.0.1.41'),
 (1,NULL,'UPDATE','employee_credentials','12','role_id','2026-07-01 11:00','5','5','10.0.0.2'),
 (NULL,12,'INSERT','reservation','11','*','2026-07-10 09:55','','self-booking attempt','203.0.113.7'),
 (NULL,2,'UPDATE','reservation','13','status','2026-07-02 08:20','Confirmed','Cancelled','198.51.100.23'),
 (3,NULL,'INSERT','room_task','6','*','2026-07-10 08:00','','turnover room 102','10.0.1.10'),
 (13,NULL,'INSERT','facility_maintenance','4','*','2026-07-10 07:45','','underwater light out','10.0.3.5');

COMMIT;

-- Row-count sanity report
SELECT relname AS table_name, n_live_tup AS rows
FROM pg_stat_user_tables ORDER BY relname;
