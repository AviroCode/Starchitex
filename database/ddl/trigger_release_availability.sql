-- Orphan guard: if an availability row loses its reservation link
-- (e.g. reservation deleted -> ON DELETE SET NULL), the slot must not
-- stay blocked as 'Reserved'/'Occupied'. Auto-release it.
CREATE OR REPLACE FUNCTION release_availability_on_unlink()
RETURNS trigger AS $$
BEGIN
  IF NEW.reservation_id IS NULL AND OLD.reservation_id IS NOT NULL
     AND NEW.status IN ('Reserved', 'Occupied') THEN
    NEW.status := 'Available';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_release_availability ON room_availability;
CREATE TRIGGER trg_release_availability
  BEFORE UPDATE OF reservation_id ON room_availability
  FOR EACH ROW EXECUTE FUNCTION release_availability_on_unlink();
