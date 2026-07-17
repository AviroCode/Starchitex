# Starchitex — Multi-Branch Hotel Management System

Our database course term project. Starchitex is a centralized PostgreSQL database for a hotel chain with multiple branches — one shared database instead of each branch keeping its own copies of everything. It covers reservations, check-in/check-out, billing, service requests, housekeeping, maintenance, role-based access control, and audit logging, with virtually all of that business logic enforced **inside the database** via triggers, stored procedures, `CHECK` constraints, and native Row-Level Security ,  not just in application code.

On top of the database, this repo also includes a full working Spring Boot + React application (three separate consoles - Guest Portal, Staff Console, Admin Console) that exercises every piece of the schema for real. See **[Testing Guide](#-testing-guide-for-instructors)** below for exactly how to drive it.

Team:
- Aung Kaung Thar (6780844) — database implementation, backend and frontend 
- Elbin Ye Htet Naing (6781209) — RBAC & security design and check the relations and features 
- Min Linn Khant (6780839) — testing/QA, deployment, monitoring and frontend 

A full narrative report (business context, ER diagrams, normalization walkthrough, data dictionary, advanced queries/triggers, challenges) can see below .

## Repository layout

- `backend/src/main/resources/schema.sql` — the entire schema: tables, constraints, triggers, stored procedures, views, and RLS policies, in dependency order.
- `database/seed/seed_data.sql` — the minimal **production** bootstrap (fixed RBAC taxonomy + one branch + one admin login). This is what a real deploy applies.
- `database/seed/demo_data.sql` — a **local-only** rich demo dataset (extra branch, rooms, staff, guests, live reservations) that gives something to click on immediately. Never used in production — see below.
- `database/tests/*.sql` — the automated test suite (integrity constraints, full workflow lifecycles, housekeeping/maintenance, audit logging, RLS isolation). Each file prints its own PASS/FAIL lines.
- `backend/` — Spring Boot 4 API (raw JDBC via `JdbcTemplate`, no ORM — every query is explicit SQL).
- `frontend/` — React 18 + Vite, three role-driven consoles under `/guest/*`, `/staff/*`, `/admin/*`.
- `Documentation.md` — a running, dated log of every architectural decision and why it was made.

## Quickstart (Docker — recommended for grading)

Requires Docker + Docker Compose. From the repo root:

```bash
cp .env.example .env   # if present; otherwise create .env with POSTGRES_PASSWORD and JWT_SECRET set
docker compose up -d --build
```

This starts three containers:
- **Postgres** on `localhost:5433` — self-initializes on first run: `schema.sql`, then `seed_data.sql`, then `demo_data.sql` (in that order, via `docker-entrypoint-initdb.d`), so you get a fully populated database with zero manual steps.
- **Backend** (Spring Boot) on `localhost:8080`
- **Frontend** (nginx serving the built React app) on **`localhost:3000`** ← open this in a browser

To reset to a clean state (re-run all three init scripts from scratch):
```bash
docker compose down -v && docker compose up -d --build
```

## Rebuilding the database from scratch (no Docker)

```bash
psql "$DATABASE_URL" -f backend/src/main/resources/schema.sql
psql "$DATABASE_URL" -f database/seed/seed_data.sql
# Optional — only for local testing/demos, never in production:
psql "$DATABASE_URL" -f database/seed/demo_data.sql
```

## Running the tests

```bash
for f in database/tests/*.sql; do psql "$DATABASE_URL" -f "$f"; done
```

Or, against the Docker Postgres container directly:
```bash
for f in database/tests/*.sql; do docker exec -i starchitex-postgres psql -U starchitex_user -d starchitex -f - < "$f"; done
```

Each test prints its own PASS/FAIL lines, so the output is readable on its own. The suite covers things like: double-booking gets rejected, invoices have to add up, checkout can't come before check-in, maintenance tickets block booking, cancellation fees post automatically within 24h of check-in, the audit log can't be edited, and each staff role can only do what its permissions allow (including not seeing other branches' data).

---

## Testing Guide

Everything below assumes the Docker Quickstart above (`localhost:3000`) with the demo dataset loaded — no manual data entry required. Every login uses the password **`demo1234`**.

### Logins to use

| Login | Role | Where it lands |
|---|---|---|
| `admin.sys` | System Administrator (all branches) | Admin Console |
| `owner.hq` | Hotel Owner (all branches) | Admin Console |
| `manager.bkk` | Branch Manager (Main Branch only) | Staff Console |
| `reception.bkk` | Front Desk Receptionist (Main Branch only) | Staff Console |
| `finance.riv` | Finance Manager (Riverside branch only) | Staff Console |
| `demo.guest` | Guest | Guest Portal |

Go to `http://localhost:3000/login` to sign in with any of the above, or `http://localhost:3000/register` to create a brand-new guest account from scratch.

### 1. Guest self-registration and booking (Guest Portal)
1. `http://localhost:3000/register` — create a new guest account (first/last name, email, phone, password). You're logged straight in.
2. You land on `/guest/book` — pick dates, pick a room, and note the **confirm dialog** that appears before anything is actually booked (nothing books on the first click).
3. `/guest/reservations` and `/guest/invoices` show only *your own* bookings — this is Row-Level Security at work, not an application-layer filter (see §5 below).

### 2. Staff booking, housekeeping, and the checkout→cleaning chain
1. Log in as `reception.bkk` → `/staff/reservations`. You'll see **Kenji Tanaka's** reservation, currently `Checked In` in room 102.
2. Click **"Check out"**. Behind the scenes, `trg_mark_room_dirty_on_checkout` fires: room 102 flips to `Dirty` and a "Post-checkout cleaning" task is auto-created.
3. Go to `/staff/rooms` — room 102 now shows a **Dirty** badge.
4. Go to `/staff/housekeeping` — the auto-created task is sitting there. Mark it **Completed**; room 102 flips back to **Clean** (`trg_mark_room_clean_on_task_complete`).

### 3. Maintenance blocks booking
1. Still as `reception.bkk` (or any staff), open `/staff/housekeeping` — room 201 at the **Riverside** branch already has an open maintenance ticket ("AC unit not cooling").
2. Try to book that room (as `demo.guest` on `/guest/book`, branch = Riverside, or via the staff Reservations form) — the booking is **rejected** by `trg_prevent_booking_maintenance_room`, and the room shows "Out of Service" in the UI before you even try.

### 4. Cancellation fee within 24 hours of check-in
1. Log in as `reception.bkk` → `/staff/reservations`. Find **Li Wei's** reservation (`Confirmed`, checking in tomorrow) — it already has an unpaid invoice.
2. Click **"Cancel"** — the confirm dialog explicitly warns you this is within the 24h window.
3. Go to `/staff/billing`, open Li Wei's invoice — a new **Fee** line item (one night's rate) has been posted automatically by `trg_enforce_cancellation_policy`.
4. For contrast: cancel **Demo Guest's** far-future Suite reservation (`Pending`, 10 days out) the same way — no fee gets added.

### 5. Service request → invoice auto-posting
1. As `reception.bkk`, open `/staff/service-requests` — Li Wei has a `Pending` Breakfast request.
2. Mark it **Completed**. Open `/staff/billing` on Li Wei's invoice again — the breakfast charge appears as a new line item with no manual entry (`trg_auto_post_completed_service_request`).

### 6. Row-Level Security / branch isolation
1. Log in as `reception.bkk` (Main Branch only) → `/staff/reservations`. You will **not** see Demo Guest's Riverside reservation.
2. Log out, log in as `finance.riv` (Riverside only) → you'll see the Riverside reservation, but **not** Main Branch's.
3. Log in as `admin.sys` or `owner.hq` (cross-branch roles) → you see everything from both branches.
4. This isolation is enforced by PostgreSQL itself (`CREATE POLICY` + session variables), not by the application filtering results — see `database/tests/06_rls_isolation.sql` for the automated version of this exact check.

### 7. Analytics (real numbers, not hardcoded)
1. Log in as `admin.sys` → `/admin/analytics`. Occupancy/ADR/RevPAR are computed live from `Reservation`/`RoomAvailability`/`Invoice` data.
2. The Monthly Revenue table reads from a **materialized view** (`MonthlyRevenueReport`) refreshed nightly at 2 AM — after checking someone out and taking a payment (per §2 above), that revenue will show up **the next time the view refreshes**, not instantly; this is a deliberate cache trade-off, explained in `Documentation.md`.

### 8. Simulated "sign in with organization Google"
1. On `http://localhost:3000/login`, click **"Sign in with organization Google"**.
2. Enter `admin.sys@starchitex.com` (the seeded admin's email — matches the default `starchitex.com` org domain) — you're logged in with **no password check at all**.
3. This is explicitly a simulation (no real Google OAuth project exists) — see `Documentation.md`'s Phase 16 for exactly what a real integration would add.

### 9. Refund tracking
1. On any fully-paid invoice, if you later add a cancellation fee or discount that drops the total below what's already been paid, `/staff/billing` shows a **"Refund due"** banner with a **"Mark Refunded"** button — this only *records* that staff processed a refund outside the app (no real payment gateway exists to reverse a charge through).

---

##  Database Design Architecture
This project designs a robust, enterprise-grade relational database for a multi-branch Hotel Management System. It supports the full hotel operation: room bookings, facility reservations, multi-department task assignment (housekeeping / maintenance), secure split billing, and a strict Role-Based Access Control (RBAC) security model.

The database is normalized to Third Normal Form (3NF), enforces referential integrity through mandatory foreign keys, and isolates data per branch so that staff only ever see the location they belong to.

---

## Entity Reference (26 Entities)

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
* **Room** — `room_id (PK)`, `room_number`, `floor`, `branch_id (FK)`, `room_type_id (FK)`, `housekeeping_status`
  * Individual physical rooms; the foundation of inventory. `housekeeping_status` (Clean/Dirty) is auto-managed by triggers on checkout and task completion.
* **RoomAvailability** — `availability_id (PK)`, `room_id (FK)`, `calendar_date`, `status`, `reservation_id (FK, NULLABLE)`, `price_override`
  * Day-by-day inventory calendar; answers availability queries without scanning full reservation history and allows blocking rooms for maintenance.

### Reservations
* **Reservation** — `reservation_id (PK)`, `branch_id (FK)`, `guest_id (FK)`, `check_in_date`, `check_out_date`, `actual_checkin_time`, `actual_checkout_time`, `booking_date`, `num_of_guests`, `status`, `special_requests`
  * The booking contract: dates and status of a guest's stay.
* **ReservationRoom** — `reservation_id (FK)`, `room_id (FK)`, `PRIMARY KEY (reservation_id, room_id)`
  * Junction connecting reservations to specific rooms; supports multi-room bookings.
* **ReservationStatusLog** — `log_id (PK)`, `reservation_id (FK)`, `status`, `changed_by_employee_id (FK)`, `action_time`, `remarks`
  * Audit trail of the booking life-cycle; tracks each status change and the employee responsible (survives shift changes).

### Billing
* **Invoice** — `invoice_id (PK)`, `reservation_id (FK)`, `payer_guest_id (FK)`, `invoice_date`, `sub_total`, `tax_amount`, `discount`, `total_amount`, `status`
  * The primary bill; `payer_guest_id` identifies who pays and supports split billing.
* **InvoiceItem** — `invoice_item_id (PK)`, `invoice_id (FK)`, `item_type`, `quantity`, `amount`
  * Line items (room charge, service fee, damage, cancellation fee, etc.).
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
  * Room hardware/repair issues: report, assignment, and completion. An open ticket blocks new bookings on that room.
* **FacilityMaintenance** — `facility_maintenance_id (PK)`, `facility_id (FK, NOT NULL)`, `reported_by (FK)`, `assigned_employee_id (FK)`, `report_date`, `priority`, `completion_date`, `description`, `status`
  * Repairs for shared facilities, prioritized and tracked.

### Auditing
* **AuditLog** — `log_id (PK)`, `employee_id (FK)`, `action`, `table_name`, `pk_of_table`, `affected_col`, `action_time`, `old_value`, `new_value`
  * The "black box" recorder for sensitive actions, ensuring operational transparency.

---

## 🔗 Key Relationships (Foreign Keys)
* `Employee.branch_id → Branch` · `Room.branch_id → Branch` · `Facility.branch_id → Branch` · `Reservation.branch_id → Branch`
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

 **ER Diagrams (Lucidchart, editable):**
- Conceptual (major entities): https://lucid.app/lucidchart/3d1b3318-7870-4a4a-a655-82433e1291ce/edit
- Full logical schema (all 26 tables): https://lucid.app/lucidchart/1f8f624d-995c-4d15-b6d1-78503add5c50/edit

---

##  Security Design

### Login Authentication
Users log in with a username (or email). Passwords are never stored in plain text — they are hashed with BCrypt. All queries use parameterized statements (`JdbcTemplate` with `?` placeholders throughout) to prevent SQL injection, and JWT sessions are stateless with explicit expiry.

### Role-Based Access Control (RBAC)
Access is granted strictly by role. A user's `role_id` maps (through `RolePermission`) to a set of permissions, and the application exposes only the views and actions those permissions allow.

### Data Isolation
Branch isolation is enforced with native PostgreSQL Row-Level Security (RLS) — `schema.sql` defines 24 `CREATE POLICY` rules across 19 `FORCE ROW LEVEL SECURITY` tables, keyed off session variables (`app.current_branch_id`, `app.current_guest_id`, `app.is_super_admin`) that the backend sets per-connection (`RlsDataSource.java`). This means a receptionist only ever sees data for their own branch even if an application-layer check is ever missed, and guests get a read-only carve-out on `Room`/`Branch`/`Facility` so they can browse and book across the chain. `@PreAuthorize` checks in the backend are defense-in-depth on top of this, not the primary enforcement mechanism.

### Audit Logging
Every sensitive action is written to `AuditLog`. This table is **append-only** at the RLS-policy level — no `UPDATE`/`DELETE` policy exists, so with `FORCE ROW LEVEL SECURITY` those operations are denied to everyone, including the table owner.

### Backup & Recovery
Regular automated backups and a tested restore procedure protect against data loss and corruption.

---

## 👥 Roles

These are the canonical 10 roles, seeded exactly as-is by `database/seed/seed_data.sql` (the `@PreAuthorize` checks in the backend match these role names literally).

| # | Role | Branch Access | Description |
|---|------|---------------|-------------|
| 1 | System Administrator | All branches | Full system access across all branches. |
| 2 | Hotel Owner | All branches | Strategic oversight; cross-branch read/write. |
| 3 | Sales Executive | All branches | Cross-branch reservations and guest management. |
| 4 | Branch Manager | Own branch | Full management of own branch. |
| 5 | Front Desk Receptionist | Own branch | Check-in/out, room assignment, guest lookup at own branch. |
| 6 | Housekeeping Staff | Own branch | Room tasks and maintenance at own branch. |
| 7 | Maintenance Technician | Own branch | Facility and room maintenance at own branch. |
| 8 | Finance Manager | Own branch | Invoice and payment management at own branch. |
| 9 | HR Manager | Own branch | Employee management at own branch. |
| 10 | Guest | N/A | Self-service: view own reservations and invoices. |

### RBAC Access Matrix

Derived directly from the `RolePermission` rows in `database/seed/seed_data.sql`.

| # | Role | Permissions Granted | Table / Data Access |
|---|------|---------------------|----------------------|
| 1 | System Administrator | All 11 permissions | Everything — all branches, all tables |
| 2 | Hotel Owner | VIEW_ALL_BRANCHES, MANAGE_EMPLOYEES, MANAGE_ROOMS, MANAGE_RESERVATIONS, VIEW_INVOICES, MANAGE_INVOICES, VIEW_GUESTS, MANAGE_GUESTS, VIEW_AUDIT_LOGS | Employees, Rooms, Reservations, Invoices, Guests, Audit Logs — all branches |
| 3 | Sales Executive | VIEW_ALL_BRANCHES, MANAGE_RESERVATIONS, VIEW_INVOICES, VIEW_GUESTS, MANAGE_GUESTS | Reservations, Invoices (read), Guests — all branches |
| 4 | Branch Manager | MANAGE_EMPLOYEES, MANAGE_ROOMS, MANAGE_RESERVATIONS, VIEW_INVOICES, MANAGE_INVOICES, VIEW_GUESTS, MANAGE_GUESTS, VIEW_AUDIT_LOGS, MANAGE_TASKS | Employees, Rooms, Reservations, Invoices, Guests, Audit Logs, Tasks — own branch only |
| 5 | Front Desk Receptionist | MANAGE_ROOMS, MANAGE_RESERVATIONS, VIEW_INVOICES, MANAGE_INVOICES, VIEW_GUESTS, MANAGE_GUESTS | Rooms, Reservations, Invoices, Guests — own branch only |
| 6 | Housekeeping Staff | MANAGE_TASKS | Room/Facility housekeeping tasks — own branch only |
| 7 | Maintenance Technician | MANAGE_TASKS | Room/Facility maintenance tasks — own branch only |
| 8 | Finance Manager | VIEW_INVOICES, MANAGE_INVOICES | Invoices, Payments — own branch only |
| 9 | HR Manager | MANAGE_EMPLOYEES, VIEW_GUESTS | Employees — own branch only; Guests (read) |
| 10 | Guest | VIEW_OWN_RESERVATION | Own reservations and invoices only |

---

##  Permission Catalog (11 Permissions)

Matches `database/seed/seed_data.sql` exactly.

| ID | Permission | Description |
|----|-----------|-------------|
| 1 | VIEW_ALL_BRANCHES | Read data from any branch |
| 2 | MANAGE_EMPLOYEES | Create and update employee records |
| 3 | MANAGE_ROOMS | Create and update room records |
| 4 | MANAGE_RESERVATIONS | Create, confirm, check-in, check-out reservations |
| 5 | VIEW_INVOICES | Read invoice records |
| 6 | MANAGE_INVOICES | Create invoice items and process payments |
| 7 | VIEW_GUESTS | Read guest profile data |
| 8 | MANAGE_GUESTS | Create and update guest profiles |
| 9 | VIEW_OWN_RESERVATION | Guest self-service: read own reservations |
| 10 | VIEW_AUDIT_LOGS | Read audit log entries |
| 11 | MANAGE_TASKS | Create and update room/facility tasks |
