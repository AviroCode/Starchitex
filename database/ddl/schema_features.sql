-- ============================================================
-- Starchitex database features (merged from backend/schema.sql)
-- Runs ADDITIVELY on the deployed v3 database — safe on live data:
--   psql "$DATABASE_URL" -f schema_features.sql
--
-- Contains Aung's four features, adapted to schema v3:
--  1. log_reservation_audit trigger  (FIXED: satisfies chk_audit_one_actor)
--  2. calculate_invoice_total()      (FIXED: sums amount, not qty*amount)
--  3. MonthlyRevenueReport MV        (ENHANCED: per-branch via reservation.branch_id)
--  4. AvailableRoomsToday view + indexes
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. Automated audit logging for reservation cancel/delete
-- v3's audit_log requires EXACTLY ONE actor (employee XOR guest).
-- A trigger can't know the actor by itself, so we read it from
-- session variables the application (or demo script) sets:
--   SET app.employee_id = '4';   -- or: SET app.guest_id = '12';
-- If neither is set, we attribute to employee 1 (System Administrator)
-- as the system actor, so the trigger NEVER violates the constraint.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION log_reservation_audit()
RETURNS trigger AS $$
DECLARE
  v_emp INT := NULLIF(current_setting('app.employee_id', true), '')::INT;
  v_guest INT := NULLIF(current_setting('app.guest_id', true), '')::INT;
BEGIN
  IF v_emp IS NULL AND v_guest IS NULL THEN
    v_emp := 1;  -- system actor fallback (admin.sys)
  ELSIF v_emp IS NOT NULL AND v_guest IS NOT NULL THEN
    v_guest := NULL;  -- one actor only; employee wins if both set
  END IF;

  IF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log (employee_id, guest_id, action, table_name, pk_of_table,
                           affected_col, old_value, new_value, IP_address)
    VALUES (v_emp, v_guest, 'DELETE', 'reservation', OLD.reservation_id::text,
            '*', 'status=' || OLD.status, '', coalesce(current_setting('app.ip', true), 'db-internal'));
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' AND NEW.status = 'Cancelled' AND OLD.status IS DISTINCT FROM 'Cancelled' THEN
    INSERT INTO audit_log (employee_id, guest_id, action, table_name, pk_of_table,
                           affected_col, old_value, new_value, IP_address)
    VALUES (v_emp, v_guest, 'UPDATE', 'reservation', NEW.reservation_id::text,
            'status', OLD.status, 'Cancelled', coalesce(current_setting('app.ip', true), 'db-internal'));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_reservation_audit ON reservation;
CREATE TRIGGER trg_reservation_audit
  BEFORE UPDATE OR DELETE ON reservation
  FOR EACH ROW EXECUTE FUNCTION log_reservation_audit();

-- ------------------------------------------------------------
-- 2. Invoice total calculation
-- invoice_item.amount is ALREADY the line total (chk_item_math:
-- amount = quantity * unit_price), so we sum amount — summing
-- quantity*amount would double-count. 7% tax, discount respected,
-- result always satisfies chk_invoice_math by construction.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_invoice_total(p_invoice_id INT)
RETURNS void AS $$
DECLARE
  v_sub  DECIMAL(10,2);
  v_tax  DECIMAL(10,2);
  v_disc DECIMAL(10,2);
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO v_sub
  FROM invoice_item WHERE invoice_id = p_invoice_id;

  SELECT COALESCE(discount, 0) INTO v_disc
  FROM invoice WHERE invoice_id = p_invoice_id;

  v_tax := ROUND(v_sub * 0.07, 2);

  UPDATE invoice
  SET sub_total = v_sub,
      tax_amount = v_tax,
      total_amount = v_sub + v_tax - v_disc
  WHERE invoice_id = p_invoice_id;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 3. Monthly revenue materialized view (per branch — heavy query
-- cached to disk; refresh nightly or on demand)
-- ------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS MonthlyRevenueReport;
CREATE MATERIALIZED VIEW MonthlyRevenueReport AS
SELECT
  b.branch_id,
  b.name AS branch_name,
  EXTRACT(YEAR  FROM i.invoice_date)::INT AS year,
  EXTRACT(MONTH FROM i.invoice_date)::INT AS month,
  COUNT(i.invoice_id)          AS invoice_count,
  SUM(i.total_amount)          AS total_revenue
FROM invoice i
JOIN reservation r ON r.reservation_id = i.reservation_id
JOIN branch b      ON b.branch_id = r.branch_id
WHERE i.status <> 'Cancelled'
GROUP BY b.branch_id, b.name, year, month
ORDER BY year, month, b.branch_id;

-- ------------------------------------------------------------
-- 4. AvailableRoomsToday view + indexes
-- A room is bookable today when: no calendar row blocks today
-- (Occupied/Reserved/Under Maintenance) AND housekeeping says
-- it's presentable (Clean or Inspected).
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW AvailableRoomsToday AS
SELECT
  ro.room_id, ro.room_number, ro.floor,
  b.branch_id, b.name AS branch_name,
  rt.type_name, rt.base_price, rt.capacity,
  ro.housekeeping_status
FROM room ro
JOIN branch b    ON b.branch_id = ro.branch_id
JOIN room_type rt ON rt.room_type_id = ro.room_type_id
WHERE ro.housekeeping_status IN ('Clean', 'Inspected')
  AND NOT EXISTS (
    SELECT 1 FROM room_availability ra
    WHERE ra.room_id = ro.room_id
      AND ra.calendar_date = CURRENT_DATE
      AND ra.status IN ('Occupied', 'Reserved', 'Under Maintenance')
  );

CREATE INDEX IF NOT EXISTS idx_guest_email ON guest (email);
CREATE INDEX IF NOT EXISTS idx_reservation_dates ON reservation (check_in_date, check_out_date);
CREATE INDEX IF NOT EXISTS idx_availability_room_date ON room_availability (room_id, calendar_date);

COMMIT;
