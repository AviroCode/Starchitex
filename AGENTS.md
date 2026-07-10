# 🤖 AI Agent Guidelines & Rules (Starchitex)

This file contains strict technical boundaries and context required for any AI Agent working on this codebase.

## 🛑 Rule 1: NO Object-Relational Mapping (ORM)
The user has explicitly forbidden the use of ORM tools like **Hibernate** or **JPA**. 
* You **MUST** handle the database structure manually. 
* All database interactions in the Spring Boot backend must be done using raw SQL queries via **Spring JDBC (`JdbcTemplate`)**.
* Do not write `@Entity`, `@Table`, or extend `JpaRepository`. Use standard `@Repository` classes with injected `JdbcTemplate`.

## 📚 Rule 2: Database Schema Context
The database represents a complex Hotel Management System (26 tables normalized to 3NF). 
When writing manual SQL queries, you must adhere to the following strict relationships:

### Core Tables
* **Branch**: `branch_id (PK)`
* **Employee**: `employee_id (PK)`, `branch_id (FK)`
* **Guest**: `guest_id (PK)`
* **Room**: `room_id (PK)`, `branch_id (FK)`, `room_type_id (FK)`
* **Reservation**: `reservation_id (PK)`, `guest_id (FK)`

### Advanced Real-World Features (Must Support)
1. **Split Billing:** `Invoice` has a `payer_guest_id` to allow multiple guests in one room to pay separately.
2. **Shift Tracking:** Do not put `check_in_by` on the `Reservation` table. Use the `ReservationStatusLog` table (a state machine tracking status changes across employee shifts).
3. **Task Integrity:** Tasks are strictly separated into `RoomTask`, `FacilityTask`, `RoomMaintenance`, and `FacilityMaintenance` to ensure 100% NOT NULL foreign keys pointing exactly to the physical location of the task.
4. **Availability Calendar:** Do not query reservations to find available rooms. Query the `RoomAvailability` table, which serves as a day-by-day inventory calendar.

## 🔒 Rule 3: Security & RBAC
* **Authentication:** Passwords must be hashed (bcrypt/Argon2). Guests use `GuestCredentials` and staff use `EmployeeCredentials`.
* **Data Isolation:** All backend queries should conceptually support Row-Level Security / Branch Isolation (e.g., `WHERE branch_id = ?`).
* **Auditing:** Sensitive `INSERT`/`UPDATE`/`DELETE` actions should trigger a log entry in the `AuditLog` table.

## 📝 Rule 4: Documentation Log
You must ALWAYS append a concrete summary explanation of what you did to the `Documentation.md` file at the end of every task or feature implementation. Do not overwrite previous logs, append a new section detailing your exact modifications.
