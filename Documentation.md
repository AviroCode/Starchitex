# Starchitex Database Setup Guide (Render.com)

This guide explains how to set up the PostgreSQL database for the Starchitex backend using a free instance on Render.com.

## 1. Create the Database
1. Go to [Render.com](https://render.com/) and create an account (or sign in).
2. Click **New +** and select **PostgreSQL**.
3. Fill in the details:
   - **Name:** `starchitex-db` (or anything you prefer).
   - **Database:** `starchitex`
   - **User:** `starchitex_user`
   - **Region:** Choose the region closest to you.
   - **Instance Type:** Select the **Free** tier.
4. Click **Create Database**.

## 2. Get Your Credentials
Once the database is created, you will be taken to its dashboard. Look for the **Connections** section. You need to extract three things from the **External Database URL**.

The URL will look something like this:
`postgres://starchitex_user:SECRET_PASSWORD@dpg-cxxxxxxxxx-a.oregon-postgres.render.com/starchitex`

**Extract your details:**
- **Username:** `starchitex_user`
- **Password:** `SECRET_PASSWORD`
- **Host/URL:** `dpg-cxxxxxxxxx-a.oregon-postgres.render.com/starchitex`

## 3. Configure the Spring Boot Backend
1. In the `/backend` folder of this project, create a new file named `.env`.
2. Copy the contents of `.env.example` into your new `.env` file.
3. Replace the placeholder values with your real Render.com credentials. Make sure to keep the `jdbc:postgresql://` prefix for the URL!

It should look like this:
```env
DB_URL=jdbc:postgresql://dpg-cxxxxxxxxx-a.oregon-postgres.render.com/starchitex
DB_USERNAME=starchitex_user
DB_PASSWORD=SECRET_PASSWORD
```

## 4. Run the App
Your Spring Boot application is now configured to automatically read these environment variables and connect to the remote database when it boots up!

---

## 🛠️ Development Changelog

### Phase 1: Infrastructure & Data Modeling (Completed)
- **Initialized Spring Boot Backend (App Server):** Scaffolded a Maven project configured strictly for `spring-boot-starter-data-jdbc` (Zero-ORM).
- **Initialized PostgreSQL Database (DB Server):** Drafted `schema.sql` implementing all 26 tables in 3NF and configured Spring Boot to automatically initialize the tables on startup.
- **Implemented Domain Models:** Created Java Records for all 26 entities in the `model` package to act as clean, immutable data carriers for raw SQL mapping.
- **Configured 3-Tier Docker Orchestration:** Set up a `docker-compose.yml` defining three fully isolated servers: `db` (Postgres on port 5433), `backend` (Spring Boot App Server on port 8080), and `frontend` (NGINX Web Server on port 3000).
- **Frontend Scaffolded (Web Server):** Initialized an independent NGINX web server to serve static UI assets, ensuring strict separation of concerns from the App Server.

### Phase 2: Core Business Logic (Vertical Slicing)
- **Branch Vertical Slice:** Implemented the full backend stack for the `Branch` entity without an ORM.
  - **Repository Layer (`BranchRepository`):** Implemented `JdbcTemplate` with a custom `RowMapper` to manually execute `SELECT * FROM Branch`.
  - **Service Layer (`BranchService`):** Created the intermediate business logic layer.
  - **Controller Layer (`BranchController`):** Exposed REST APIs (`GET /api/branches`, `GET /api/branches/{id}`, `POST /api/branches`, and `PUT /api/branches/{id}`).
- **Guest Vertical Slice:** Implemented data access, temporal logic, and API endpoints for the `Guest` entity.
  - **Repository Layer (`GuestRepository`):** Mapped standard `DATE` to `LocalDate` and `TIMESTAMP` to `LocalDateTime` using custom JDBC mappings, writing raw INSERT, UPDATE, and SELECT statements.
  - **Service Layer (`GuestService`):** Wired transactional data access.
  - **Controller Layer (`GuestController`):** Exposed REST endpoints at `/api/guests` supporting HTTP GET, POST, and PUT operations.
- **RoomType Vertical Slice:** Implemented data access, decimal logic, and API endpoints for the `RoomType` entity.
  - **Repository Layer (`RoomTypeRepository`):** Managed currency/pricing calculations using `BigDecimal` column mapping to prevent float precision errors.
  - **Service Layer (`RoomTypeService`):** Exposed basic business logic wrappers.
  - **Controller Layer (`RoomTypeController`):** Exposed REST endpoints at `/api/room-types` mapping GET, POST, and PUT HTTP queries.
- **Service Vertical Slice:** Implemented data access, decimal logic, and API endpoints for the `Service` entity (amenities).
  - **Repository Layer (`ServiceRepository`):** Mapped PostgreSQL decimal types directly to `BigDecimal` for zero precision loss.
  - **Service Layer (`ServiceService`):** Implemented core data validation wrappers.
  - **Controller Layer (`ServiceController`):** Exposed REST endpoints at `/api/services` supporting GET, POST, and PUT queries.
- **Role Vertical Slice:** Implemented data access and API endpoints for the `Role` entity (system roles).
  - **Repository Layer (`RoleRepository`):** Implemented standard CRUD operations via `JdbcTemplate`.
  - **Service Layer (`RoleService`):** Implemented core business logic wrappers.
  - **Controller Layer (`RoleController`):** Exposed REST endpoints at `/api/roles` supporting GET, POST, and PUT operations.
- **Permission Vertical Slice:** Implemented data access and API endpoints for the `Permission` entity (system permissions).
  - **Repository Layer (`PermissionRepository`):** Implemented standard CRUD operations via `JdbcTemplate`.
  - **Service Layer (`PermissionService`):** Implemented core business logic wrappers.
  - **Controller Layer (`PermissionController`):** Exposed REST endpoints at `/api/permissions` supporting GET, POST, and PUT operations.
- **RolePermission Vertical Slice:** Implemented many-to-many relationship mapping between Role and Permission.
  - **Repository Layer (`RolePermissionRepository`):** Mapped standard joint operations and lookup queries using `JdbcTemplate`.
  - **Service Layer (`RolePermissionService`):** Exposed assign/revoke logic wrappers.
  - **Controller Layer (`RolePermissionController`):** Exposed endpoints at `/api/role-permissions` mapping assignment operations.
- **Facility Vertical Slice:** Implemented data access, branch isolation, and API endpoints for Branch Facilities.
  - **Repository Layer (`FacilityRepository`):** Implemented JDBC CRUD with support for filtering by `branch_id`.
  - **Service Layer (`FacilityService`):** Implemented business logic layers.
  - **Controller Layer (`FacilityController`):** Exposed endpoints at `/api/facilities` (supporting branch filters).
- **Room Vertical Slice:** Implemented data access, branch isolation, and API endpoints for Hotel Rooms.
  - **Repository Layer (`RoomRepository`):** Implemented JDBC CRUD with support for filtering by `branch_id`.
  - **Service Layer (`RoomService`):** Implemented business logic layers.
  - **Controller Layer (`RoomController`):** Exposed endpoints at `/api/rooms` (supporting branch filters).
- **Employee Vertical Slice:** Implemented data access, temporal logic, decimal logic, and API endpoints for Hotel Staff.
  - **Repository Layer (`EmployeeRepository`):** Mapped `salary` to `BigDecimal` and `date_of_birth`/`hire_date` to `LocalDate` with raw SQL mappings and support for filtering by `branch_id`.
  - **Service Layer (`EmployeeService`):** Implemented staff business rules.
  - **Controller Layer (`EmployeeController`):** Exposed endpoints at `/api/employees` (supporting branch filters).
- **EmployeeCredentials Vertical Slice:** Implemented authentication layer data access and API endpoints for Hotel Staff.
  - **Repository Layer (`EmployeeCredentialsRepository`):** Mapped `created_at` and `last_login` to `LocalDateTime` and supported password update and login timestamp actions.
  - **Service Layer (`EmployeeCredentialsService`):** Implemented core logic wrappers for credential actions.
  - **Controller Layer (`EmployeeCredentialsController`):** Exposed endpoints at `/api/employee-credentials`.
- **GuestCredentials Vertical Slice:** Implemented authentication layer data access and API endpoints for Hotel Guests.
  - **Repository Layer (`GuestCredentialsRepository`):** Mapped `created_at` and `last_login` to `LocalDateTime` and supported password update and login timestamp actions.
  - **Service Layer (`GuestCredentialsService`):** Implemented core logic wrappers for credential actions.
  - **Controller Layer (`GuestCredentialsController`):** Exposed endpoints at `/api/guest-credentials`.
- **Reservation Vertical Slice:** Implemented data access, temporal logic, and API endpoints for the core reservation state.
  - **Repository Layer (`ReservationRepository`):** Mapped `DATE` columns to `LocalDate` and `TIMESTAMP` to `LocalDateTime` using raw JDBC mappers.
  - **Service Layer (`ReservationService`):** Implemented logic to manage hotel bookings.
  - **Controller Layer (`ReservationController`):** Exposed endpoints at `/api/reservations`.
- **AuditLog Vertical Slice:** Implemented data access and API endpoints for action auditing.
  - **Repository Layer (`AuditLogRepository`):** Implemented CRUD operations mapping `action_time` to `LocalDateTime`.
  - **Service Layer (`AuditLogService`):** Implemented business logic wrappers for log viewing and writing.
  - **Controller Layer (`AuditLogController`):** Exposed read/write endpoints at `/api/audit-logs`.
- **Level 3 Dependency (Group 4) Vertical Slices:** Implemented full architectural stacks (Repository, Service, Controller) for the 10 remaining complex entities.
  - **Phase 1 (Reservation Operations):**
    - `ReservationRoom`: Mapped Many-to-Many logic between Reservations and Rooms.
    - `ReservationStatusLog`: Tracked reservation state machine transitions (`action_time` mapped to `LocalDateTime`).
  - **Phase 2 (Financials & Availability):**
    - `RoomAvailability`: Engineered daily availability calendar (`calendar_date` mapped to `LocalDate`, `price_override` mapped to `BigDecimal`).
    - `Invoice`: Managed split billing and core financials mapping zero-precision-loss `BigDecimal`s.
  - **Phase 3 (Guest Services):**
    - `ServiceRequest`: Managed requests for hotel amenities (`request_date` mapped to `LocalDateTime`).
    - `FacilityBooking`: Engineered timeslot logic for facility rentals (`start_date_time`, `end_date_time` mapped to `LocalDateTime`).
  - **Phase 4 (Maintenance & Operations):**
    - `RoomTask` & `FacilityTask`: Implemented housekeeping logic assigning employees to standard tasks.
    - `RoomMaintenance` & `FacilityMaintenance`: Configured ticketing system tracking maintenance reports (`report_date` mapped to `LocalDateTime`).
- **Level 4 Dependency (Group 5) Vertical Slices:** Implemented full architectural stacks (Repository, Service, Controller) for the final 2 entities.
  - `InvoiceItem`: Managed line items for an invoice, mapping `amount` to `BigDecimal` for zero precision loss.
  - `Payment`: Tracked payment transactions against an invoice, mapping `amount` to `BigDecimal` and `payment_date` to `LocalDateTime`.

### Security Layer (RBAC & JWT)
- **Dependencies:** Added `spring-boot-starter-security` and `jjwt` (Java JWT).
- **Password Hashing:** Updated `EmployeeCredentialsService` and `GuestCredentialsService` to inject `PasswordEncoder` (BCrypt) ensuring all plain-text passwords are securely hashed upon creation or update.
- **Authentication:** Created `AuthController` exposing `/api/auth/login` to authenticate users and issue JWTs.
- **Authorization:** 
  - Implemented `JwtAuthenticationFilter` to intercept requests and validate tokens in the `Authorization: Bearer` header.
  - Built `CustomUserDetailsService` to dynamically link roles to database permissions using `RolePermissionRepository`. This seamlessly injects permissions (e.g., `CREATE_RESERVATION`) into the Spring Security Context, enabling the use of `@PreAuthorize` on Controller endpoints.
- **Configuration:** Added `SecurityConfig` to disable CSRF, enforce stateless sessions, and manage the filter chain.

### Database-Level Security (SQL GRANTs)
- **Script Creation:** Created [db_security_grants.sql](file:///Users/aviro/Documents/MUIC%20/T6/Database%20/Starchitex/backend/src/main/resources/db_security_grants.sql) to be executed by a PostgreSQL Superuser.
- **Backend Service Account:** Defined `starchitex_backend` with CRUD privileges but revoked schema modification (e.g., `DROP TABLE`) to protect against catastrophic SQL injection.
- **Data Analytics Team:** Defined `starchitex_analyst` as a read-only role (`SELECT` only) on operational tables. Revoked access to `EmployeeCredentials` and `GuestCredentials` to prevent data leaks.
- **Automated Backups:** Defined `starchitex_backup` as a read-only role across all tables, strictly prohibiting any write operations.
### Bug Fixes
- **Resolved Import Collision in `ServiceService`:**
  - Fixed a collision between `com.starchitex.backend.model.Service` and `org.springframework.stereotype.Service` by removing the stereotype import and using its fully-qualified annotation name (`@org.springframework.stereotype.Service`) in [ServiceService.java](file:///Users/aviro/Documents/MUIC%20/T6/Database%20/Starchitex/backend/src/main/java/com/starchitex/backend/service/ServiceService.java).


## Feature: Automated Audit Logging (PL/pgSQL Trigger)
- **What was done:** Added a PostgreSQL Stored Procedure and Trigger to `schema.sql`.
- **Details:** 
  - Created `log_reservation_audit()` PL/pgSQL function.
  - Attached it via `trg_reservation_audit` trigger to the `Reservation` table.
  - This trigger automatically detects when a reservation is `DELETE`d or its status is `UPDATE`d to `CANCELLED`, and automatically inserts a record into the `AuditLog` table without requiring any Java backend intervention.

## Feature: Financial Calculation Stored Procedure (PL/pgSQL)
- **What was done:** Added a standalone PostgreSQL Stored Procedure to `schema.sql`.
- **Details:**
  - Created `calculate_invoice_total(p_invoice_id INT)` PL/pgSQL function.
  - This function automatically calculates an invoice's `sub_total` (by summing `quantity * amount` from the `InvoiceItem` table), applies a 7% tax rate, factors in the discount, and immediately `UPDATE`s the main `Invoice` table with the new totals.
  - This removes complex financial calculation logic from the Java backend, ensuring 100% data integrity at the database level when finalizing bills.

## Feature: Check Constraints (Data Integrity)
- **What was done:** Added comprehensive `CHECK` constraints to the database schema.
- **Details:**
  - Added constraints to `Reservation` ensuring `check_out_date > check_in_date` and `num_of_guests > 0`.
  - Added constraints to `RoomType` and `Service` ensuring no negative pricing and capacity `> 0`.
  - Added constraints to `FacilityBooking` ensuring chronological start and end times.
  - Added constraints to `Invoice` and `InvoiceItem` strictly enforcing non-negative financial values (e.g. `sub_total >= 0`, `quantity > 0`).
  - These constraints mathematically prevent invalid, corrupt, or illogical data from ever being inserted into the system, regardless of application logic bugs.

## Feature: Materialized Views (Data Analytics)
- **What was done:** Implemented a Materialized View for high-performance financial reporting.
- **Details:**
  - Created `MonthlyRevenueReport` Materialized View using `EXTRACT(YEAR...)`, `EXTRACT(MONTH...)`, `COUNT()`, and `SUM()` aggregation.
  - This caches the heavy grouped math onto the disk.
  - Created `MonthlyRevenueDTO.java` and added the corresponding fetch query in `InvoiceRepository.java`.
  - **Auto-Refresh:** Configured Spring Boot `@EnableScheduling` and created a `@Scheduled` cron job in `InvoiceService.java` that executes `REFRESH MATERIALIZED VIEW MonthlyRevenueReport;` every night at 2:00 AM, ensuring the analytics data stays up-to-date without blocking standard application traffic.
## Feature: Advanced Database Concepts (Views, Indexes, Transactions)
- **What was done:** Implemented 3 key enterprise database architectures.
- **Details:**
  - **Views:** Created `AvailableRoomsToday` SQL View in `schema.sql` to abstract a complex 3-table JOIN. Updated Java `RoomRepository` to query this view seamlessly using a new `AvailableRoomDTO`.
  - **Indexes:** Created `idx_guest_email` and `idx_reservation_dates` indexes in `schema.sql` to optimize B-Tree lookups on frequently queried columns, drastically improving read speeds.
  - **Transactions (TCL):** Integrated `@Transactional` from Spring Framework into `InvoiceService.java`. This guarantees atomicity (ACID compliance) by wrapping operations in `BEGIN` and `COMMIT` commands, ensuring rollbacks happen if the Java runtime crashes mid-operation.

## Feature: Enterprise Data Integrity (12 Schema Fixes)
- **What was done:** Resolved 12 critical structural vulnerabilities in the database to guarantee real-world operational security and mathematical accuracy.
- **Details:**
  - **Double-Booking Prevention:** Added a PL/pgSQL trigger `prevent_double_booking` to `ReservationRoom` that mathematically blocks overlapping reservations for the same physical room.
  - **Branch Cross-Check:** Added `enforce_branch_consistency` trigger to guarantee a reservation cannot be assigned a room in a different branch.
  - **Reservation Branch ID:** Added `branch_id` to `Reservation` to support real-world workflows where a guest books at a specific branch *before* a physical room is assigned, enabling high-performance Row-Level Security.
  - **Invoice Arithmetic Integrity:** Added a CHECK constraint `chk_invoice_total` to guarantee that `total_amount = GREATEST(0, (sub_total - discount) + tax_amount)`. It is impossible for an invoice total to be mathematically corrupted.
  - **Strict Payment Methods:** Constrained `payment_method` to real-world channels (Cash, Credit Card, Bank Transfer, etc).
  - **Financial Deletion Protection:** Changed `ON DELETE CASCADE` to `ON DELETE RESTRICT` for Guest and Invoice linkages. You cannot delete a guest who owes money or has an invoice history, ensuring strict financial auditing.
  - **Logical Timestamps & Defaults:** Added `DEFAULT` statuses (e.g., `'Pending'`, `'Unpaid'`) across the board, aligned casing with the application testing suite (Title Case), and added checks to guarantee `check_out_time >= check_in_time`.
  - **Performance Indexes:** Created B-Tree indexes on 6 critical Foreign Keys (e.g., `guest_id`, `branch_id`, `reservation_id`) to prevent table-scan performance degradation at scale.

## Backend Security and Business-Logic Remediation (Phase 2)
To secure the Spring Boot backend against race conditions, unauthorized data access, and state-machine violations, the following 9 application-level integrity and security flaws have been fixed:

1. **Booking Availability Lock**: `ReservationService.createReservation()` is now `@Transactional` and throws an error if checkout is before check-in. Note: Real overlap checking relies on the PostgreSQL trigger `prevent_double_booking` when `ReservationRoom` records are inserted.
2. **Reservation Status State Machine**: The generic `PUT /api/reservations/{id}` endpoint was entirely removed. It was replaced with three strict REST endpoints (`POST /api/reservations/{id}/check-in`, `/check-out`, `/cancel`) which automatically apply logic-gated transitions and inject precise server-side timestamps.
3. **Database Financial Validation**: Created `recalculateInvoiceTotal` in `InvoiceRepository`. `InvoiceService` now executes a raw SQL `SELECT calculate_invoice_total(?)` against the DB, enforcing the PostgreSQL server as the ultimate source of truth for invoice mathematics.
4. **Overpayment & Underpayment Protection**: `PaymentService.createPayment` now calculates the total paid against an invoice before persisting the new payment, rejecting any payment that exceeds the `total_amount`.
5. **Invoice Status Automation**: `PaymentService` automatically cascades payment calculations to update the `Invoice` status to `Partially Paid` or `Paid`, ensuring financial consistency without client intervention.
6. **JWT Branch Integration (RLS Context)**: Modified `JwtUtil.java` to bake `branchId` directly into JWT claims upon login. This context persists statelessly across the application.
7. **Custom Spring Security Principal**: Updated `CustomUserDetailsService` to fetch the employee's `branchId` from the database and inject it into a new `CustomUserDetails` object, allowing Spring Security to access the user's branch anywhere in the app.
8. **Endpoint Authorization**: Applied `@PreAuthorize("hasAuthority('ADMIN') or #param.branchId() == authentication.principal.branchId")` directly to the `Employee`, `Room`, and `Reservation` controllers to instantly block cross-branch data manipulation.
9. **Sensitive Field Protection**: Added Jackson `@JsonIgnore` to `passwordHash` inside `EmployeeCredentials` and `salary` inside `Employee`, preventing catastrophic PII/Auth data leaks over REST endpoints.
10. **Audit Log Security**: Removed the `POST /api/audit-logs` endpoint. Clients can no longer arbitrarily spoof audit records; audit generation is now exclusively restricted to internal services and DB triggers.

## Database Schema and Backend Security Hardening (Phase 3)
To resolve remaining data-integrity gaps and resolve vulnerabilities found in the security setup, the following changes were applied:

1. **InvoiceItem Normalization & Custom Charges**: Expanded `InvoiceItem` with nullable `room_id` and `service_id` foreign keys, and a `description` field. We added a PostgreSQL trigger `enforce_invoice_item_price` which calculates the amount based on target room type price or service price for standard charges, but allows custom amounts for `'Damage'`, `'Maintenance'`, and `'Other'` charges.
2. **Actual Check-in/out Constraints (A.11)**: Added a database constraint `chk_reservation_times` verifying that `actual_checkin_time` and `actual_checkout_time` strictly fall inside the reservation's `check_in_date` and `check_out_date` range.
3. **Room Availability Automation**: Authored an SQL trigger `trg_sync_room_availability` on `ReservationRoom`. When rooms are linked or removed from reservations, the `RoomAvailability` calendar is automatically populated with `'Occupied'` or `'Available'` status across the booked date range.
4. **All-Branch Authorization Fix**: Injected `RoleRepository` into `CustomUserDetailsService` to properly load the literal role name and map it to Spring Security roles (e.g. `ROLE_System Administrator`). Replaced broken `hasAuthority('ADMIN')` expressions with `hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive')` to allow all-branch roles access across branches.
5. **GET Endpoint Authorization**: Applied branch-level security rules to all `GET` methods in controllers (e.g., `EmployeeController`, `RoomController`, `ReservationController`, and `GuestController`) to lock down cross-branch reads.
6. **Graceful DB Error Catching**: Wrapped `assignRoomToReservation` in `ReservationRoomController` with a try/catch to return a clean `400 Bad Request` when double-booking triggers fail.
7. **Pessimistic Locking**: Wrapped payment processes with a `FOR UPDATE` query lock inside `InvoiceRepository` (`findByIdForUpdate`) to lock invoice records and protect against concurrent payment race conditions.
8. **Removed Invoice PUT Bypass**: Deleted the arbitrary `PUT /api/invoices/{id}` method to enforce payments as the sole mechanism for updating invoice statuses.


## Backend Bug Fixes — Phase 4 (Post-Audit)

Following an in-depth code audit, five confirmed bugs were identified and resolved:

1. **RBAC Over-Restriction Fixed**: By-ID endpoints (`getEmployeeById`, `getRoomById`, `getReservationById`, `getGuestById`) were incorrectly restricted to senior roles only. They now accept any authenticated branch employee as a fallback. `GET /api/reservations/guest/{guestId}` now also allows a Guest to read their own reservation history. `getAllGuests` intentionally remains senior-role only.
2. **Guest Self-Service via `guestId` Claim**: Added `guestId` field to `CustomUserDetails`. `CustomUserDetailsService` now populates this for guest logins (null for employees), enabling `authentication.principal.guestId` in SpEL expressions.
3. **`calculate_invoice_total()` Now Reachable**: Injected `InvoiceService` into `InvoiceItemService`. Every `createInvoiceItem`, `updateInvoiceItem`, and `deleteInvoiceItem` now calls `invoiceService.recalculateInvoice(invoiceId)`, making the DB stored procedure live through the API.
4. **`Pending → Confirmed` Transition Added**: Added `confirm()` in `ReservationService` and `POST /api/reservations/{id}/confirm` endpoint. The full state machine is now `Pending → Confirmed → Checked In → Checked Out`. Check-in is no longer unreachable.
5. **`cancel()` Now Cleans Up `RoomAvailability`**: `ReservationService.cancel()` calls `reservationRoomRepository.deleteByReservationId()` after status update. This fires `trg_sync_room_availability` on each deleted `ReservationRoom` row, restoring those dates to `'Available'` automatically.
6. **Canonical Role Seed Data Committed**: Created `database/seed/data.sql` with 10 exact `Role` INSERT statements. These are the single source of truth for role name strings used in all Java `@PreAuthorize` expressions.

## DB-First Refactor — Overpayment Trigger (Phase 5)

Per the project's database-first architecture principle, the overpayment/underpayment rejection rule has been moved from Java (`PaymentService`) into the database layer:

- **New trigger `trg_prevent_overpayment` (BEFORE INSERT on `Payment`)**: The function `prevent_overpayment()` acquires a `SELECT ... FOR UPDATE` lock on the target `Invoice` row, sums all existing payments for that invoice, and raises a `check_violation` exception if the new payment would cause the running total to exceed `Invoice.total_amount`. This rule now applies to every writer — the API, a direct `psql` script, or any future service — not just the single Java code path.
- **`PaymentService` simplified**: The redundant Java sum/compare guard and the `getInvoiceByIdForUpdate` row-lock call have been removed. `createPayment` now simply calls `paymentRepository.save()` and lets the trigger enforce the constraint. Invoice status (`Paid` / `Partially Paid`) is still updated in Java after a successful insert, as that remains appropriate app-level logic.
