-- fn_available_rooms(branch_id) -> TABLE
-- Serves: ROOMS screen (key-rack). Rooms bookable at a branch today.
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
