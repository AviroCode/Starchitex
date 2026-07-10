# Starchitex — Multi-Branch Hotel Management System

Our database course term project Starchitex is a centralized PostgreSQL database for a hotel chain with multiple branches — one shared database instead of each branch keeping its own copies of everything. It covers reservations, check-in/check-out, billing, service requests, housekeeping, maintenance, role-based access control, and audit logging.

Team:
- Aung Kaung Thar (6780844) — database implementation, backend
- Elbin Ye Htet Naing (6781209) — RBAC & security design, frontend
- Min Linn Khant (6780839) — testing/QA, deployment, monitoring



Everything the project brief asks for lives in the **`database/`** folder:

- `database/ddl/` — the schema (tables, constraints, triggers)
- `database/seed/` — example data, 10+ rows per table
- `database/functions/` — the query functions, one `.sql` file each
- `database/tests/` — our test suite (integrity, workflows, RBAC)

The live database runs on render.com — the connection URL and credentials are in the submitted report (we keep them out of this repo since it's public).

The `backend/` and `frontend/` folders are a working Spring Boot prototype we built on top of the database. It's a bonus, not part of the required deliverables — the brief doesn't ask for an app, so please judge the project by the `database/` folder and the report.

## Rebuilding the database from scratch

If anything happens to the live database, the whole thing can be recreated from this repo:

```bash
psql "$DATABASE_URL" -f database/ddl/schema.sql
psql "$DATABASE_URL" -f database/seed/seed_data.sql
for f in database/functions/*.sql; do psql "$DATABASE_URL" -f "$f"; done
```

(`DATABASE_URL` is the external URL from Render — see the report.)

## Running the tests

```bash
for f in database/tests/*.sql; do psql "$DATABASE_URL" -f "$f"; done
```

Each test prints its own PASS/FAIL lines, so the output is readable on its own. The suite covers things like: double-booking gets rejected, invoices have to add up, checkout can't come before check-in, the audit log can't be edited, and each staff role can only do what its permissions allow (including not seeing other branches' data).

---

## 📖 Database Design Architecture
This project designs a robust, enterprise-grade relational database for a multi-branch Hotel Management System. It supports the full hotel operation: room bookings, facility reservations, multi-department task assignment (housekeeping / maintenance), secure split billing, and a strict Role-Based Access Control (RBAC) security model.

The database is normalized to Third Normal Form (3NF), enforces referential integrity through mandatory foreign keys, and isolates data per branch so that staff only ever see the location they belong to.

---

## 🗂️ Entity Reference (26 Entities)

### Organization & People
* **Branch** — `branch_id (PK)`, `name`, `address`, `city`, `province`, `postal_code`, `email`, `phone`, `status`
  * A physical hotel location. A chain has many branches, each with its own staff and operational data.
* **Employee** — `employee_id (PK)`, `branch_id (FK)`, `first_name`, `last_name`, `position`, `gender`, `date_of_birth`, `phone`, `email`, `hire_date`, `salary`, `employment_status`
  * Staff members: identity, contact info, and branch/role assignment.
* **Guest** — `guest_id (PK)`, `first_name`, `last_name`, `gender`, `date_of_birth`, `nationality`, `passport_number`, `phone_number`, `email`, `address`, `created_at`
  * Personal identity and contact info for visitors; required for check-in and legal records.

### Authentication & Authorization
* **EmployeeCredentials** — `employee_id (PK, FK)`, `username (UQ)`, `password_hash`, `role_id (FK)`, `created_at`, `last_login`
  * Secure login for staff; one credential row per employee.
* **GuestCredentials** — `guest_cred_id (PK)`, `guest_id (FK)`, `username (UQ)`, `password_hash`, `role_id (FK)`, `created_at`, `last_login`
  * Login access for repeat guests using the hotel portal.
* **Role** — `role_id (PK)`, `role_name`, `description`
  * Master list of job functions in the hotel hierarchy.
* **Permission** — `permission_id (PK)`, `permission_name`, `description`
  * Granular actions allowed in the system.
* **RolePermission** — `role_id (FK)`, `permission_id (FK)`, `PRIMARY KEY (role_id, permission_id)`
  * Junction mapping which permissions each role is authorized to perform.

### Rooms & Inventory
* **RoomType** — `room_type_id (PK)`, `type_name`, `description`, `base_price`, `capacity`
  * Categorizes rooms by quality/size; drives pricing and filtering.
* **Room** — `room_id (PK)`, `room_number`, `floor`, `branch_id (FK)`, `room_type_id (FK)`
  * Individual physical rooms; the foundation of inventory.
* **RoomAvailability** — `availability_id (PK)`, `room_id (FK)`, `calendar_date`, `status`, `reservation_id (FK, NULLABLE)`, `price_override`
  * Day-by-day inventory calendar; answers availability queries without scanning full reservation history and allows blocking rooms for maintenance.

### Reservations
* **Reservation** — `reservation_id (PK)`, `guest_id (FK)`, `check_in_date`, `check_out_date`, `actual_checkin_time`, `actual_checkout_time`, `booking_date`, `num_of_guests`, `status`
  * The booking contract: dates and status of a guest's stay.
* **ReservationRoom** — `reservation_id (FK)`, `room_id (FK)`, `PRIMARY KEY (reservation_id, room_id)`
  * Junction connecting reservations to specific rooms; supports multi-room bookings.
* **ReservationStatusLog** — `log_id (PK)`, `reservation_id (FK)`, `status`, `changed_by_employee_id (FK)`, `action_time`, `remarks`
  * Audit trail of the booking life-cycle; tracks each status change and the employee responsible (survives shift changes).

### Billing
* **Invoice** — `invoice_id (PK)`, `reservation_id (FK)`, `payer_guest_id (FK)`, `invoice_date`, `sub_total`, `tax_amount`, `discount`, `total_amount`, `status`
  * The primary bill; `payer_guest_id` identifies who pays and supports split billing.
* **InvoiceItem** — `invoice_item_id (PK)`, `invoice_id (FK)`, `item_type`, `quantity`, `amount`
  * Line items (room charge, service fee, etc.).
* **Payment** — `payment_id (PK)`, `invoice_id (FK)`, `payment_date`, `amount`, `payment_method`, `transaction_ref`
  * Actual money exchanges linked to an invoice.

### Services & Facilities
* **Service** — `service_id (PK)`, `service_name`, `category`, `price`, `description`
  * Menu of extra services (laundry, room service, etc.).
* **ServiceRequest** — `request_id (PK)`, `reservation_id (FK)`, `service_id (FK)`, `description`, `request_date`, `status`, `handled_by (FK)`
  * Guest requests during a stay; records who handled it and completion status.
* **Facility** — `facility_id (PK)`, `branch_id (FK)`, `facility_name`, `description`, `capacity`, `location`
  * Hotel amenities such as pools or conference rooms.
* **FacilityBooking** — `facility_booking_id (PK)`, `reservation_id (FK)`, `facility_id (FK)`, `booking_date`, `start_date_time`, `end_date_time`
  * Reservations for amenities and facilities.

### Housekeeping & Maintenance
* **RoomTask** — `roomtask_id (PK)`, `room_id (FK, NOT NULL)`, `assigned_employee_id (FK)`, `description`, `assigned_time`, `completed_time`, `status`
  * Housekeeping to-do list assigning staff to clean specific rooms.
* **FacilityTask** — `facilitytask_id (PK)`, `facility_id (FK, NOT NULL)`, `assigned_employee_id (FK)`, `description`, `assigned_time`, `completed_time`, `status`
  * Cleaning/upkeep for non-room areas.
* **RoomMaintenance** — `room_maintenance_id (PK)`, `room_id (FK, NOT NULL)`, `reported_by (FK)`, `assigned_employee_id (FK)`, `report_date`, `priority`, `completion_date`, `description`, `status`
  * Room hardware/repair issues: report, assignment, and completion.
* **FacilityMaintenance** — `facility_maintenance_id (PK)`, `facility_id (FK, NOT NULL)`, `reported_by (FK)`, `assigned_employee_id (FK)`, `report_date`, `priority`, `completion_date`, `description`, `status`
  * Repairs for shared facilities, prioritized and tracked.

### Auditing
* **AuditLog** — `log_id (PK)`, `employee_id (FK)`, `action`, `table_name`, `pk_of_table`, `affected_col`, `action_time`, `old_value`, `new_value`, `IP_address`
  * The "black box" recorder for sensitive actions, ensuring operational transparency.

---

## 🔗 Key Relationships (Foreign Keys)
* `Employee.branch_id → Branch` · `Room.branch_id → Branch` · `Facility.branch_id → Branch`
* `EmployeeCredentials.employee_id → Employee` · `EmployeeCredentials.role_id → Role`
* `GuestCredentials.guest_id → Guest` · `GuestCredentials.role_id → Role`
* `RolePermission.role_id → Role` · `RolePermission.permission_id → Permission`
* `Room.room_type_id → RoomType`
* `RoomAvailability.room_id → Room` · `RoomAvailability.reservation_id → Reservation (nullable)`
* `Reservation.guest_id → Guest`
* `ReservationRoom.reservation_id → Reservation` · `ReservationRoom.room_id → Room`
* `ReservationStatusLog.reservation_id → Reservation` · `ReservationStatusLog.changed_by_employee_id → Employee`
* `Invoice.reservation_id → Reservation` · `Invoice.payer_guest_id → Guest`
* `InvoiceItem.invoice_id → Invoice` · `Payment.invoice_id → Invoice`
* `ServiceRequest.reservation_id → Reservation` · `ServiceRequest.service_id → Service` · `ServiceRequest.handled_by → Employee`
* `FacilityBooking.reservation_id → Reservation` · `FacilityBooking.facility_id → Facility`
* `RoomTask.room_id → Room` · `RoomTask.assigned_employee_id → Employee`
* `FacilityTask.facility_id → Facility` · `FacilityTask.assigned_employee_id → Employee`
* `RoomMaintenance.room_id → Room` · `RoomMaintenance.reported_by / assigned_employee_id → Employee`
* `FacilityMaintenance.facility_id → Facility` · `FacilityMaintenance.reported_by / assigned_employee_id → Employee`
* `AuditLog.employee_id → Employee`

📈 **ER Diagram (Lucidchart):** https://lucid.app/lucidchart/823b5b42-f407-4e7f-960c-308119eee0ad/view

---

## 🔐 Security Design

### Login Authentication
Users log in with a username (or email). Passwords are never stored in plain text — they are hashed with a modern, slow algorithm (bcrypt, Argon2, or PBKDF2). All queries use parameterized statements to prevent SQL injection, and sessions support explicit logout.

### Role-Based Access Control (RBAC)
Access is granted strictly by role. A user's `role_id` maps (through `RolePermission`) to a set of permissions, and the application exposes only the views and actions those permissions allow.

### Data Isolation
Branch isolation is enforced with Row-Level Security (RLS) at the database layer, or via strict Data Access Objects (DAOs) in the backend, so that (for example) a receptionist only ever sees data for their own branch.

### Audit Logging
Every sensitive action is written to `AuditLog`. This table is **append-only** — `UPDATE` and `DELETE` permissions are revoked for all database users so the record cannot be tampered with.

### Backup & Recovery
Regular automated backups and a tested restore procedure protect against data loss and corruption.

---

## 👥 Roles

| # | Role | Branch Access | Description |
|---|------|---------------|-------------|
| 1 | System Administrator | All branches | Oversees entire system configuration and security. |
| 2 | Branch Manager | Own branch | Oversees branch operations, occupancy, and reports. |
| 3 | Front Desk Receptionist | Own branch | Manages guest registrations and reservations. |
| 4 | Housekeeping Staff | Own branch | Manages room cleaning and status updates. |
| 5 | Maintenance Staff | Own branch | Manages room repairs and facility maintenance. |
| 6 | Restaurant / Room Service Staff | Own branch | Manages food orders and room service. |
| 7 | Sales Executive | All branches | Handles corporate bookings and promotions. |
| 8 | Accountant / Cashier | Own branch | Processes payments and financial records. |
| 9 | Hotel Owner / Regional Director | All branches | Monitors cross-branch performance and reports. |
| 10 | Guest | N/A | Manages personal profile and bookings. |

### RBAC Access Matrix

| # | Role | Table / Data Access | Cannot Do |
|---|------|--------------------|-----------|
| 1 | System Administrator | Users, Roles, Permissions, Branches, Employees, Guests, Reservations, Rooms, Invoices, Services, Maintenance, Housekeeping, Audit Logs | Perform hotel operations (cleaning rooms, checking guests in) |
| 2 | Branch Manager | Employees, Rooms, Reservations, Guests, Bills, Maintenance, Housekeeping, Service Requests, Reports | View other branches; change RBAC; create admins |
| 3 | Front Desk Receptionist | Guests, Reservations, Rooms, Payments, Invoices, Service Requests | Employee salaries; other branches; audit logs; housekeeping/maintenance schedules |
| 4 | Housekeeping Staff | Assigned rooms, cleaning schedule, housekeeping tasks | Guest payments; employee info; reservations |
| 5 | Maintenance Staff | Maintenance requests, rooms, equipment | Reservations; guests; payments |
| 6 | Restaurant / Room Service Staff | Room service orders, guest room number | Guest personal info; payments; reservations |
| 7 | Sales Executive | Corporate customers, group reservations, promotional packages | Employee info; housekeeping; maintenance; audit logs |
| 8 | Accountant / Cashier | Payments, invoices, reservation charges, taxes | Employee roles; housekeeping; maintenance |
| 9 | Hotel Owner / Regional Director | Reports, revenue, reservations, employees, guests | Modify daily operations; assign cleaning tasks |
| 10 | Guest | Own reservations, own invoices, own profile | Other guests' data; hotel operations; staff info |

---

## 🔑 Permission Catalog (35 Permissions)

| ID | Permission | Module | Description |
|----|-----------|--------|-------------|
| 1 | VIEW_GUEST | Guest | View guest information |
| 2 | CREATE_GUEST | Guest | Register a new guest |
| 3 | UPDATE_GUEST | Guest | Edit guest information |
| 4 | DELETE_GUEST | Guest | Remove guest record |
| 5 | VIEW_RESERVATION | Reservation | View reservations |
| 6 | CREATE_RESERVATION | Reservation | Create a reservation |
| 7 | UPDATE_RESERVATION | Reservation | Modify reservation |
| 8 | CANCEL_RESERVATION | Reservation | Cancel reservation |
| 9 | CHECK_IN | Reservation | Check guest in |
| 10 | CHECK_OUT | Reservation | Check guest out |
| 11 | VIEW_ROOM | Room | View room details |
| 12 | UPDATE_ROOM_STATUS | Room | Change room status |
| 13 | VIEW_PAYMENT | Payment | View payment records |
| 14 | PROCESS_PAYMENT | Payment | Record a payment |
| 15 | ISSUE_REFUND | Payment | Refund a payment |
| 16 | VIEW_INVOICE | Invoice | View invoices |
| 17 | CREATE_INVOICE | Invoice | Generate invoices |
| 18 | VIEW_SERVICE_REQUEST | Service | View service requests |
| 19 | CREATE_SERVICE_REQUEST | Service | Create service requests |
| 20 | UPDATE_SERVICE_REQUEST | Service | Update service request status |
| 21 | VIEW_HOUSEKEEPING_TASK | Housekeeping | View cleaning tasks |
| 22 | ASSIGN_HOUSEKEEPING_TASK | Housekeeping | Assign cleaning tasks |
| 23 | COMPLETE_HOUSEKEEPING_TASK | Housekeeping | Mark cleaning complete |
| 24 | VIEW_MAINTENANCE | Maintenance | View maintenance requests |
| 25 | CREATE_MAINTENANCE | Maintenance | Report maintenance issue |
| 26 | UPDATE_MAINTENANCE | Maintenance | Update maintenance status |
| 27 | VIEW_EMPLOYEE | Employee | View employee records |
| 28 | CREATE_EMPLOYEE | Employee | Add employee |
| 29 | UPDATE_EMPLOYEE | Employee | Edit employee |
| 30 | DELETE_EMPLOYEE | Employee | Remove employee |
| 31 | VIEW_REPORT | Report | View reports |
| 32 | GENERATE_REPORT | Report | Generate reports |
| 33 | MANAGE_USERS | Security | Create/update user accounts |
| 34 | MANAGE_ROLES | Security | Assign roles |
| 35 | VIEW_AUDIT_LOG | Security | View audit logs |
