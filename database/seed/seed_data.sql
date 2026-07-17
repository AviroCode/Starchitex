-- =============================================================================
-- Starchitex Hotel Management System — Production Bootstrap Seed
-- Targets backend/src/main/resources/schema.sql (the RLS-enabled schema).
-- Role names here MUST exactly match the strings in @PreAuthorize annotations.
--
-- This is intentionally minimal: fixed RBAC taxonomy (Role/Permission) plus
-- exactly one Branch and one System Administrator login, so a fresh
-- deployment starts empty rather than full of demo data. Log in as
-- admin.sys, then use the admin UI to add real branches, room types, rooms
-- (Catalog page), employees, and guests.
--
-- Change the admin.sys password after first deploy — there is no in-app
-- password-change flow yet, so this has to be done at the DB level (update
-- EmployeeCredentials.password_hash with a fresh BCrypt hash).
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

-- ---------- Branch (1 — a starting point, edit via the Branches admin page) ----------
INSERT INTO Branch (branch_id, name, address, city, province, postal_code, email, phone, status) VALUES
 (1,'Main Branch','','','','','contact@example.com','', 'Active')
ON CONFLICT (branch_id) DO NOTHING;

-- ---------- Bootstrap admin (password 'demo1234' — rotate after first deploy) ----------
-- Email domain matches the default app.staff-google-domain (STAFF_GOOGLE_DOMAIN
-- env var) so this account can also demo the simulated Google sign-in path.
INSERT INTO Employee (employee_id, branch_id, first_name, last_name, position, gender, date_of_birth, phone, email, hire_date, salary, employment_status) VALUES
 (1,1,'System','Administrator','System Administrator','Other','2000-01-01','','admin.sys@starchitex.com',CURRENT_DATE,0,'Active')
ON CONFLICT (employee_id) DO NOTHING;

INSERT INTO EmployeeCredentials (employee_id, username, password_hash, role_id, last_login) VALUES
 (1,'admin.sys','$2a$06$lZ2t6pA1BxbLMCGpy0Mhf.8Y8P/8pAf990iiAuJKRg3aYFFuixMVm',1, NULL)
ON CONFLICT (employee_id) DO NOTHING;

-- ---------- Advance every sequence past the explicit IDs above ----------
-- (Required because SERIAL PKs were bypassed with explicit values; without
-- this, the app's first real INSERT via the API would collide on nextval().)
SELECT setval('branch_branch_id_seq', (SELECT COALESCE(MAX(branch_id), 1) FROM Branch));
SELECT setval('role_role_id_seq', (SELECT COALESCE(MAX(role_id), 1) FROM Role));
SELECT setval('permission_permission_id_seq', (SELECT COALESCE(MAX(permission_id), 1) FROM Permission));
SELECT setval('employee_employee_id_seq', (SELECT COALESCE(MAX(employee_id), 1) FROM Employee));

COMMIT;
