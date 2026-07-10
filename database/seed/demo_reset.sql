-- ============================================================
-- Demo reset: removes anything created DURING a demo run and
-- restores the demo anchors. Safe to run repeatedly.
--   psql "$DATABASE_URL" -f demo_reset.sql
-- Seeded data (reservation_id <= 14, invoice_id <= 10, etc.) is untouched.
-- ============================================================
BEGIN;

-- demo-created payments/invoices (anything beyond the seeded IDs)
DELETE FROM payment      WHERE payment_id > 12;
DELETE FROM invoice_item WHERE invoice_id > 10;
DELETE FROM invoice      WHERE invoice_id > 10;

-- demo-created service/facility activity
DELETE FROM service_request  WHERE request_id > 12;
DELETE FROM facility_booking WHERE facility_booking_id > 10;

-- demo-created reservations (availability rows release via trigger/cascade)
DELETE FROM room_availability WHERE reservation_id > 14;
DELETE FROM reservation_status_log WHERE reservation_id > 14;
DELETE FROM reservation_room  WHERE reservation_id > 14;
DELETE FROM reservation       WHERE reservation_id > 14;

-- demo-created guests/tasks/maintenance beyond seed
DELETE FROM guest_credentials WHERE guest_cred_id > 12;
DELETE FROM guest             WHERE guest_id > 12;
DELETE FROM room_task         WHERE roomtask_id > 10;
DELETE FROM room_maintenance  WHERE room_maintenance_id > 10;

-- restore demo room 4 to pristine
UPDATE room SET housekeeping_status = 'Clean' WHERE room_id = 4;
UPDATE room_availability SET status = 'Available', reservation_id = NULL
WHERE room_id = 4 AND status <> 'Available';

-- realign sequences with the seeded maxima
SELECT setval('reservation_reservation_id_seq', GREATEST((SELECT max(reservation_id) FROM reservation), 14));
SELECT setval('invoice_invoice_id_seq',         GREATEST((SELECT max(invoice_id) FROM invoice), 10));
SELECT setval('payment_payment_id_seq',         GREATEST((SELECT max(payment_id) FROM payment), 12));
SELECT setval('guest_guest_id_seq',             GREATEST((SELECT max(guest_id) FROM guest), 12));

COMMIT;
SELECT 'demo reset complete' AS status;
