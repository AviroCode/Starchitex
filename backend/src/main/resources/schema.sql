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
    status VARCHAR(50) NOT NULL DEFAULT 'Pending'
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
        item_type IN ('Room', 'Service', 'Damage', 'Maintenance', 'Other')
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
    -- 1. Calculate the sub_total from all associated InvoiceItems
    SELECT COALESCE(SUM(quantity * amount), 0) INTO v_sub_total
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
-- 'Damage', 'Maintenance', 'Other' amounts are left untouched (staff-entered).
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
