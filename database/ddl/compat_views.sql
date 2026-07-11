-- ============================================================
-- Compatibility views: the Java backend uses CamelCase table
-- names (EmployeeCredentials -> folds to employeecredentials);
-- the deployed schema uses snake_case (employee_credentials).
-- These simple views alias every multi-word table so ALL backend
-- queries work unchanged. Simple views are auto-updatable in
-- PostgreSQL, so INSERT/UPDATE pass through too.
--   psql "$DATABASE_URL" -f compat_views.sql
-- ============================================================
BEGIN;
CREATE OR REPLACE VIEW employeecredentials    AS SELECT * FROM employee_credentials;
CREATE OR REPLACE VIEW guestcredentials       AS SELECT * FROM guest_credentials;
CREATE OR REPLACE VIEW rolepermission         AS SELECT * FROM role_permission;
CREATE OR REPLACE VIEW roomtype               AS SELECT * FROM room_type;
CREATE OR REPLACE VIEW reservationroom        AS SELECT * FROM reservation_room;
CREATE OR REPLACE VIEW roomavailability       AS SELECT * FROM room_availability;
CREATE OR REPLACE VIEW reservationstatuslog   AS SELECT * FROM reservation_status_log;
CREATE OR REPLACE VIEW invoiceitem            AS SELECT * FROM invoice_item;
CREATE OR REPLACE VIEW servicerequest         AS SELECT * FROM service_request;
CREATE OR REPLACE VIEW facilitybooking        AS SELECT * FROM facility_booking;
CREATE OR REPLACE VIEW roomtask               AS SELECT * FROM room_task;
CREATE OR REPLACE VIEW facilitytask           AS SELECT * FROM facility_task;
CREATE OR REPLACE VIEW roommaintenance        AS SELECT * FROM room_maintenance;
CREATE OR REPLACE VIEW facilitymaintenance    AS SELECT * FROM facility_maintenance;
CREATE OR REPLACE VIEW auditlog               AS SELECT * FROM audit_log;
COMMIT;
