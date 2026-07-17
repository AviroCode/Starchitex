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

## DB-First Refactor — Invoice Status Trigger (Phase 6)

Continuing the DB-first transition, the logic for updating the invoice status based on payments has been migrated to the database:

- **New trigger `trg_update_invoice_status_on_payment` (AFTER INSERT OR DELETE ON `Payment`)**: The function `update_invoice_status_on_payment()` is triggered after any payment mutation. It calculates the total amount paid so far for the associated invoice and dynamically updates the invoice `status` to `'Paid'`, `'Partially Paid'`, or `'Unpaid'`. 
- **`PaymentService` simplification**: The manual update to `Invoice.status` within Java has been fully removed. This guarantees that `Invoice.status` stays consistent regardless of how payments are entered (e.g. via direct script or other interfaces), closing the silent staleness loop.

## DB-First Refactor — Invoice Recalculation Trigger (Phase 7)

The logic for recalculating invoice totals (`sub_total`, `tax_amount`, `total_amount`) when line items change has been migrated to the database:

- **New trigger `trg_recalculate_invoice_total_on_item_change` (AFTER INSERT OR UPDATE OR DELETE ON `InvoiceItem`)**: This trigger automatically invokes the existing `calculate_invoice_total(invoice_id)` stored procedure whenever an invoice item is mutated.
- **`InvoiceItemService` simplification**: The manual wiring of `InvoiceService` and explicit calls to `recalculateInvoice()` have been removed from the Java layer. The database now natively guarantees that an invoice's totals stay perfectly synchronized with its underlying line items without requiring app-level coordination.

## DB-First Refactor — Reservation State Machine Trigger (Phase 8)

The reservation status state machine logic has been completely migrated from the Java layer into the database layer:

- **New trigger `trg_enforce_reservation_state_machine` (BEFORE UPDATE ON `Reservation`)**: This trigger acts as a strict state machine validator. It inspects `OLD.status` and `NEW.status` and raises a `check_violation` exception for any illegal transitions. The allowed paths are strictly enforced (`Pending` → `Confirmed` → `Checked In` → `Checked Out`). Cancelled and Checked Out are enforced as terminal states.
- **`ReservationService` simplification**: All four transition methods (`confirm`, `checkIn`, `checkOut`, `cancel`) have had their ad-hoc `if (!res.status().equals(...))` guard clauses removed. The Java layer simply attempts the status update and relies on the PostgreSQL trigger to block illegal state transitions.

## DB-First Refactor — PostgreSQL Row-Level Security (Phase 9)

The most significant architectural shift to a database-first model: moving multi-tenant (branch) data isolation completely out of the application layer into native PostgreSQL Row-Level Security (RLS). This fulfills the project's core promise of database-level security and makes isolation entirely bypass-proof.

- **`schema.sql` (RLS Configuration)**:
  - Enabled and forced `ROW LEVEL SECURITY` on all tenant-specific tables (`Branch`, `Employee`, `Room`, `Reservation`, `Invoice`, `Payment`, `RoomTask`, etc.).
  - Added `CREATE POLICY` statements that read PostgreSQL session variables (`app.current_branch_id`, `app.current_guest_id`, `app.is_super_admin`) to dynamically filter rows. A branch employee querying `SELECT * FROM Room` will now organically only receive rows matching their `branch_id`, without any explicit `WHERE` clause from the Java backend.
- **`RlsDataSource` & `DataSourceConfig`**:
  - Implemented a dynamic connection proxy (`RlsDataSource.java`) wrapped around the default HikariCP pool.
  - Intercepts `getConnection()` to extract the current user's security context (from Spring Security) and executes `SET app.current_branch_id = X` directly on the physical PostgreSQL connection.
  - Intercepts `Connection.close()` to issue `RESET` commands, securely scrubbing the tenant context before the connection is returned to the Hikari pool to prevent cross-contamination.
- **Controller `@PreAuthorize` Cleanup**:
  - With PostgreSQL enforcing isolation universally at the lowest level, all redundant SpEL checks (e.g., `#branchId == authentication.principal.branchId`) have been removed from `RoomController`, `ReservationController`, `EmployeeController`, and `ReservationRoomController`.

## DB-First Refactor — Cancel-Time Cleanup Trigger (Phase 10)

The logic for cleaning up assigned rooms when a reservation is cancelled has been moved from the Java layer to a database trigger.

- **New trigger `trg_cleanup_on_reservation_cancel` (AFTER UPDATE ON `Reservation`)**: This trigger fires when a reservation status changes to `Cancelled`. It automatically deletes the associated `ReservationRoom` records. This deletion then natively cascades to the pre-existing `trg_sync_room_availability` trigger, which correctly frees up the `RoomAvailability` calendar slots.
- **`ReservationService` Simplification**: The explicit call to `reservationRoomRepository.deleteByReservationId(reservationId)` inside the `cancel()` method has been removed. The database is now entirely responsible for ensuring that cancelled reservations don't hold onto rooms, regardless of whether the cancellation comes from the API or a direct SQL script.

## DB-First Refactor — Guest Anonymization & Extended Audit Logging (Phase 11)

To support GDPR requirements and broaden the system's observability directly at the data layer, we added stored procedures and extended the audit triggers.

- **Guest Anonymization (GDPR)**:
  - Added the stored procedure `anonymize_guest(guest_id)`.
  - Instead of performing a hard `DELETE` (which violates foreign key constraints on `Reservation` and financial history), this procedure nullifies all Personally Identifiable Information (PII) on the `Guest` record.
  - It automatically revokes access by deleting the associated `GuestCredentials`.
- **Extended Audit Logging**:
  - `trg_invoice_audit`: Logs updates to `Invoice` statuses and deletions.
  - `trg_payment_audit`: Logs deletions of `Payment` records (since payments are immutable, there is no update trigger).
  - `trg_service_request_audit`: Logs cancellations and deletions of `ServiceRequest` records.
  - This ensures comprehensive, un-bypassable auditing for the core financial and operational entities, directly to the `AuditLog` table.

## Bug Fixes, RLS Completion & Authorization Sweep (Phase 12)

Two bugs from Phase 9-11 would have broken on first real execution, plus the RLS rollout left some gaps. All were caught by actually running `schema.sql` against a throwaway Postgres 16 container (via Docker) with `ON_ERROR_STOP=1`, instead of just reading the SQL — the same discipline is recommended before every future schema change.

- **Fixed: RLS policies referencing a nonexistent column.** `RoomTask`, `FacilityTask`, `RoomMaintenance`, `FacilityMaintenance`, and `FacilityBooking` don't have a `branch_id` column, but Phase 9's policies for them assumed one — `CREATE POLICY ... USING (branch_id = current_branch_id())` failed at apply time with `column "branch_id" does not exist`. Since those tables already had RLS `ENABLE`d and `FORCE`d, a failed policy meant deny-all: the entire housekeeping/maintenance/facility-booking module would have returned zero rows for everyone, including admins. Rewrote each policy to derive branch via the table's real FK (`Room.branch_id` or `Facility.branch_id`) through an `EXISTS` subquery.
- **Fixed: wrong column name in `log_payment_audit()`.** Phase 11 added `OLD.amount_paid`, but `Payment`'s real column is `amount`. Every `DELETE` on `Payment` would have thrown `record "old" has no field "amount_paid"` and rolled back — payments would have become permanently un-deletable. Corrected to `OLD.amount`.
- **Fixed: `AuditLog` RLS would have silently blocked every audit trigger.** The original Phase 12 draft gave `AuditLog` only a `SELECT` policy (super-admin only) after `ENABLE`/`FORCE ROW LEVEL SECURITY`. Since the audit triggers (`log_reservation_audit`, `log_invoice_audit`, `log_payment_audit`, `log_service_request_audit`) run `INSERT`s in the same session as whatever staff/guest action triggered them, and there was no policy permitting `INSERT`, those inserts would have been silently rejected for every non-super-admin session — i.e. audit logging would have appeared to work in testing (as super-admin) and then quietly stopped recording anything for real staff/guest activity. Added `CREATE POLICY audit_log_insert ON AuditLog FOR INSERT WITH CHECK (true)` so writes are always allowed while reads stay super-admin-only.
- **Closed RLS gaps**:
  - Guests previously resolved to `current_branch_id() = NULL` with no super-admin flag, so `room_isolation`/`branch_isolation` filtered out every row — a guest could never browse rooms or branches to make a booking. Added `room_guest_read`/`branch_guest_read` `FOR SELECT` policies permitting any authenticated guest session to read (not write) `Room` and `Branch`.
  - `Facility` had no RLS at all. Added `facility_isolation` (staff, own branch) mirroring `room_isolation`, plus the same guest-read carve-out (`facility_guest_read`) so guests can browse spa/pool/conference rooms to book `FacilityBooking`.
  - `InvoiceItem`, `ServiceRequest`, `ReservationStatusLog` had no RLS. Added policies mirroring the existing `invoice_isolation`/`payment_isolation` pattern (scoped via their `reservation_id` → `Reservation.branch_id`/`guest_id`).
  - `Guest` had no RLS, and `GuestController.getGuestById` had been loosened at the app layer to allow any staff member (any branch) to read any guest's full PII by ID with nothing backstopping it at the DB layer. Added `guest_isolation`: any staff member (any branch, since guest directories are realistically chain-wide in a hotel PMS) or the guest themself. `GuestController`'s checks are now defense-in-depth on top of this, not the only gate.
  - `AuditLog` had no RLS at all despite being the most security-sensitive table in the schema. Added read access restricted to super-admin roles only (see the insert-policy note above).
- **Verified against a real database, not just read through.** Spun up Postgres 16 in Docker, ran the full `schema.sql` with `ON_ERROR_STOP=1` (zero errors), then created a non-superuser role (Postgres superusers bypass RLS entirely, so testing as `postgres` would have proven nothing) and exercised 6 concrete scenarios: branch-1 staff seeing only branch-1 `Room` rows, a guest session seeing all rooms, a super-admin seeing everything, a non-admin cancelling a reservation and the audit trigger still successfully writing a row, a non-admin correctly getting 0 rows from `AuditLog`, an admin correctly reading that same row, and branch-2 staff correctly unable to see branch-1's `InvoiceItem`. All passed.
- **Authorization sweep — `@PreAuthorize` added to controllers that had none**: `RolePermissionController` (admin-only — this endpoint assigns/revokes permissions on roles), `BranchController` (admin-only — branches are chain infrastructure), `AuditLogController` (admin-only, matching the new `AuditLog` RLS policy), `EmployeeCredentialsController` and `GuestCredentialsController` (self-or-admin for password/login endpoints — required adding `employeeId` to the security principal, see below), `PaymentController`, `InvoiceItemController`, `FacilityController`, `FacilityBookingController`, `FacilityMaintenanceController`, `FacilityTaskController`, `RoomTaskController`, `RoomMaintenanceController` (all: staff-of-any-branch-or-admin, since the underlying tables are RLS-protected — these checks are defense-in-depth, not the primary gate). `GuestController` was simplified to the same lightweight pattern now that `Guest` RLS is authoritative.
- **`employeeId` added to the security principal** (`CustomUserDetails`, `CustomUserDetailsService`), mirroring the existing `branchId`/`guestId` fields, to support "change your own password" checks on `EmployeeCredentialsController`. This turned out not to require touching `JwtUtil`/`AuthController`: `JwtAuthenticationFilter` re-derives `UserDetails` fresh from the database on every request via `loadUserByUsername(username)`, so `branchId`/`guestId`/`employeeId` were never actually read from JWT claims in the first place — only `username` is. **Known limitation**: `GuestCredentialsController`'s password/login endpoints key off `guestCredId` (the credentials row), not `guestId`, so a clean self-service check would need an extra DB lookup to resolve one to the other; those two endpoints are admin-only for now (`getCredentialsByGuestId`, which does key off the real `guestId`, does get a proper self-or-admin check).
- **README/seed reconciliation**: `README.md`'s Roles table, RBAC Access Matrix, and Permission Catalog were rewritten to exactly match `database/seed/data.sql` (10 roles, 11 permissions) instead of the original aspirational 35-permission catalog that was never actually seeded anywhere in the repo. The Security Design → Data Isolation section was also updated to describe the RLS mechanism that now actually exists, rather than the previous "RLS or strict DAOs" either/or language.

## Follow-up fixes (Phase 13)

Two gaps identified right after Phase 12 shipped:

- **Seed scripts would fail against RLS-protected tables.** With `FORCE ROW LEVEL SECURITY` on every tenant table, a plain `psql -f seed_data.sql` session has no branch/guest/admin context set, so any `INSERT` into `Branch`, `Employee`, `Room`, `Guest`, `Reservation`, etc. is rejected with `new row violates row-level security policy` — reproduced directly against a non-superuser role mirroring what a managed Postgres provider (e.g. Render) actually grants. Fixed by adding `SET app.is_super_admin = 'true';` at the top of `database/seed/data.sql`, with a comment explaining this line is required in any future seed/data-loading script that touches an RLS-protected table.
- **`RoomAvailability` had no RLS at all.** Added `room_availability_isolation` (staff, own branch, derived via `room_id → Room.branch_id` since the table has no `branch_id` of its own) plus `room_availability_guest_read` (guests can browse any branch's calendar to check dates before booking). This needed a deliberately asymmetric `USING`/`WITH CHECK`: a guest cancelling their *own* reservation triggers `trg_cleanup_on_reservation_cancel` → `trg_sync_room_availability` in the *guest's own session*, which has no branch context — so `USING` additionally allows a guest to see rows tied to their own reservation, and `WITH CHECK` is deliberately looser than `USING`, allowing any write that either matches the room's branch OR results in `reservation_id IS NULL` (i.e. *releasing* a room is always safe regardless of who's doing it — the only thing that needs branch-gating is *claiming* one). Verified end-to-end in Docker: booked a room as staff (calendar correctly flipped to `Occupied`), then cancelled that same reservation as the guest with zero branch context, and confirmed the calendar correctly flipped back to `Available` rather than silently failing to update.

## Housekeeping status, maintenance-blocks-booking, and analytics (Phase 14)

A gap analysis against a full real-world front-desk/housekeeping/analytics workflow surfaced several gaps between what the schema already half-supported and what was actually wired up.

- **`Room.housekeeping_status` (`Clean`/`Dirty`)** — new column, deliberately separate from `RoomAvailability.status` (booking occupancy) and from "Out of Service" (derived from open `RoomMaintenance` tickets, not stored). Two new triggers: `trg_mark_room_dirty_on_checkout` (AFTER UPDATE ON `Reservation`, fires when status becomes `Checked Out`) sets every room on that stay to `Dirty` and queues a `RoomTask` (`Post-checkout cleaning`, `Pending`); `trg_mark_room_clean_on_task_complete` (AFTER UPDATE ON `RoomTask`) flips the room back to `Clean` once that task completes.
- **Maintenance now actually blocks booking.** Previously a room with an open `RoomMaintenance` ticket could still be booked — `RoomMaintenanceService` never touched availability at all. New trigger `trg_prevent_booking_maintenance_room` (BEFORE INSERT/UPDATE ON `ReservationRoom`) rejects the link if any non-`Completed` maintenance ticket exists for that room. Frontend defense-in-depth: the guest booking page marks such rooms "Out of Service" and disables the Book button before the guest ever hits the DB rejection.
- **Completed service requests auto-post to the folio.** New trigger `trg_auto_post_completed_service_request` (AFTER UPDATE ON `ServiceRequest`, fires when status becomes `Completed`) looks up the most recent `Invoice` for that reservation and inserts a `Service` `InvoiceItem` if one exists (`amount` gets overwritten by the pre-existing `enforce_invoice_item_price` trigger, same as a manually-added item). No-op if no invoice exists yet — staff still add it manually once they create one.
- **Real Occupancy/ADR/RevPAR analytics.** `MonthlyRevenueReport` (a materialized view) and its nightly `@Scheduled` refresh (`InvoiceService.refreshAnalyticsCache`, 2 AM) already existed but were never exposed — no controller endpoint, no frontend page. New `AnalyticsController` (`/api/analytics/summary`, `/api/analytics/monthly-revenue`) and a new `InvoiceRepository.getAnalyticsSummary()` query computing occupancy rate, ADR, and RevPAR from real `Reservation`/`RoomAvailability`/`Invoice` data (with divide-by-zero guards), surfaced on a new admin `AnalyticsPage.jsx`.
- **CRM duplicate-guest check.** `GuestsPage.jsx` now checks the already-loaded guest list for a matching email/passport before submitting, instead of letting a fresh registration attempt fail as a bare `UNIQUE` violation.
- **`Reservation.special_requests`** (nullable `TEXT`) added end-to-end (model → repository → service → both booking forms), plus a lightweight "Prefer: Any / Low floor / High floor" sort on the guest booking page as an honest, non-automated stand-in for a real room-allocation engine.
- Fixed two pre-existing bugs found while testing this round: `RoomMaintenanceService.createMaintenanceTicket` and `RoomTaskService.createTask` both passed an explicit `null` for `status` whenever the request body omitted it, which overrides the column's `DEFAULT` and trips the `NOT NULL` constraint — every "Log report" / "Add task" click 500'd. Fixed by defaulting to `'Reported'`/`'Pending'` in Java, mirroring the DB default, when the client doesn't supply one.
- Verified against a fresh Docker rebuild: full `database/tests/*.sql` suite passes, including new assertions for the maintenance-blocks-booking rejection and the service-auto-posting no-op/success cases.

## Atomic booking, confirm-before-book UX, and cancellation policy (Phase 15)

- **Booking is now one transaction, not two.** `guest/BookRoomPage.jsx` and `ReservationsPage.jsx` used to call `POST /api/reservations` then a *separate* `POST /api/reservation-rooms` — if the second call was rejected (double-booked or maintenance-blocked room), the first left a dangling `Pending` reservation with no room ever attached. New `ReservationService.bookRoom(BookingRequestDTO)` (`@Transactional`) creates the reservation and assigns the room in one transaction via the new `POST /api/reservations/book`; a trigger rejection on the room assignment now rolls back the reservation insert too. Verified directly: forced both the double-booking and maintenance-blocked rejection paths through this endpoint and confirmed zero orphan `Reservation` rows each time.
- **Confirm-before-you-book.** New reusable `ConfirmDialog.jsx` component; both booking forms now show a review step (room, dates, price, guests, special requests) before firing the atomic booking call, instead of booking instantly on click.
- **Cancellation fee within 24h of check-in.** New trigger `trg_enforce_cancellation_policy` (BEFORE UPDATE ON `Reservation`, fires when status becomes `Cancelled`): if `check_in_date - CURRENT_DATE <= 1` and an `Invoice` already exists for the reservation, posts a `Fee` `InvoiceItem` (a new allowed `chk_invoiceitem_type` value) for one night's rate, summed across every room on the reservation. This is a *fee gate*, not a booking block — cancellation itself stays always allowed, matching the existing state machine. Must run BEFORE the row update (not AFTER, like the service-auto-post trigger) so it still sees the `ReservationRoom` links that `trg_cleanup_on_reservation_cancel` (an AFTER trigger) is about to delete.
- **Closing the loop on `Invoice.status = 'Refunded'`** — a value the CHECK constraint always allowed but nothing ever set. New `POST /api/invoices/{id}/mark-refunded` and a refund banner on `BillingPage.jsx` (shown when `sum(payments) > total_amount`) that calls it. This only *records* that staff processed a refund outside the app — there's no real payment gateway integration to reverse a charge through, matching the scope boundary established in the Phase 14 gap analysis.
- **Rooms can now actually be created from the UI.** `POST /api/rooms` already existed and worked; nothing in the frontend ever called it (`RoomsPage.jsx` is a read-only key-rack display, `CatalogPage.jsx` only created `RoomType`/`Service`). Added a "New room" form + table to `CatalogPage.jsx`.
- **`database/seed/seed_data.sql` trimmed to a production bootstrap.** Previously shipped 3 branches, 10 rooms, 9 fake staff, 6 fake guests, 8 reservations, invoices, and payments. Now ships only the fixed RBAC taxonomy (`Role`/`Permission`/`RolePermission` — reference data, not demo content), one placeholder `Branch`, and one `System Administrator` login (`admin.sys` / `demo1234`, with a comment to rotate the password at the DB level after first deploy since there's no in-app change-password flow yet). Everything else — rooms, room types, guests, reservations, invoices — starts empty; the admin logs in and builds it via the UI (including the new Rooms form above, without which this trim would have stranded a fresh deployment with no way to add physical rooms at all).
- Verified against a fresh Docker rebuild from the trimmed seed: `admin.sys` logs in, every other old demo login is gone, full `database/tests/*.sql` suite passes (including new cancellation-fee assertions — one confirming the fee posts within the 24h window, one confirming it doesn't 30 days out).

## Guest self-registration and simulated staff Google SSO (Phase 16)

Two account-creation gaps: guests previously had no way to create their own login (`GuestsPage.jsx` only ever created a `Guest` profile row, staff-side, never a `GuestCredentials` login — the only guest account that ever existed was one hardcoded demo login in seed data), and staff login was username/password only.

**The constraint that shaped this**: every route requires an authenticated JWT (`SecurityConfig`'s `anyRequest().authenticated()` — only `/api/auth/**` and `/error` are public), and RLS scoping (`RlsDataSource`) is driven entirely by the `CustomUserDetails` principal on `SecurityContextHolder`. There was no path for a genuinely anonymous request to write anything, not even a new `Guest` row. Both new flows solve this the same way: a narrow, purpose-built public endpoint under `/api/auth/**` that issues `SET app.is_super_admin = 'true'` as the *first statement* of an `@Transactional` method — the exact pattern already trusted throughout `database/seed/seed_data.sql` and every `database/tests/*.sql` script — does exactly one scoped write or read, then mints a normal JWT via the existing `JwtUtil`. This is **not** a blanket RLS bypass: each method only ever touches data keyed to what the caller themselves supplied in the request body (their own new guest record, or an email they typed in to look themselves up), and the elevated session variable only survives for that one pinned connection/transaction (`RlsConnectionInvocationHandler` resets it on `close()`, same as every other request). Every screen reached *after* the JWT is minted — Book a Room, My Reservations, etc. — is completely unchanged and stays fully RLS-scoped, because from that point on it's just an ordinary session like any other.

- **`POST /api/auth/register-guest`** (new `AuthService.registerGuest`): inserts a `Guest` (`GuestRepository.saveReturningId`, new method — `first_name`/`last_name` are the only `NOT NULL` columns, so this is a light form: name, email, phone, password, not the full staff-entered KYC form) plus a `GuestCredentials` row (password hashed via the existing `PasswordEncoder` bean, reusing `GuestCredentialsService.createCredentials`), then returns a JWT — auto-login, no separate sign-in step. New public `/register` route (`RegisterPage.jsx`), linked from `LoginPage.jsx`.
- **`POST /api/auth/google-login`** (new `AuthService.googleLogin`) — **explicitly simulated**, not real OAuth2/OIDC: no Google Cloud project, no redirect, no signed ID-token verification exists. A client asserts an email; the backend checks it against a configurable `app.staff-google-domain` property (`STAFF_GOOGLE_DOMAIN` env var, defaults to `starchitex.com`), looks up the matching `Employee` (new `EmployeeRepository.findByEmail`), and — if that employee already has an `EmployeeCredentials` row (still provisioned exactly as today via `EmployeesPage.jsx`) — mints a JWT with **no password check at all**. Staff are still provisioned the same way; this only replaces the password step for whoever's email matches the org domain. Real integration would add `spring-security-oauth2-client`, a registered redirect URI, and verification of Google's signed ID token in place of trusting the raw request body — everything is isolated to this one method so that swap wouldn't touch anything else. New "Sign in with organization Google" button on `LoginPage.jsx` opens a modal explicitly labeled "Simulated" so it's never mistaken for the real thing.
- Anonymous booking (book with no account at all, retrieve later via a confirmation code) was considered and deliberately dropped from scope — every booking now requires signing in or registering first.
- Verified: registered a new guest end to end and confirmed auto-login into the Guest Portal; simulated a Google login with a domain-matching `Employee.email` and confirmed it logs in with no password; confirmed both a non-matching domain and a matching-domain employee with no `EmployeeCredentials` row are rejected; full `database/tests/*.sql` suite still passes (this phase touches no schema/triggers, only new application-layer endpoints).
