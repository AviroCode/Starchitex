
-- 1.
CREATE TABLE IF NOT EXISTS branch(
  branch_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  address VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  province VARCHAR(100) NOT NULL,
  postal_code VARCHAR(20) NOT NULL,
  email VARCHAR(254) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'Active'
    CHECK (status IN ('Active', 'Under Construction', 'Closed')),

  CONSTRAINT chk_branch_email_lowercase CHECK (email = LOWER(email))

);

-- 2.
CREATE TABLE IF NOT EXISTS employee(
  employee_id SERIAL PRIMARY KEY,
  branch_id INT NOT NULL,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  position VARCHAR(50) NOT NULL,
  gender VARCHAR(20) CHECK (gender IN ('Male', 'Female', 'Other')),
  date_of_birth DATE NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(254) NOT NULL UNIQUE,
  hire_date DATE NOT NULL,
  salary DECIMAL(10,2),
  employee_status VARCHAR(20) NOT NULL DEFAULT 'Active'
    CHECK (employee_status IN ('Active', 'Terminated', 'On Leave')),

  CONSTRAINT fk_branch
    FOREIGN KEY(branch_id)
      REFERENCES branch(branch_id)
      ON DELETE RESTRICT

);

-- 3.
CREATE TABLE IF NOT EXISTS role(
  role_id SERIAL PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255)
);

-- 4.
CREATE TABLE IF NOT EXISTS permission(
  permission_id SERIAL PRIMARY KEY,
  permission_name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255)
);

-- 5.
CREATE TABLE IF NOT EXISTS role_permission(
  role_id INT NOT NULL,
  permission_id INT NOT NULL,
  PRIMARY KEY (role_id, permission_id),

  CONSTRAINT fk_role
    FOREIGN KEY(role_id)
      REFERENCES role(role_id)
      ON DELETE CASCADE,

  CONSTRAINT fk_permission
    FOREIGN KEY(permission_id)
      REFERENCES permission(permission_id)
      ON DELETE CASCADE
);

-- 6.
CREATE TABLE IF NOT EXISTS employee_credentials(
  employee_id INT NOT NULL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  role_id INT NOT NULL,
  last_login TIMESTAMP DEFAULT NULL,

  CONSTRAINT fk_employee
    FOREIGN KEY(employee_id)
      REFERENCES employee(employee_id)
      ON DELETE CASCADE,

  CONSTRAINT fk_role
    FOREIGN KEY(role_id)
      REFERENCES role(role_id)
      ON DELETE RESTRICT
);

-- 7.
CREATE TABLE IF NOT EXISTS audit_log(
  log_id SERIAL PRIMARY KEY,
  employee_id INT,
  guest_id INT,
  action VARCHAR(255) NOT NULL,
  table_name VARCHAR(255) NOT NULL,
  pk_of_table VARCHAR(255) NOT NULL,
  affected_col VARCHAR(50) NOT NULL,
  action_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  old_value TEXT,
  new_value TEXT,
  IP_address VARCHAR(45) NOT NULL,

  CONSTRAINT fk_employee
    FOREIGN KEY(employee_id)
      REFERENCES employee(employee_id)
      ON DELETE RESTRICT,

  -- exactly one actor per log row: an employee OR a guest
  CONSTRAINT chk_audit_one_actor
    CHECK ( (employee_id IS NOT NULL AND guest_id IS NULL)
         OR (employee_id IS NULL AND guest_id IS NOT NULL) )
);

-- 8.
CREATE TABLE IF NOT EXISTS guest(
  guest_id SERIAL PRIMARY KEY,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  gender VARCHAR(20) CHECK (gender IN ('Male', 'Female', 'Other')),
  date_of_birth DATE NOT NULL,
  nationality VARCHAR(50) NOT NULL,
  passport_number VARCHAR(50) NOT NULL UNIQUE,
  phone_number VARCHAR(20),
  email VARCHAR(254) NOT NULL UNIQUE,
  address VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 9.
CREATE TABLE IF NOT EXISTS guest_credentials(
  guest_cred_id SERIAL PRIMARY KEY,
  guest_id INT NOT NULL,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role_id INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP DEFAULT NULL,

  CONSTRAINT fk_guest
    FOREIGN KEY(guest_id)
      REFERENCES guest(guest_id)
      ON DELETE CASCADE,

  CONSTRAINT fk_role
    FOREIGN KEY(role_id)
      REFERENCES role(role_id)
      ON DELETE RESTRICT
);

-- 10.
CREATE TABLE IF NOT EXISTS reservation(
  reservation_id SERIAL PRIMARY KEY,
  guest_id INT NOT NULL,
  -- branch that owns this reservation (for branch isolation + per-branch reports).
  -- Nullable during transition; set NOT NULL once all inserts supply it.
  branch_id INT,
  check_in_date DATE NOT NULL,
  check_out_date DATE NOT NULL,
  actual_checkin_time TIMESTAMP DEFAULT null,
  actual_checkout_time TIMESTAMP DEFAULT null,
  booking_date DATE NOT NULL DEFAULT CURRENT_DATE,
  num_of_guests INT NOT NULL CHECK (num_of_guests > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'Pending'
    CHECK (status IN ('Pending', 'Confirmed', 'Checked In', 'Checked Out', 'Cancelled')),

  CONSTRAINT fk_guest
    FOREIGN KEY(guest_id)
      REFERENCES guest(guest_id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_res_branch
    FOREIGN KEY(branch_id)
      REFERENCES branch(branch_id)
      ON DELETE RESTRICT,

  CONSTRAINT chk_booking_dates CHECK (check_out_date > check_in_date)
);

-- heavy-query index: per-branch occupancy / status reports
CREATE INDEX IF NOT EXISTS idx_reservation_branch_status
  ON reservation (branch_id, status);

-- 11.
CREATE TABLE IF NOT EXISTS invoice(
  invoice_id SERIAL PRIMARY KEY,
  reservation_id INT NOT NULL,
  payer_guest_id INT NOT NULL,
  invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
  sub_total DECIMAL(10,2) NOT NULL CHECK (sub_total >= 0),
  tax_amount DECIMAL(10,2) NOT NULL CHECK (tax_amount >=0),
  discount DECIMAL(10,2) NOT NULL DEFAULT 0.0 CHECK (discount >= 0),
  total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
  status VARCHAR(20) NOT NULL DEFAULT 'Pending'
    CHECK (status IN ('Pending', 'Partially Paid', 'Paid', 'Cancelled')),

  CONSTRAINT fk_reservation
    FOREIGN KEY(reservation_id)
      REFERENCES reservation(reservation_id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_payer_guest
    FOREIGN KEY(payer_guest_id)
      REFERENCES guest(guest_id)
      ON DELETE RESTRICT,

  CONSTRAINT chk_invoice_math
    CHECK (total_amount = (sub_total + tax_amount - discount))
);

-- 12.
CREATE TABLE IF NOT EXISTS invoice_item(
  invoice_item_id SERIAL PRIMARY KEY,
  invoice_id INT NOT NULL,
  item_type VARCHAR(50) NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) CHECK (unit_price >= 0),
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  -- what generated this line (traceability for billing tests/report)
  reference_type VARCHAR(30)
    CHECK (reference_type IN ('Room', 'ServiceRequest', 'FacilityBooking', 'Other')),
  reference_id INT,

  CONSTRAINT fk_invoice
    FOREIGN KEY(invoice_id)
      REFERENCES invoice(invoice_id)
      ON DELETE CASCADE,

  -- line math must balance whenever unit_price is given
  CONSTRAINT chk_item_math
    CHECK (unit_price IS NULL OR amount = quantity * unit_price)
);

-- 13.
CREATE TABLE IF NOT EXISTS payment(
  payment_id SERIAL PRIMARY KEY,
  invoice_id INT NOT NULL,
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  payment_method VARCHAR(50) NOT NULL
    CHECK (payment_method IN ('Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Mobile Payment')),
  transaction_ref VARCHAR(100),

  CONSTRAINT fk_invoice
    FOREIGN KEY(invoice_id)
      REFERENCES invoice(invoice_id)
      ON DELETE RESTRICT

);

-- 14.
CREATE TABLE IF NOT EXISTS reservation_status_log(
  log_id SERIAL PRIMARY KEY,
  reservation_id INT NOT NULL,
  status VARCHAR(20) NOT NULL
    CHECK (status IN ('Pending', 'Confirmed', 'Checked In', 'Checked Out', 'Cancelled')),
  changed_by_employee_id INT,
  action_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  remarks VARCHAR(255),


  CONSTRAINT fk_reservation
    FOREIGN KEY(reservation_id)
      REFERENCES reservation(reservation_id)
      ON DELETE CASCADE,

  CONSTRAINT fk_employee
    FOREIGN KEY(changed_by_employee_id)
      REFERENCES employee(employee_id)
      ON DELETE RESTRICT
);

-- 15.
CREATE TABLE IF NOT EXISTS service(
  service_id SERIAL PRIMARY KEY,
  service_name VARCHAR(100) NOT NULL,
  category VARCHAR(255)
    CHECK (category IN ('Room Service', 'Spa & Wellness', 'Transport', 'Facility Access', 'Housekeeping')),
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  description VARCHAR(255)
);

-- 16.
CREATE TABLE IF NOT EXISTS service_request(
  request_id SERIAL PRIMARY KEY,
  reservation_id INT NOT NULL,
  service_id INT NOT NULL,
  description VARCHAR(255),
  request_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status VARCHAR(20) NOT NULL DEFAULT 'Pending'
    CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled')),
  handled_by INT,

  CONSTRAINT fk_reservation
    FOREIGN KEY(reservation_id)
      REFERENCES reservation(reservation_id)
      ON DELETE CASCADE,

  CONSTRAINT fk_service
    FOREIGN KEY(service_id)
      REFERENCES service(service_id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_employee
    FOREIGN KEY(handled_by)
      REFERENCES employee(employee_id)
      ON DELETE RESTRICT
);

-- 17.
CREATE TABLE IF NOT EXISTS facility(
  facility_id SERIAL PRIMARY KEY,
  branch_id INT NOT NULL,
  facility_name VARCHAR(50) NOT NULL,
  description VARCHAR(255),
  capacity INT NOT NULL CHECK (capacity > 0),
  location VARCHAR(150) NOT NULL,

  CONSTRAINT fk_branch
    FOREIGN KEY(branch_id)
      REFERENCES branch(branch_id)
      ON DELETE RESTRICT
);

-- 18.
CREATE TABLE IF NOT EXISTS facility_booking(
  facility_booking_id SERIAL PRIMARY KEY,
  reservation_id INT NOT NULL,
  facility_id INT NOT NULL,
  booking_date DATE NOT NULL DEFAULT CURRENT_DATE,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,

  CONSTRAINT fk_reservation
    FOREIGN KEY(reservation_id)
      REFERENCES reservation(reservation_id)
      ON DELETE CASCADE,

  CONSTRAINT fk_facility
    FOREIGN KEY(facility_id)
      REFERENCES facility(facility_id)
      ON DELETE RESTRICT,

  CONSTRAINT chk_booking_times CHECK (end_time > start_time)
);

-- 19.
CREATE TABLE IF NOT EXISTS facility_task(
  facilitytask_id SERIAL PRIMARY KEY,
  facility_id INT NOT NULL,
  assigned_employee_id INT NOT NULL,
  description VARCHAR(255) NOT NULL,
  assigned_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_time TIMESTAMP DEFAULT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'Pending'
    CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled')),

  CONSTRAINT fk_facility
    FOREIGN KEY(facility_id)
      REFERENCES facility(facility_id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_employee
    FOREIGN KEY(assigned_employee_id)
      REFERENCES employee(employee_id)
      ON DELETE RESTRICT,

  CONSTRAINT chk_task_times
    CHECK (completed_time IS NULL OR completed_time >= assigned_time)
);

-- 20.
CREATE TABLE IF NOT EXISTS facility_maintenance(
  facility_maintenance_id SERIAL PRIMARY KEY,
  facility_id INT NOT NULL,
  reported_by INT NOT NULL,
  assigned_employee_id INT,
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  priority VARCHAR(20) NOT NULL DEFAULT 'Low'
    CHECK (priority IN ('Low', 'Medium', 'High')),
  completion_date DATE,
  description VARCHAR(255) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'Pending'
    CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled')),

  CONSTRAINT fk_facility
    FOREIGN KEY(facility_id)
      REFERENCES facility(facility_id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_reported_by
    FOREIGN KEY(reported_by)
      REFERENCES employee(employee_id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_assigned_employee
    FOREIGN KEY(assigned_employee_id)
      REFERENCES employee(employee_id)
      ON DELETE RESTRICT,

  CONSTRAINT chk_maintenance_dates
    CHECK (completion_date IS NULL OR completion_date >= report_date)
);

-- 21.
CREATE TABLE IF NOT EXISTS room_type(
  room_type_id SERIAL PRIMARY KEY,
  type_name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255),
  base_price DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
  capacity INT NOT NULL CHECK (capacity > 0)
);

-- 22.
CREATE TABLE IF NOT EXISTS room(
  room_id SERIAL PRIMARY KEY,
  branch_id INT NOT NULL,
  room_number VARCHAR(10) NOT NULL,
  floor INT NOT NULL,
  room_type_id INT NOT NULL,
  -- CURRENT physical state of the room (housekeeping). Booking state
  -- stays per-date in room_availability — the two change independently.
  housekeeping_status VARCHAR(20) NOT NULL DEFAULT 'Clean'
    CHECK (housekeeping_status IN ('Clean', 'Dirty', 'Cleaning', 'Inspected')),

  CONSTRAINT fk_branch
    FOREIGN KEY(branch_id)
      REFERENCES branch(branch_id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_room_type
    FOREIGN KEY(room_type_id)
      REFERENCES room_type(room_type_id)
      ON DELETE RESTRICT,

  CONSTRAINT unique_branch_room_number UNIQUE (branch_id, room_number)
);

-- 23.
CREATE TABLE IF NOT EXISTS reservation_room(
  reservation_id INT NOT NULL,
  room_id INT NOT NULL,
  -- nightly rate agreed AT BOOKING TIME (snapshot; base_price may change later)
  price_per_night DECIMAL(10,2) CHECK (price_per_night >= 0),
  PRIMARY KEY (reservation_id, room_id),

  CONSTRAINT fk_reservation
    FOREIGN KEY(reservation_id)
      REFERENCES reservation(reservation_id)
      ON DELETE CASCADE,

  CONSTRAINT fk_room
    FOREIGN KEY(room_id)
      REFERENCES room(room_id)
      ON DELETE CASCADE
);

-- 24.
CREATE TABLE IF NOT EXISTS room_availability(
  availability_id SERIAL PRIMARY KEY,
  room_id INT NOT NULL,
  calendar_date DATE NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'Available'
    CHECK (status IN ('Available', 'Occupied', 'Reserved', 'Under Maintenance')),
  reservation_id INT,
  price_override DECIMAL(10,2) DEFAULT NULL CHECK (price_override >= 0),

  CONSTRAINT fk_room
    FOREIGN KEY(room_id)
      REFERENCES room(room_id)
      ON DELETE CASCADE,

  CONSTRAINT fk_reservation
    FOREIGN KEY(reservation_id)
      REFERENCES reservation(reservation_id)
      ON DELETE SET NULL,

  CONSTRAINT unique_room_date UNIQUE (room_id, calendar_date)
);

-- 25.
CREATE TABLE IF NOT EXISTS room_task(
  roomtask_id SERIAL PRIMARY KEY,
  room_id INT NOT NULL,
  assigned_employee_id INT,
  description VARCHAR(255) NOT NULL,
  assigned_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_time TIMESTAMP DEFAULT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'Pending'
    CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled')),

  CONSTRAINT fk_room
    FOREIGN KEY(room_id)
      REFERENCES room(room_id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_employee
    FOREIGN KEY(assigned_employee_id)
      REFERENCES employee(employee_id)
      ON DELETE RESTRICT,

  CONSTRAINT chk_task_times
    CHECK (completed_time IS NULL OR completed_time >= assigned_time)
);

-- 26.
CREATE TABLE IF NOT EXISTS room_maintenance(
  room_maintenance_id SERIAL PRIMARY KEY,
  room_id INT NOT NULL,
  reported_by INT NOT NULL,
  assigned_employee_id INT,
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  priority VARCHAR(20) NOT NULL DEFAULT 'Low'
    CHECK (priority IN ('Low', 'Medium', 'High')),
  completion_date DATE,
  description VARCHAR(255) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'Pending'
    CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled')),

  CONSTRAINT fk_room
    FOREIGN KEY(room_id)
      REFERENCES room(room_id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_reported_by
    FOREIGN KEY(reported_by)
      REFERENCES employee(employee_id)
      ON DELETE RESTRICT,

  CONSTRAINT fk_assigned_employee
    FOREIGN KEY(assigned_employee_id)
      REFERENCES employee(employee_id)
      ON DELETE RESTRICT,

  CONSTRAINT chk_maintenance_dates
    CHECK (completion_date IS NULL OR completion_date >= report_date)
);

SELECT
    ROW_NUMBER() OVER (ORDER BY table_name) AS row_num,
    table_name
FROM
    information_schema.tables
WHERE
    table_schema = 'public';