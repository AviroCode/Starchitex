-- ============================================================
-- Screen-serving functions (per the project spec: "functions
-- that provide the necessary data for each screen").
-- Named fn_* to match the grading example format.
-- Deploy:  psql "$DATABASE_URL" -f screen_functions.sql
-- Each returns a real result you can screenshot for the slides.
-- ============================================================
BEGIN;

-- === LOGIN screen === fn_login_with_username_and_password(user, pass)
-- Returns 0 = success, 1 = bad credentials (mirrors the grader's example).
CREATE OR REPLACE FUNCTION fn_login(p_username VARCHAR, p_password VARCHAR)
RETURNS INT AS $$
DECLARE v_ok BOOLEAN;
BEGIN
  SELECT (password_hash = crypt(p_password, password_hash)) INTO v_ok
  FROM employee_credentials WHERE username = p_username;
  IF v_ok IS TRUE THEN RETURN 0; ELSE RETURN 1; END IF;
END; $$ LANGUAGE plpgsql;

-- === ROOMS screen === fn_available_rooms(branch_id)
-- Feeds the room key-rack: which rooms are bookable at a branch today.
CREATE OR REPLACE FUNCTION fn_available_rooms(p_branch_id INT)
RETURNS TABLE(room_id INT, room_number VARCHAR, floor INT, type_name VARCHAR,
              base_price DECIMAL, housekeeping_status VARCHAR) AS $$
  SELECT r.room_id, r.room_number, r.floor, rt.type_name, rt.base_price, r.housekeeping_status
  FROM room r
  JOIN room_type rt ON rt.room_type_id = r.room_type_id
  WHERE r.branch_id = p_branch_id
    AND r.housekeeping_status IN ('Clean','Inspected')
    AND NOT EXISTS (
      SELECT 1 FROM room_availability ra
      WHERE ra.room_id = r.room_id AND ra.calendar_date = CURRENT_DATE
        AND ra.status IN ('Occupied','Reserved','Under Maintenance'))
  ORDER BY r.room_number;
$$ LANGUAGE sql;

-- === RESERVATIONS screen === fn_branch_reservations(branch_id)
-- Feeds the reservations list, scoped to one branch (branch isolation).
CREATE OR REPLACE FUNCTION fn_branch_reservations(p_branch_id INT)
RETURNS TABLE(reservation_id INT, guest_name TEXT, check_in DATE, check_out DATE,
              guests INT, status VARCHAR) AS $$
  SELECT r.reservation_id, g.first_name || ' ' || g.last_name,
         r.check_in_date, r.check_out_date, r.num_of_guests, r.status
  FROM reservation r
  JOIN guest g ON g.guest_id = r.guest_id
  WHERE r.branch_id = p_branch_id
  ORDER BY r.reservation_id DESC;
$$ LANGUAGE sql;

-- === BILLING screen === fn_guest_folio(invoice_id)
-- Feeds the billing folio: totals + amount paid + balance due.
CREATE OR REPLACE FUNCTION fn_guest_folio(p_invoice_id INT)
RETURNS TABLE(invoice_id INT, payer TEXT, sub_total DECIMAL, tax DECIMAL,
              discount DECIMAL, total DECIMAL, paid DECIMAL, balance DECIMAL, status VARCHAR) AS $$
  SELECT i.invoice_id, g.first_name || ' ' || g.last_name,
         i.sub_total, i.tax_amount, i.discount, i.total_amount,
         COALESCE((SELECT SUM(amount) FROM payment WHERE invoice_id = i.invoice_id), 0),
         i.total_amount - COALESCE((SELECT SUM(amount) FROM payment WHERE invoice_id = i.invoice_id), 0),
         i.status
  FROM invoice i
  JOIN guest g ON g.guest_id = i.payer_guest_id
  WHERE i.invoice_id = p_invoice_id;
$$ LANGUAGE sql;

-- === MANAGER dashboard === fn_branch_revenue(branch_id)
-- Feeds a manager report: monthly revenue for a branch (from the MV).
CREATE OR REPLACE FUNCTION fn_branch_revenue(p_branch_id INT)
RETURNS TABLE(branch_name VARCHAR, year INT, month INT, invoices BIGINT, revenue NUMERIC) AS $$
  SELECT branch_name, year, month, invoice_count, total_revenue
  FROM MonthlyRevenueReport WHERE branch_id = p_branch_id
  ORDER BY year, month;
$$ LANGUAGE sql;

COMMIT;
