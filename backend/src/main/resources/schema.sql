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
    room_type_id INT NOT NULL REFERENCES RoomType(room_type_id)
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
    guest_id INT NOT NULL REFERENCES Guest(guest_id),
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    actual_checkin_time TIMESTAMP,
    actual_checkout_time TIMESTAMP,
    booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    num_of_guests INT NOT NULL,
    status VARCHAR(50) NOT NULL
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
    price_override DECIMAL(10, 2)
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
    reservation_id INT NOT NULL REFERENCES Reservation(reservation_id),
    payer_guest_id INT NOT NULL REFERENCES Guest(guest_id),
    invoice_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sub_total DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS ServiceRequest (
    request_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL REFERENCES Reservation(reservation_id),
    service_id INT NOT NULL REFERENCES Service(service_id),
    description TEXT,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL,
    handled_by INT REFERENCES Employee(employee_id)
);

CREATE TABLE IF NOT EXISTS FacilityBooking (
    facility_booking_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL REFERENCES Reservation(reservation_id),
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
    status VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS FacilityTask (
    facilitytask_id SERIAL PRIMARY KEY,
    facility_id INT NOT NULL REFERENCES Facility(facility_id),
    assigned_employee_id INT REFERENCES Employee(employee_id),
    description TEXT,
    assigned_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_time TIMESTAMP,
    status VARCHAR(50) NOT NULL
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
    status VARCHAR(50) NOT NULL
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
    status VARCHAR(50) NOT NULL
);

-- 5. Tables referencing Group 4
CREATE TABLE IF NOT EXISTS InvoiceItem (
    invoice_item_id SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL REFERENCES Invoice(invoice_id) ON DELETE CASCADE,
    item_type VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS Payment (
    payment_id SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL REFERENCES Invoice(invoice_id) ON DELETE CASCADE,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    transaction_ref VARCHAR(255)
);

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
        IF (OLD.status <> NEW.status AND NEW.status = 'CANCELLED') THEN
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

-- Ensure Facility Booking times are logical
ALTER TABLE FacilityBooking ADD CONSTRAINT chk_facility_booking_times CHECK (end_date_time > start_date_time);

-- Ensure Invoice amounts are not negative
ALTER TABLE Invoice ADD CONSTRAINT chk_invoice_amounts CHECK (sub_total >= 0 AND tax_amount >= 0 AND discount >= 0 AND total_amount >= 0);
ALTER TABLE InvoiceItem ADD CONSTRAINT chk_invoice_item_amount CHECK (amount >= 0 AND quantity > 0);



-- ====================================================================================
-- 9. Views (Virtual Tables)
-- ====================================================================================
CREATE OR REPLACE VIEW AvailableRoomsToday AS 
SELECT r.room_id, r.room_number, r.floor, rt.type_name, ra.price_override, ra.status 
FROM Room r
JOIN RoomType rt ON r.room_type_id = rt.room_type_id
JOIN RoomAvailability ra ON r.room_id = ra.room_id
WHERE ra.status = 'AVAILABLE' AND ra.calendar_date = CURRENT_DATE;

-- Indexes (Performance Optimization)
-- Speeds up login and guest lookup
CREATE INDEX IF NOT EXISTS idx_guest_email ON Guest(email);

-- SPEED UP SEARCHING FOR THE RESERVATIONS BETWEEN CERTAIN DATES 
CREATE INDEX IF NOT EXISTS idx_reservation_dates ON Reservation(check_in_date, check_out_date);


