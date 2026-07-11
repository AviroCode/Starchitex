-- fn_branch_reservations(branch_id) -> TABLE
-- Serves: RESERVATIONS screen. Reservations scoped to one branch (branch isolation).
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
