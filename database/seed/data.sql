-- =============================================================================
-- Starchitex Hotel Management System — Canonical Seed Data
-- Role names here MUST exactly match the strings in @PreAuthorize annotations.
-- =============================================================================

-- Roles (10 canonical roles)
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

-- Permissions
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

-- RolePermission mappings
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
