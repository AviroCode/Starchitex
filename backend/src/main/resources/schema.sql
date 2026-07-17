-- 1. Independent Tables (No Foreign Keys)
CREATE TABLE IF NOT EXISTS Branch (
    branch_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(20),
    email VARCHAR(255),
    phone VARCHAR(50),
    status VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS Role (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE IF NOT EXISTS Permission (
    permission_id SERIAL PRIMARY KEY,
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE IF NOT EXISTS RoomType (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    description TEXT,
    base_price DECIMAL(10, 2) NOT NULL,
    capacity INT NOT NULL
);

CREATE TABLE IF NOT EXISTS Service (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10, 2) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS Guest (
    guest_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    gender VARCHAR(20),
    date_of_birth DATE,
    nationality VARCHAR(100),
    passport_number VARCHAR(100),
    phone_number VARCHAR(50),
    email VARCHAR(255) UNIQUE,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tables referencing Independent Tables
CREATE TABLE IF NOT EXISTS RolePermission (
    role_id INT REFERENCES Role(role_id) ON DELETE CASCADE,
    permission_id INT REFERENCES Permission(permission_id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS Facility (
    facility_id SERIAL PRIMARY KEY,
    branch_id INT NOT NULL REFERENCES Branch(branch_id),
    facility_name VARCHAR(255) NOT NULL,
    description TEXT,
    capacity INT,
    location VARCHAR(255)
);



CREATE TABLE IF NOT EXISTS Room (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(50) NOT NULL,
    floor INT,
    branch_id INT NOT NULL REFERENCES Branch(branch_id),
    room_type_id INT NOT NULL REFERENCES RoomType(room_type_id),
    -- Housekeeping cleanliness state — deliberately separate from
    -- RoomAvailability.status, which tracks booking occupancy, not
    -- cleanliness. "Out of service" is derived from open RoomMaintenance
    -- tickets (see prevent_booking_maintenance_room below), not stored here.
    housekeeping_status VARCHAR(20) NOT NULL DEFAULT 'Clean',
    UNIQUE (branch_id, room_number)
);

CREATE TABLE IF NOT EXISTS Employee (
    employee_id SERIAL PRIMARY KEY,
    branch_id INT NOT NULL REFERENCES Branch(branch_id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    position VARCHAR(100),
    gender VARCHAR(20),
    date_of_birth DATE,
    phone VARCHAR(50),
    email VARCHAR(255) UNIQUE,
    hire_date DATE,
    salary DECIMAL(10, 2),
    employment_status VARCHAR(50)
);

-- 3. Tables referencing Group 2
CREATE TABLE IF NOT EXISTS EmployeeCredentials (
    employee_id INT PRIMARY KEY REFERENCES Employee(employee_id) ON DELETE CASCADE,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL REFERENCES Role(role_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE TABLE IF NOT EXISTS GuestCredentials (
    guest_cred_id SERIAL PRIMARY KEY,
    guest_id INT NOT NULL UNIQUE REFERENCES Guest(guest_id) ON DELETE CASCADE,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL REFERENCES Role(role_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Reservation (
    reservation_id SERIAL PRIMARY KEY,
    branch_id INT NOT NULL REFERENCES Branch(branch_id),
    guest_id INT NOT NULL REFERENCES Guest(guest_id) ON DELETE RESTRICT,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    actual_checkin_time TIMESTAMP,
    actual_checkout_time TIMESTAMP,
    booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    num_of_guests INT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending',
    special_requests TEXT
);

CREATE TABLE IF NOT EXISTS AuditLog (
    log_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES Employee(employee_id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    pk_of_table VARCHAR(100),
    affected_col VARCHAR(100),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_value TEXT,
    new_value TEXT,
    IP_address VARCHAR(50)
);

-- 4. Tables referencing Group 3
CREATE TABLE IF NOT EXISTS ReservationRoom (
    reservation_id INT REFERENCES Reservation(reservation_id) ON DELETE CASCADE,
    room_id INT REFERENCES Room(room_id),
    PRIMARY KEY (reservation_id, room_id)
);

CREATE TABLE IF NOT EXISTS RoomAvailability (
    availability_id SERIAL PRIMARY KEY,
    room_id INT NOT NULL REFERENCES Room(room_id),
    calendar_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    reservation_id INT REFERENCES Reservation(reservation_id),
    price_override DECIMAL(10, 2),
    UNIQUE (room_id, calendar_date)
);

CREATE TABLE IF NOT EXISTS ReservationStatusLog (
    log_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL REFERENCES Reservation(reservation_id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    changed_by_employee_id INT REFERENCES Employee(employee_id),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    remarks TEXT
);

CREATE TABLE IF NOT EXISTS Invoice (
    invoice_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL REFERENCES Reservation(reservation_id) ON DELETE RESTRICT,
    payer_guest_id INT NOT NULL REFERENCES Guest(guest_id) ON DELETE RESTRICT,
    invoice_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sub_total DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Unpaid'
);

CREATE TABLE IF NOT EXISTS ServiceRequest (
    request_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL REFERENCES Reservation(reservation_id) ON DELETE RESTRICT,
    service_id INT NOT NULL REFERENCES Service(service_id),
    description TEXT,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending',
    handled_by INT REFERENCES Employee(employee_id)
);

CREATE TABLE IF NOT EXISTS FacilityBooking (
    facility_booking_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL REFERENCES Reservation(reservation_id) ON DELETE RESTRICT,
    facility_id INT NOT NULL REFERENCES Facility(facility_id),
    booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    start_date_time TIMESTAMP NOT NULL,
    end_date_time TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS RoomTask (
    roomtask_id SERIAL PRIMARY KEY,
    room_id INT NOT NULL REFERENCES Room(room_id),
    assigned_employee_id INT REFERENCES Employee(employee_id),
    description TEXT,
    assigned_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_time TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending'
);

CREATE TABLE IF NOT EXISTS FacilityTask (
    facilitytask_id SERIAL PRIMARY KEY,
    facility_id INT NOT NULL REFERENCES Facility(facility_id),
    assigned_employee_id INT REFERENCES Employee(employee_id),
    description TEXT,
    assigned_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_time TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'Pending'
);

CREATE TABLE IF NOT EXISTS RoomMaintenance (
    room_maintenance_id SERIAL PRIMARY KEY,
    room_id INT NOT NULL REFERENCES Room(room_id),
    reported_by INT REFERENCES Employee(employee_id),
    assigned_employee_id INT REFERENCES Employee(employee_id),
    report_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    priority VARCHAR(50),
    completion_date TIMESTAMP,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'Reported'
);

CREATE TABLE IF NOT EXISTS FacilityMaintenance (
    facility_maintenance_id SERIAL PRIMARY KEY,
    facility_id INT NOT NULL REFERENCES Facility(facility_id),
    reported_by INT REFERENCES Employee(employee_id),
    assigned_employee_id INT REFERENCES Employee(employee_id),
    report_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    priority VARCHAR(50),
    completion_date TIMESTAMP,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'Reported'
);

-- 5. Tables referencing Group 4
CREATE TABLE IF NOT EXISTS InvoiceItem (
    invoice_item_id SERIAL PRIMARY KEY,
    invoice_id  INT          NOT NULL REFERENCES Invoice(invoice_id)  ON DELETE RESTRICT,
    room_id     INT                   REFERENCES Room(room_id),        -- set for Room / Damage / Maintenance charges
    service_id  INT                   REFERENCES Service(service_id),  -- set for Service charges
    item_type   VARCHAR(100) NOT NULL,
    quantity    INT          NOT NULL DEFAULT 1,
    amount      DECIMAL(10, 2) NOT NULL,
    description TEXT,                                                  -- optional staff note (e.g. "broken TV")
    CONSTRAINT chk_invoiceitem_type CHECK (
        item_type IN ('Room', 'Service', 'Damage', 'Maintenance', 'Other', 'Fee')
    ),
    -- Exactly one of room_id / service_id must be set (or neither for 'Other')
    CONSTRAINT chk_invoiceitem_refs CHECK (
        NOT (room_id IS NOT NULL AND service_id IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS Payment (
    payment_id SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL REFERENCES Invoice(invoice_id) ON DELETE RESTRICT,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_ref VARCHAR(255)
);
ALTER TABLE Payment ADD CONSTRAINT chk_payment_method CHECK (payment_method IN ('Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Digital Wallet', 'Other'));
ALTER TABLE Payment ADD CONSTRAINT chk_payment_amount CHECK (amount > 0);

-- 6. Triggers and Functions (PL/pgSQL)

-- Function to automatically log reservation cancellations and deletions into AuditLog
CREATE OR REPLACE FUNCTION log_reservation_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO AuditLog(action, table_name, pk_of_table, old_value)
        VALUES ('DELETE', 'Reservation', OLD.reservation_id::VARCHAR, 'Guest ID: ' || OLD.guest_id || ', Status: ' || OLD.status);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.status <> NEW.status AND NEW.status = 'Cancelled') THEN
            INSERT INTO AuditLog(action, table_name, pk_of_table, affected_col, old_value, new_value)
            VALUES ('UPDATE_CANCEL', 'Reservation', OLD.reservation_id::VARCHAR, 'status', OLD.status, NEW.status);
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to execute the function on Reservation changes
DROP TRIGGER IF EXISTS trg_reservation_audit ON Reservation;
CREATE TRIGGER trg_reservation_audit
AFTER UPDATE OR DELETE ON Reservation
FOR EACH ROW
EXECUTE FUNCTION log_reservation_audit();

-- -----------------------------------------------------------------------
-- Extended Audit Logging (Invoice, Payment, ServiceRequest)
-- -----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION log_invoice_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO AuditLog(action, table_name, pk_of_table, old_value)
        VALUES ('DELETE', 'Invoice', OLD.invoice_id::VARCHAR, 'Total: ' || OLD.total_amount || ', Status: ' || OLD.status);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.status <> NEW.status) THEN
            INSERT INTO AuditLog(action, table_name, pk_of_table, affected_col, old_value, new_value)
            VALUES ('UPDATE_STATUS', 'Invoice', OLD.invoice_id::VARCHAR, 'status', OLD.status, NEW.status);
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_invoice_audit ON Invoice;
CREATE TRIGGER trg_invoice_audit
AFTER UPDATE OR DELETE ON Invoice
FOR EACH ROW EXECUTE FUNCTION log_invoice_audit();


CREATE OR REPLACE FUNCTION log_payment_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO AuditLog(action, table_name, pk_of_table, old_value)
        VALUES ('DELETE', 'Payment', OLD.payment_id::VARCHAR, 'Amount: ' || OLD.amount || ', Method: ' || OLD.payment_method);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_payment_audit ON Payment;
CREATE TRIGGER trg_payment_audit
AFTER DELETE ON Payment
FOR EACH ROW EXECUTE FUNCTION log_payment_audit();


CREATE OR REPLACE FUNCTION log_service_request_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO AuditLog(action, table_name, pk_of_table, old_value)
        VALUES ('DELETE', 'ServiceRequest', OLD.request_id::VARCHAR, 'Service: ' || OLD.service_id || ', Status: ' || OLD.status);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.status <> NEW.status AND NEW.status = 'Cancelled') THEN
            INSERT INTO AuditLog(action, table_name, pk_of_table, affected_col, old_value, new_value)
            VALUES ('UPDATE_CANCEL', 'ServiceRequest', OLD.request_id::VARCHAR, 'status', OLD.status, NEW.status);
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_service_request_audit ON ServiceRequest;
CREATE TRIGGER trg_service_request_audit
AFTER UPDATE OR DELETE ON ServiceRequest
FOR EACH ROW EXECUTE FUNCTION log_service_request_audit();


-- -----------------------------------------------------------------------
-- Trigger: auto_post_completed_service_request
-- Fires AFTER UPDATE ON ServiceRequest, when status becomes 'Completed'.
-- Posts the service straight to the guest's folio (POS -> Folio auto-
-- posting) if an Invoice already exists for the reservation. If none
-- exists yet, this is a deliberate no-op — staff add it manually once
-- they create the invoice, same as any other line item.
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auto_post_completed_service_request()
RETURNS TRIGGER AS $$
DECLARE
    v_invoice_id INT;
BEGIN
    IF NEW.status = 'Completed' AND OLD.status != 'Completed' THEN
        SELECT invoice_id INTO v_invoice_id
        FROM Invoice WHERE reservation_id = NEW.reservation_id
        ORDER BY invoice_id DESC LIMIT 1;

        IF v_invoice_id IS NOT NULL THEN
            INSERT INTO InvoiceItem (invoice_id, service_id, item_type, quantity, amount)
            VALUES (v_invoice_id, NEW.service_id, 'Service', 1, 0);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_auto_post_completed_service_request ON ServiceRequest;
CREATE TRIGGER trg_auto_post_completed_service_request
AFTER UPDATE ON ServiceRequest
FOR EACH ROW EXECUTE FUNCTION auto_post_completed_service_request();



-- Trigger to prevent double booking of rooms
CREATE OR REPLACE FUNCTION prevent_double_booking()
RETURNS TRIGGER AS $$
DECLARE
    v_conflicts INT;
BEGIN
    SELECT COUNT(*) INTO v_conflicts
    FROM ReservationRoom rr
    JOIN Reservation r_existing ON rr.reservation_id = r_existing.reservation_id
    JOIN Reservation r_new ON NEW.reservation_id = r_new.reservation_id
    WHERE rr.room_id = NEW.room_id
      AND r_existing.status NOT IN ('Cancelled', 'Checked Out')
      AND r_existing.reservation_id != NEW.reservation_id
      AND (r_new.check_in_date < r_existing.check_out_date AND r_new.check_out_date > r_existing.check_in_date);
      
    IF v_conflicts > 0 THEN
        RAISE EXCEPTION 'Double booking detected for room_id % on requested dates', NEW.room_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_double_booking ON ReservationRoom;
CREATE TRIGGER trg_prevent_double_booking
BEFORE INSERT OR UPDATE ON ReservationRoom
FOR EACH ROW EXECUTE FUNCTION prevent_double_booking();



-- Trigger to block booking a room that has an open (unresolved) maintenance
-- ticket — "Out of Service" is derived from RoomMaintenance rather than a
-- stored flag, so a room automatically becomes bookable again the moment its
-- last open ticket is marked Completed, with nothing else to keep in sync.
CREATE OR REPLACE FUNCTION prevent_booking_maintenance_room()
RETURNS TRIGGER AS $$
DECLARE
    v_open_tickets INT;
BEGIN
    SELECT COUNT(*) INTO v_open_tickets
    FROM RoomMaintenance
    WHERE room_id = NEW.room_id AND status != 'Completed';

    IF v_open_tickets > 0 THEN
        RAISE EXCEPTION 'Room % is out of service (open maintenance ticket)', NEW.room_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_booking_maintenance_room ON ReservationRoom;
CREATE TRIGGER trg_prevent_booking_maintenance_room
BEFORE INSERT OR UPDATE ON ReservationRoom
FOR EACH ROW EXECUTE FUNCTION prevent_booking_maintenance_room();



-- Trigger to enforce branch consistency between Reservation and Room
CREATE OR REPLACE FUNCTION enforce_branch_consistency()
RETURNS TRIGGER AS $$
DECLARE
    v_res_branch INT;
    v_room_branch INT;
BEGIN
    SELECT branch_id INTO v_res_branch FROM Reservation WHERE reservation_id = NEW.reservation_id;
    SELECT branch_id INTO v_room_branch FROM Room WHERE room_id = NEW.room_id;
    
    IF v_res_branch != v_room_branch THEN
        RAISE EXCEPTION 'Branch consistency failed: Reservation branch % does not match Room branch %', v_res_branch, v_room_branch;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enforce_branch_consistency ON ReservationRoom;
CREATE TRIGGER trg_enforce_branch_consistency
BEFORE INSERT OR UPDATE ON ReservationRoom
FOR EACH ROW EXECUTE FUNCTION enforce_branch_consistency();

-- 7. Standalone Stored Procedures (PL/pgSQL)

-- Function to dynamically calculate and update an invoice's total
CREATE OR REPLACE FUNCTION calculate_invoice_total(p_invoice_id INT)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    v_sub_total DECIMAL(10, 2);
    v_discount DECIMAL(10, 2);
    v_tax_amount DECIMAL(10, 2);
    v_total_amount DECIMAL(10, 2);
    TAX_RATE CONSTANT DECIMAL(10, 2) := 0.07; -- 7% Tax
BEGIN
    -- 1. Calculate the sub_total from all associated InvoiceItems.
    -- `amount` is already the line total (enforce_invoice_item_price sets it
    -- to unit_price * quantity for Room/Service items), so summing plain
    -- `amount` is correct; `SUM(quantity * amount)` would double-count
    -- quantity for any line with quantity > 1.
    SELECT COALESCE(SUM(amount), 0) INTO v_sub_total
    FROM InvoiceItem
    WHERE invoice_id = p_invoice_id;

    -- 2. Get the current discount from the Invoice table
    SELECT COALESCE(discount, 0) INTO v_discount
    FROM Invoice
    WHERE invoice_id = p_invoice_id;

    -- 3. Calculate Tax (7% of the discounted sub-total)
    v_tax_amount := GREATEST(0, (v_sub_total - v_discount) * TAX_RATE);

    -- 4. Calculate Final Total
    v_total_amount := GREATEST(0, (v_sub_total - v_discount) + v_tax_amount);

    -- 5. Update the Invoice table with the new calculated values
    UPDATE Invoice
    SET sub_total = v_sub_total,
        tax_amount = v_tax_amount,
        total_amount = v_total_amount
    WHERE invoice_id = p_invoice_id;

    -- 6. Return the final total
    RETURN v_total_amount;
END;
$$ LANGUAGE plpgsql;

-- 8. Check Constraints (Data Integrity)

-- Ensure RoomType capacity and base price are valid
ALTER TABLE RoomType ADD CONSTRAINT chk_roomtype_capacity CHECK (capacity > 0);
ALTER TABLE RoomType ADD CONSTRAINT chk_roomtype_price CHECK (base_price >= 0);

-- Ensure Service pricing is valid
ALTER TABLE Service ADD CONSTRAINT chk_service_price CHECK (price >= 0);

-- Ensure Reservation dates are logical (Checkout must be strictly after Check-in)
ALTER TABLE Reservation ADD CONSTRAINT chk_reservation_dates CHECK (check_out_date > check_in_date);
ALTER TABLE Reservation ADD CONSTRAINT chk_reservation_guests CHECK (num_of_guests > 0);


-- Ensure logical timestamps
ALTER TABLE Reservation ADD CONSTRAINT chk_reservation_times CHECK (
    (actual_checkin_time IS NULL OR DATE(actual_checkin_time) >= check_in_date AND DATE(actual_checkin_time) <= check_out_date) AND
    (actual_checkout_time IS NULL OR actual_checkin_time IS NULL OR actual_checkout_time >= actual_checkin_time) AND
    (actual_checkout_time IS NULL OR DATE(actual_checkout_time) >= check_in_date AND DATE(actual_checkout_time) <= check_out_date)
);
ALTER TABLE RoomTask ADD CONSTRAINT chk_roomtask_times CHECK (completed_time IS NULL OR completed_time >= assigned_time);
ALTER TABLE FacilityTask ADD CONSTRAINT chk_facilitytask_times CHECK (completed_time IS NULL OR completed_time >= assigned_time);

-- Ensure Facility Booking times are logical
ALTER TABLE FacilityBooking ADD CONSTRAINT chk_facility_booking_times CHECK (end_date_time > start_date_time);

-- Ensure Invoice amounts are not negative
ALTER TABLE Invoice ADD CONSTRAINT chk_invoice_amounts CHECK (sub_total >= 0 AND tax_amount >= 0 AND discount >= 0 AND total_amount >= 0);
ALTER TABLE Invoice ADD CONSTRAINT chk_invoice_total CHECK (total_amount = GREATEST(0, (sub_total - COALESCE(discount, 0)) + tax_amount));
ALTER TABLE InvoiceItem ADD CONSTRAINT chk_invoice_item_amount CHECK (amount >= 0 AND quantity > 0);



-- ====================================================================================
-- 9. Views (Virtual Tables)
-- ====================================================================================
CREATE OR REPLACE VIEW AvailableRoomsToday AS 
SELECT r.room_id, r.room_number, r.floor, rt.type_name, ra.price_override, ra.status 
FROM Room r
JOIN RoomType rt ON r.room_type_id = rt.room_type_id
JOIN RoomAvailability ra ON r.room_id = ra.room_id
WHERE ra.status = 'Available' AND ra.calendar_date = CURRENT_DATE;

-- Indexes (Performance Optimization)

CREATE INDEX IF NOT EXISTS idx_reservation_guest_id ON Reservation(guest_id);
CREATE INDEX IF NOT EXISTS idx_reservation_branch_id ON Reservation(branch_id);
CREATE INDEX IF NOT EXISTS idx_room_branch_id ON Room(branch_id);
CREATE INDEX IF NOT EXISTS idx_invoice_reservation_id ON Invoice(reservation_id);
CREATE INDEX IF NOT EXISTS idx_payment_invoice_id ON Payment(invoice_id);
CREATE INDEX IF NOT EXISTS idx_room_availability_room_id ON RoomAvailability(room_id);

-- Speeds up login and guest lookup
CREATE INDEX IF NOT EXISTS idx_guest_email ON Guest(email);

-- SPEED UP SEARCHING FOR THE RESERVATIONS BETWEEN CERTAIN DATES 
CREATE INDEX IF NOT EXISTS idx_reservation_dates ON Reservation(check_in_date, check_out_date);


 -- Materialized Views (Data Analytics)
CREATE MATERIALIZED VIEW MonthlyRevenueReport AS
SELECT 
    EXTRACT(YEAR FROM invoice_date) AS invoice_year,
    EXTRACT(MONTH FROM invoice_date) AS invoice_month,
    COUNT(invoice_id) AS total_invoices,
    SUM(total_amount) AS total_revenue
FROM Invoice
WHERE status = 'Paid'
GROUP BY EXTRACT(YEAR FROM invoice_date), EXTRACT(MONTH FROM invoice_date)
ORDER BY invoice_year DESC, invoice_month DESC;

-- Status constraints 
ALTER TABLE Branch ADD CONSTRAINT chk_branch_status CHECK (status IN ('Active', 'Inactive'));

-- Enforce valid Employee employment statuses
ALTER TABLE Employee ADD CONSTRAINT chk_employee_status
CHECK (employment_status IN ('Active', 'Terminated', 'On Leave'));

-- Enforce valid Room housekeeping status
ALTER TABLE Room ADD CONSTRAINT chk_room_housekeeping_status
CHECK (housekeeping_status IN ('Clean', 'Dirty'));

-- Enforce valid RoomAvailability status
ALTER TABLE RoomAvailability ADD CONSTRAINT chk_room_availability_status 
CHECK (status IN ('Available', 'Occupied', 'Maintenance'));

-- Enforce valid Reservation status
ALTER TABLE Reservation ADD CONSTRAINT chk_reservation_status 
CHECK (status IN ('Pending', 'Confirmed', 'Checked In', 'Checked Out', 'Cancelled'));

-- Enforce valid ReservationStatusLog status
ALTER TABLE ReservationStatusLog ADD CONSTRAINT chk_reservation_status_log_status 
CHECK (status IN ('Pending', 'Confirmed', 'Checked In', 'Checked Out', 'Cancelled'));

-- Enforce valid Invoice status
ALTER TABLE Invoice ADD CONSTRAINT chk_invoice_status 
CHECK (status IN ('Unpaid', 'Partially Paid', 'Paid', 'Refunded'));

-- Enforce valid ServiceRequest status
ALTER TABLE ServiceRequest ADD CONSTRAINT chk_service_request_status 
CHECK (status IN ('Pending', 'Completed', 'Cancelled'));

-- Enforce valid RoomTask and FacilityTask statuses
ALTER TABLE RoomTask ADD CONSTRAINT chk_room_task_status 
CHECK (status IN ('Pending', 'In Progress', 'Completed'));

ALTER TABLE FacilityTask ADD CONSTRAINT chk_facility_task_status 
CHECK (status IN ('Pending', 'In Progress', 'Completed'));

-- Enforce valid RoomMaintenance and FacilityMaintenance statuses
ALTER TABLE RoomMaintenance ADD CONSTRAINT chk_room_maintenance_status 
CHECK (status IN ('Reported', 'In Progress', 'Completed'));

ALTER TABLE FacilityMaintenance ADD CONSTRAINT chk_facility_maintenance_status 
CHECK (status IN ('Reported', 'In Progress', 'Completed'));


-- Trigger: auto-fill amount from RoomType.base_price or Service.price
-- 'Damage', 'Maintenance', 'Other', 'Fee' amounts are left untouched
-- (staff-entered, or system-computed elsewhere — e.g. the cancellation
-- policy trigger below sets 'Fee' amounts itself).
CREATE OR REPLACE FUNCTION enforce_invoice_item_price()
RETURNS TRIGGER AS $$
DECLARE
    v_unit_price DECIMAL(10, 2);
BEGIN
    IF NEW.item_type = 'Room' THEN
        -- Requires room_id to be set
        IF NEW.room_id IS NULL THEN
            RAISE EXCEPTION 'InvoiceItem of type Room must have room_id set';
        END IF;

        -- Look up this specific room\'s base_price
        SELECT rt.base_price INTO v_unit_price
        FROM Room r
        JOIN RoomType rt ON r.room_type_id = rt.room_type_id
        WHERE r.room_id = NEW.room_id;

        IF v_unit_price IS NOT NULL THEN
            NEW.amount := v_unit_price * NEW.quantity;
        END IF;

    ELSIF NEW.item_type = 'Service' THEN
        -- Requires service_id to be set
        IF NEW.service_id IS NULL THEN
            RAISE EXCEPTION 'InvoiceItem of type Service must have service_id set';
        END IF;

        -- Look up the service price
        SELECT price INTO v_unit_price
        FROM Service
        WHERE service_id = NEW.service_id;

        IF v_unit_price IS NOT NULL THEN
            NEW.amount := v_unit_price * NEW.quantity;
        END IF;

    -- 'Damage', 'Maintenance', 'Other': amount stays as provided by staff
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enforce_invoice_item_price ON InvoiceItem;
CREATE TRIGGER trg_enforce_invoice_item_price
BEFORE INSERT OR UPDATE ON InvoiceItem
FOR EACH ROW EXECUTE FUNCTION enforce_invoice_item_price();

-- Trigger to sync RoomAvailability
CREATE OR REPLACE FUNCTION sync_room_availability()
RETURNS TRIGGER AS $$
DECLARE
    v_checkin DATE;
    v_checkout DATE;
    curr_date DATE;
BEGIN
    IF (TG_OP = 'INSERT') THEN
        SELECT check_in_date, check_out_date INTO v_checkin, v_checkout FROM Reservation WHERE reservation_id = NEW.reservation_id;
        curr_date := v_checkin;
        WHILE curr_date < v_checkout LOOP
            INSERT INTO RoomAvailability (room_id, calendar_date, status, reservation_id)
            VALUES (NEW.room_id, curr_date, 'Occupied', NEW.reservation_id)
            ON CONFLICT (room_id, calendar_date) 
            DO UPDATE SET status = 'Occupied', reservation_id = NEW.reservation_id;
            curr_date := curr_date + 1;
        END LOOP;
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        SELECT check_in_date, check_out_date INTO v_checkin, v_checkout FROM Reservation WHERE reservation_id = OLD.reservation_id;
        curr_date := v_checkin;
        WHILE curr_date < v_checkout LOOP
            UPDATE RoomAvailability SET status = 'Available', reservation_id = NULL
            WHERE room_id = OLD.room_id AND calendar_date = curr_date;
            curr_date := curr_date + 1;
        END LOOP;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_room_availability ON ReservationRoom;
CREATE TRIGGER trg_sync_room_availability
AFTER INSERT OR DELETE ON ReservationRoom
FOR EACH ROW EXECUTE FUNCTION sync_room_availability();

-- -----------------------------------------------------------------------
-- Trigger: prevent_overpayment
-- Fires BEFORE INSERT on Payment.
-- Sums all existing payments for the same invoice and rejects the new row
-- if it would cause the total paid to exceed Invoice.total_amount.
-- This protects the rule against every writer (API, psql, future services).
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION prevent_overpayment()
RETURNS TRIGGER AS $$
DECLARE
    v_total_amount   DECIMAL(10, 2);
    v_already_paid   DECIMAL(10, 2);
    v_outstanding    DECIMAL(10, 2);
BEGIN
    -- Lock the invoice row to serialise concurrent payment inserts
    SELECT total_amount INTO v_total_amount
    FROM Invoice
    WHERE invoice_id = NEW.invoice_id
    FOR UPDATE;

    IF v_total_amount IS NULL THEN
        RAISE EXCEPTION 'Invoice % not found', NEW.invoice_id;
    END IF;

    SELECT COALESCE(SUM(amount), 0) INTO v_already_paid
    FROM Payment
    WHERE invoice_id = NEW.invoice_id;

    v_outstanding := v_total_amount - v_already_paid;

    IF NEW.amount > v_outstanding THEN
        RAISE EXCEPTION
            'Overpayment rejected: invoice % outstanding is %, but payment amount is %',
            NEW.invoice_id, v_outstanding, NEW.amount
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_overpayment ON Payment;
CREATE TRIGGER trg_prevent_overpayment
BEFORE INSERT ON Payment
FOR EACH ROW EXECUTE FUNCTION prevent_overpayment();

-- -----------------------------------------------------------------------
-- Trigger: update_invoice_status_on_payment
-- Fires AFTER INSERT OR DELETE ON Payment.
-- Automatically recalculates the total amount paid for an invoice and
-- updates its status to 'Paid', 'Partially Paid', or 'Unpaid' unconditionally.
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_invoice_status_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    v_invoice_id     INT;
    v_total_amount   DECIMAL(10, 2);
    v_total_paid     DECIMAL(10, 2);
    v_new_status     VARCHAR(50);
BEGIN
    -- Determine which invoice ID to use (NEW for insert, OLD for delete)
    IF TG_OP = 'DELETE' THEN
        v_invoice_id := OLD.invoice_id;
    ELSE
        v_invoice_id := NEW.invoice_id;
    END IF;

    -- Get the total amount of the invoice
    SELECT total_amount INTO v_total_amount
    FROM Invoice
    WHERE invoice_id = v_invoice_id;

    -- Calculate total paid so far
    SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
    FROM Payment
    WHERE invoice_id = v_invoice_id;

    -- Determine new status
    IF v_total_paid >= v_total_amount THEN
        v_new_status := 'Paid';
    ELSIF v_total_paid > 0 THEN
        v_new_status := 'Partially Paid';
    ELSE
        v_new_status := 'Unpaid';
    END IF;

    -- Update the invoice status
    UPDATE Invoice
    SET status = v_new_status
    WHERE invoice_id = v_invoice_id;

    RETURN NULL; -- AFTER trigger
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_invoice_status ON Payment;
CREATE TRIGGER trg_update_invoice_status
AFTER INSERT OR DELETE ON Payment
FOR EACH ROW EXECUTE FUNCTION update_invoice_status_on_payment();

-- -----------------------------------------------------------------------
-- Trigger: recalculate_invoice_total_on_item_change
-- Fires AFTER INSERT OR UPDATE OR DELETE ON InvoiceItem.
-- Automatically calls calculate_invoice_total() to update the invoice total
-- whenever a line item is added, modified, or removed.
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_recalculate_invoice_total()
RETURNS TRIGGER AS $$
DECLARE
    v_invoice_id INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_invoice_id := OLD.invoice_id;
    ELSE
        v_invoice_id := NEW.invoice_id;
    END IF;

    -- Call the existing stored procedure to do the math and update Invoice
    PERFORM calculate_invoice_total(v_invoice_id);

    RETURN NULL; -- AFTER trigger
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_recalculate_invoice_total_on_item_change ON InvoiceItem;
CREATE TRIGGER trg_recalculate_invoice_total_on_item_change
AFTER INSERT OR UPDATE OR DELETE ON InvoiceItem
FOR EACH ROW EXECUTE FUNCTION trigger_recalculate_invoice_total();

-- -----------------------------------------------------------------------
-- Trigger: enforce_reservation_state_machine
-- Fires BEFORE UPDATE ON Reservation.
-- Enforces allowed transitions for the reservation status state machine.
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION enforce_reservation_state_machine()
RETURNS TRIGGER AS $$
BEGIN
    -- If status is not changing, allow the update
    IF NEW.status = OLD.status THEN
        RETURN NEW;
    END IF;

    -- Allowed state transitions:
    -- Pending -> Confirmed, Cancelled
    -- Confirmed -> Checked In, Cancelled
    -- Checked In -> Checked Out
    -- Cancelled / Checked Out -> (Terminal states, no transitions allowed)
    
    IF OLD.status = 'Pending' AND NEW.status NOT IN ('Confirmed', 'Cancelled') THEN
        RAISE EXCEPTION 'Invalid transition: Cannot move from % to %', OLD.status, NEW.status USING ERRCODE = 'check_violation';
    ELSIF OLD.status = 'Confirmed' AND NEW.status NOT IN ('Checked In', 'Cancelled') THEN
        RAISE EXCEPTION 'Invalid transition: Cannot move from % to %', OLD.status, NEW.status USING ERRCODE = 'check_violation';
    ELSIF OLD.status = 'Checked In' AND NEW.status NOT IN ('Checked Out') THEN
        RAISE EXCEPTION 'Invalid transition: Cannot move from % to %', OLD.status, NEW.status USING ERRCODE = 'check_violation';
    ELSIF OLD.status IN ('Checked Out', 'Cancelled') THEN
        RAISE EXCEPTION 'Invalid transition: % is a terminal state, cannot move to %', OLD.status, NEW.status USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enforce_reservation_state_machine ON Reservation;
CREATE TRIGGER trg_enforce_reservation_state_machine
BEFORE UPDATE ON Reservation
FOR EACH ROW EXECUTE FUNCTION enforce_reservation_state_machine();

-- -----------------------------------------------------------------------
-- Trigger: enforce_cancellation_policy
-- Fires BEFORE UPDATE ON Reservation, when status transitions to
-- 'Cancelled'. Cancellation itself is never blocked — this only decides
-- whether a fee applies. If check-in is same-day or within 24h and an
-- Invoice already exists for this reservation, a one-night cancellation fee
-- (summed across every room on the reservation, at that room's RoomType
-- base_price) is posted as a 'Fee' InvoiceItem, which then flows into
-- sub_total/tax/total via trg_recalculate_invoice_total_on_item_change —
-- same pattern as trg_auto_post_completed_service_request. Runs BEFORE the
-- row update, so it still sees ReservationRoom links that
-- trg_cleanup_on_reservation_cancel (an AFTER trigger) is about to delete.
-- No invoice yet, or outside the window: no-op.
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION enforce_cancellation_policy()
RETURNS TRIGGER AS $$
DECLARE
    v_invoice_id INT;
    v_fee_amount DECIMAL(10, 2);
BEGIN
    IF NEW.status = 'Cancelled' AND OLD.status != 'Cancelled'
       AND NEW.check_in_date - CURRENT_DATE <= 1 THEN

        SELECT invoice_id INTO v_invoice_id
        FROM Invoice WHERE reservation_id = NEW.reservation_id
        ORDER BY invoice_id DESC LIMIT 1;

        IF v_invoice_id IS NOT NULL THEN
            SELECT COALESCE(SUM(rt.base_price), 0) INTO v_fee_amount
            FROM ReservationRoom rr
            JOIN Room r ON rr.room_id = r.room_id
            JOIN RoomType rt ON r.room_type_id = rt.room_type_id
            WHERE rr.reservation_id = NEW.reservation_id;

            IF v_fee_amount > 0 THEN
                INSERT INTO InvoiceItem (invoice_id, item_type, quantity, amount, description)
                VALUES (v_invoice_id, 'Fee', 1, v_fee_amount, 'Cancellation fee (within 24h of check-in)');
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enforce_cancellation_policy ON Reservation;
CREATE TRIGGER trg_enforce_cancellation_policy
BEFORE UPDATE ON Reservation
FOR EACH ROW EXECUTE FUNCTION enforce_cancellation_policy();

-- -----------------------------------------------------------------------
-- Trigger: cleanup_on_reservation_cancel
-- Fires AFTER UPDATE ON Reservation.
-- Automatically deletes associated ReservationRoom records when a reservation
-- is cancelled. This cascades to trg_sync_room_availability to free the rooms.
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cleanup_reservation_rooms_on_cancel()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Cancelled' AND OLD.status != 'Cancelled' THEN
        DELETE FROM ReservationRoom WHERE reservation_id = NEW.reservation_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cleanup_on_reservation_cancel ON Reservation;
CREATE TRIGGER trg_cleanup_on_reservation_cancel
AFTER UPDATE ON Reservation
FOR EACH ROW EXECUTE FUNCTION cleanup_reservation_rooms_on_cancel();

-- -----------------------------------------------------------------------
-- Trigger: mark_room_dirty_on_checkout
-- Fires AFTER UPDATE ON Reservation, when status becomes 'Checked Out'.
-- Flips every room from this stay to housekeeping_status = 'Dirty' and
-- queues a cleaning RoomTask for each — the "inventory reset to
-- Dirty/Vacant on checkout" step of a real front-desk workflow.
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION mark_room_dirty_on_checkout()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Checked Out' AND OLD.status != 'Checked Out' THEN
        UPDATE Room SET housekeeping_status = 'Dirty'
        WHERE room_id IN (SELECT room_id FROM ReservationRoom WHERE reservation_id = NEW.reservation_id);

        INSERT INTO RoomTask (room_id, description, status)
        SELECT room_id, 'Post-checkout cleaning', 'Pending'
        FROM ReservationRoom WHERE reservation_id = NEW.reservation_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mark_room_dirty_on_checkout ON Reservation;
CREATE TRIGGER trg_mark_room_dirty_on_checkout
AFTER UPDATE ON Reservation
FOR EACH ROW EXECUTE FUNCTION mark_room_dirty_on_checkout();

-- -----------------------------------------------------------------------
-- Trigger: mark_room_clean_on_task_complete
-- Fires AFTER UPDATE ON RoomTask, when status becomes 'Completed'.
-- -----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION mark_room_clean_on_task_complete()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'Completed' AND OLD.status != 'Completed' THEN
        UPDATE Room SET housekeeping_status = 'Clean' WHERE room_id = NEW.room_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mark_room_clean_on_task_complete ON RoomTask;
CREATE TRIGGER trg_mark_room_clean_on_task_complete
AFTER UPDATE ON RoomTask
FOR EACH ROW EXECUTE FUNCTION mark_room_clean_on_task_complete();


-- ====================================================================================
-- 10. Row-Level Security (RLS)
-- ====================================================================================

-- Helper function to check if the current user is a super admin
CREATE OR REPLACE FUNCTION is_super_admin() RETURNS BOOLEAN AS $$
BEGIN
    RETURN current_setting('app.is_super_admin', true) = 'true';
END;
$$ LANGUAGE plpgsql;

-- Helper function to get current branch ID safely
CREATE OR REPLACE FUNCTION current_branch_id() RETURNS INT AS $$
DECLARE
    val TEXT;
BEGIN
    val := current_setting('app.current_branch_id', true);
    IF val = '' OR val IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN val::INT;
END;
$$ LANGUAGE plpgsql;

-- Helper function to get current guest ID safely
CREATE OR REPLACE FUNCTION current_guest_id() RETURNS INT AS $$
DECLARE
    val TEXT;
BEGIN
    val := current_setting('app.current_guest_id', true);
    IF val = '' OR val IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN val::INT;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS on Tenant Tables
ALTER TABLE Branch ENABLE ROW LEVEL SECURITY;
ALTER TABLE Employee ENABLE ROW LEVEL SECURITY;
ALTER TABLE Room ENABLE ROW LEVEL SECURITY;
ALTER TABLE Facility ENABLE ROW LEVEL SECURITY;
ALTER TABLE RoomAvailability ENABLE ROW LEVEL SECURITY;
ALTER TABLE Reservation ENABLE ROW LEVEL SECURITY;
ALTER TABLE ReservationRoom ENABLE ROW LEVEL SECURITY;
ALTER TABLE Invoice ENABLE ROW LEVEL SECURITY;
ALTER TABLE InvoiceItem ENABLE ROW LEVEL SECURITY;
ALTER TABLE Payment ENABLE ROW LEVEL SECURITY;
ALTER TABLE ServiceRequest ENABLE ROW LEVEL SECURITY;
ALTER TABLE ReservationStatusLog ENABLE ROW LEVEL SECURITY;
ALTER TABLE Guest ENABLE ROW LEVEL SECURITY;
ALTER TABLE AuditLog ENABLE ROW LEVEL SECURITY;
ALTER TABLE RoomTask ENABLE ROW LEVEL SECURITY;
ALTER TABLE FacilityTask ENABLE ROW LEVEL SECURITY;
ALTER TABLE RoomMaintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE FacilityMaintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE FacilityBooking ENABLE ROW LEVEL SECURITY;

-- FORCE RLS so it applies even to table owners (unless BYPASSRLS is used)
ALTER TABLE Branch FORCE ROW LEVEL SECURITY;
ALTER TABLE Employee FORCE ROW LEVEL SECURITY;
ALTER TABLE Room FORCE ROW LEVEL SECURITY;
ALTER TABLE Facility FORCE ROW LEVEL SECURITY;
ALTER TABLE RoomAvailability FORCE ROW LEVEL SECURITY;
ALTER TABLE Reservation FORCE ROW LEVEL SECURITY;
ALTER TABLE ReservationRoom FORCE ROW LEVEL SECURITY;
ALTER TABLE Invoice FORCE ROW LEVEL SECURITY;
ALTER TABLE InvoiceItem FORCE ROW LEVEL SECURITY;
ALTER TABLE Payment FORCE ROW LEVEL SECURITY;
ALTER TABLE ServiceRequest FORCE ROW LEVEL SECURITY;
ALTER TABLE ReservationStatusLog FORCE ROW LEVEL SECURITY;
ALTER TABLE Guest FORCE ROW LEVEL SECURITY;
ALTER TABLE AuditLog FORCE ROW LEVEL SECURITY;
ALTER TABLE RoomTask FORCE ROW LEVEL SECURITY;
ALTER TABLE FacilityTask FORCE ROW LEVEL SECURITY;
ALTER TABLE RoomMaintenance FORCE ROW LEVEL SECURITY;
ALTER TABLE FacilityMaintenance FORCE ROW LEVEL SECURITY;
ALTER TABLE FacilityBooking FORCE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------

-- Branch: Employees can see/manage their own branch, Super Admins can see all.
-- Guests get a separate read-only SELECT policy below so they can browse branches to book.
CREATE POLICY branch_isolation ON Branch FOR ALL USING (
    is_super_admin() OR branch_id = current_branch_id()
);
CREATE POLICY branch_guest_read ON Branch FOR SELECT USING (
    current_guest_id() IS NOT NULL
);

-- Employee: Employees can see/manage employees in their own branch
CREATE POLICY employee_isolation ON Employee FOR ALL USING (
    is_super_admin() OR branch_id = current_branch_id()
);

-- Room: Isolated by branch_id for staff. Guests get a read-only SELECT policy
-- below so they can browse rooms across every branch to make a booking.
CREATE POLICY room_isolation ON Room FOR ALL USING (
    is_super_admin() OR branch_id = current_branch_id()
);
CREATE POLICY room_guest_read ON Room FOR SELECT USING (
    current_guest_id() IS NOT NULL
);

-- Facility: same pattern as Room (was previously unprotected by RLS entirely)
CREATE POLICY facility_isolation ON Facility FOR ALL USING (
    is_super_admin() OR branch_id = current_branch_id()
);
CREATE POLICY facility_guest_read ON Facility FOR SELECT USING (
    current_guest_id() IS NOT NULL
);

-- RoomAvailability: no branch_id of its own (was previously unprotected by RLS
-- entirely), so derive it via room_id -> Room.branch_id. Guests get the same
-- read-only carve-out as Room so they can check dates before booking.
--
-- USING also needs to make a guest's OWN reservation's rows visible: when a
-- guest cancels their own reservation, trg_cleanup_on_reservation_cancel ->
-- trg_sync_room_availability run in the SAME session (the guest's), and that
-- cascade needs to see + update the RoomAvailability row it's freeing up.
-- WITH CHECK is deliberately looser than USING: freeing a room (setting
-- reservation_id back to NULL) is always safe regardless of who's doing it --
-- the only thing that needs branch-gating is *claiming* a room for a branch's
-- own inventory, not releasing one.
CREATE POLICY room_availability_isolation ON RoomAvailability FOR ALL USING (
    is_super_admin()
    OR EXISTS (
        SELECT 1 FROM Room r WHERE r.room_id = RoomAvailability.room_id AND r.branch_id = current_branch_id()
    )
    OR EXISTS (
        SELECT 1 FROM Reservation res WHERE res.reservation_id = RoomAvailability.reservation_id AND res.guest_id = current_guest_id()
    )
) WITH CHECK (
    is_super_admin()
    OR EXISTS (
        SELECT 1 FROM Room r WHERE r.room_id = RoomAvailability.room_id AND r.branch_id = current_branch_id()
    )
    OR reservation_id IS NULL
);
CREATE POLICY room_availability_guest_read ON RoomAvailability FOR SELECT USING (
    current_guest_id() IS NOT NULL
);

-- Reservation: Isolated by branch_id for staff, or guest_id for guests
CREATE POLICY reservation_isolation ON Reservation FOR ALL USING (
    is_super_admin() 
    OR branch_id = current_branch_id() 
    OR guest_id = current_guest_id()
);

-- ReservationRoom: Inherits from Reservation
CREATE POLICY reservation_room_isolation ON ReservationRoom FOR ALL USING (
    is_super_admin() 
    OR EXISTS (
        SELECT 1 FROM Reservation r 
        WHERE r.reservation_id = ReservationRoom.reservation_id 
        AND (r.branch_id = current_branch_id() OR r.guest_id = current_guest_id())
    )
);

-- Invoice: Inherits from Reservation
CREATE POLICY invoice_isolation ON Invoice FOR ALL USING (
    is_super_admin() 
    OR EXISTS (
        SELECT 1 FROM Reservation r 
        WHERE r.reservation_id = Invoice.reservation_id 
        AND (r.branch_id = current_branch_id() OR r.guest_id = current_guest_id())
    )
);

-- Payment: Inherits from Invoice -> Reservation
CREATE POLICY payment_isolation ON Payment FOR ALL USING (
    is_super_admin() 
    OR EXISTS (
        SELECT 1 FROM Invoice i 
        JOIN Reservation r ON i.reservation_id = r.reservation_id
        WHERE i.invoice_id = Payment.invoice_id 
        AND (r.branch_id = current_branch_id() OR r.guest_id = current_guest_id())
    )
);

-- InvoiceItem: Inherits from Invoice -> Reservation
CREATE POLICY invoice_item_isolation ON InvoiceItem FOR ALL USING (
    is_super_admin()
    OR EXISTS (
        SELECT 1 FROM Invoice i
        JOIN Reservation r ON i.reservation_id = r.reservation_id
        WHERE i.invoice_id = InvoiceItem.invoice_id
        AND (r.branch_id = current_branch_id() OR r.guest_id = current_guest_id())
    )
);

-- ServiceRequest: Inherits from Reservation
CREATE POLICY service_request_isolation ON ServiceRequest FOR ALL USING (
    is_super_admin()
    OR EXISTS (
        SELECT 1 FROM Reservation r
        WHERE r.reservation_id = ServiceRequest.reservation_id
        AND (r.branch_id = current_branch_id() OR r.guest_id = current_guest_id())
    )
);

-- ReservationStatusLog: Inherits from Reservation
CREATE POLICY reservation_status_log_isolation ON ReservationStatusLog FOR ALL USING (
    is_super_admin()
    OR EXISTS (
        SELECT 1 FROM Reservation r
        WHERE r.reservation_id = ReservationStatusLog.reservation_id
        AND (r.branch_id = current_branch_id() OR r.guest_id = current_guest_id())
    )
);

-- Guest: chain-wide directory (a guest can stay at any branch, so guests are not
-- owned by one branch the way Room/Employee are). Any staff member (any branch)
-- or the guest themself may see/manage the row.
CREATE POLICY guest_isolation ON Guest FOR ALL USING (
    is_super_admin() OR current_branch_id() IS NOT NULL OR guest_id = current_guest_id()
);

-- AuditLog: security-sensitive, not branch data. Reads are super-admin only.
-- Inserts must stay unconditionally allowed: the audit triggers (log_reservation_audit,
-- log_invoice_audit, log_payment_audit, log_service_request_audit) run in the same
-- session as the triggering statement, so with FORCE RLS and no INSERT policy their
-- INSERTs would be rejected regardless of who fired the original statement.
-- No UPDATE/DELETE policy is defined on purpose -- nothing should ever modify audit
-- rows, and with FORCE ROW LEVEL SECURITY + no matching policy those are denied.
CREATE POLICY audit_log_read ON AuditLog FOR SELECT USING (
    is_super_admin()
);
CREATE POLICY audit_log_insert ON AuditLog FOR INSERT WITH CHECK (true);

-- Tasks & Maintenance: none of these tables carry branch_id directly, so branch
-- is derived via their Room/Facility foreign key.
CREATE POLICY room_task_isolation ON RoomTask FOR ALL USING (
    is_super_admin() OR EXISTS (
        SELECT 1 FROM Room r WHERE r.room_id = RoomTask.room_id AND r.branch_id = current_branch_id()
    )
);
CREATE POLICY facility_task_isolation ON FacilityTask FOR ALL USING (
    is_super_admin() OR EXISTS (
        SELECT 1 FROM Facility f WHERE f.facility_id = FacilityTask.facility_id AND f.branch_id = current_branch_id()
    )
);
CREATE POLICY room_maintenance_isolation ON RoomMaintenance FOR ALL USING (
    is_super_admin() OR EXISTS (
        SELECT 1 FROM Room r WHERE r.room_id = RoomMaintenance.room_id AND r.branch_id = current_branch_id()
    )
);
CREATE POLICY facility_maintenance_isolation ON FacilityMaintenance FOR ALL USING (
    is_super_admin() OR EXISTS (
        SELECT 1 FROM Facility f WHERE f.facility_id = FacilityMaintenance.facility_id AND f.branch_id = current_branch_id()
    )
);
CREATE POLICY facility_booking_isolation ON FacilityBooking FOR ALL USING (
    is_super_admin() OR EXISTS (
        SELECT 1 FROM Facility f WHERE f.facility_id = FacilityBooking.facility_id AND f.branch_id = current_branch_id()
    )
);

-- ====================================================================================
-- 11. Stored Procedures (Data Management & GDPR)
-- ====================================================================================

-- Stored Procedure: anonymize_guest(guest_id)
-- Nullifies PII for a given guest while preserving financial and audit history.
-- Also removes associated GuestCredentials to prevent future logins.
CREATE OR REPLACE PROCEDURE anonymize_guest(p_guest_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. Delete credentials to revoke access immediately
    DELETE FROM GuestCredentials WHERE guest_id = p_guest_id;
    
    -- 2. Nullify PII in Guest table. 
    -- 'first_name' and 'last_name' are NOT NULL in schema, so we replace them with a generic string.
    UPDATE Guest 
    SET first_name = 'Anonymized',
        last_name = 'Guest',
        gender = NULL,
        date_of_birth = NULL,
        nationality = NULL,
        passport_number = NULL,
        phone_number = NULL,
        email = 'anonymized_' || guest_id || '@deleted.local',
        address = NULL
    WHERE guest_id = p_guest_id;
END;
$$;
