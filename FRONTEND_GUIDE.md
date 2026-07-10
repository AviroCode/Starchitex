# Starchitex Frontend Integration Guide

This document provides everything the frontend developer needs to know to integrate with the Starchitex Spring Boot Backend.

## 1. Backend Server Details
- **Local URL:** `http://localhost:8080`
- **Base API Path:** `/api`
- **Format:** All requests and responses use `application/json`.

## 2. Authentication & Security (JWT)
The backend uses JSON Web Tokens (JWT) for Role-Based Access Control (RBAC).
- Every protected route requires the token in the headers:
  ```http
  Authorization: Bearer <your_jwt_token_here>
  ```

### Login Endpoint
- **URL:** `POST /api/auth/login`
- **Body:**
  ```json
  {
    "username": "guest_or_employee_username",
    "password": "their_password"
  }
  ```
- **Response:** Returns the raw JWT string. Save this in `localStorage` or a secure cookie! The token contains the user's `roleId` inside of it.

## 3. Core API Endpoints
The backend follows standard RESTful conventions for almost all tables in the database. Replace `{id}` with the primary key.

### Guests & Users
- `GET /api/guests` - Get all guests
- `GET /api/guests/{id}` - Get a specific guest
- `POST /api/guests` - Register a new guest

### Rooms & Availability
- `GET /api/rooms` - Get all physical rooms
- `GET /api/roomTypes` - Get room categories (Single, Double, Suite)
- `GET /api/roomAvailability` - Check the calendar availability for rooms

### Reservations & Booking
- `GET /api/reservations` - Get all reservations
- `POST /api/reservations` - Create a new reservation
- `PUT /api/reservations/{id}` - Update reservation details (e.g. status)
- *(Note: Changing a reservation status to `CANCELLED` automatically triggers a database-level Audit Log!)*

### Billing & Invoices
- `GET /api/invoices` - Get all invoices
- `GET /api/invoices/{id}` - Get a specific invoice
- `POST /api/invoices` - Create a new invoice
- *(Note: The database mathematically guarantees invoices cannot have negative values due to Check Constraints).*

### Advanced Reporting (For Manager Dashboards)
- `GET /api/invoices/monthly-revenue` (or similar depending on controller routing) - Fetches data from the `MonthlyRevenueReport` Materialized View (blazing fast!).

## 4. Key Notes for the Frontend Developer
1. **Zero-ORM Database:** The backend does not use Hibernate. It uses raw SQL `JdbcTemplate`. This means the data returned in JSON matches the exact column names of the database in camelCase format (e.g., `room_id` becomes `roomId`).
2. **Database Integrity:** Do not worry about doing extreme data validation on the frontend. The PostgreSQL database has strict `CHECK` constraints (e.g. `check_out_date` MUST be after `check_in_date`). If you send bad data, the backend will return an HTTP 500/400 error. Just catch the error and show a toast notification!
3. **Double Booking:** The backend has overlap protection. If you try to book a room that is already booked, the API will reject it. Ensure you refresh the `roomAvailability` calendar frequently!
