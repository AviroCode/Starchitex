package com.starchitex.backend.repository;

import com.starchitex.backend.model.FacilityBooking;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class FacilityBookingRepository {

    private final JdbcTemplate jdbcTemplate;

    public FacilityBookingRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<FacilityBooking> facilityBookingRowMapper = (rs, rowNum) -> new FacilityBooking(
            rs.getInt("facility_booking_id"),
            rs.getInt("reservation_id"),
            rs.getInt("facility_id"),
            rs.getObject("booking_date", LocalDateTime.class),
            rs.getObject("start_date_time", LocalDateTime.class),
            rs.getObject("end_date_time", LocalDateTime.class)
    );

    public List<FacilityBooking> findAll() {
        String sql = "SELECT * FROM FacilityBooking";
        return jdbcTemplate.query(sql, facilityBookingRowMapper);
    }

    public Optional<FacilityBooking> findById(int bookingId) {
        String sql = "SELECT * FROM FacilityBooking WHERE facility_booking_id = ?";
        List<FacilityBooking> bookings = jdbcTemplate.query(sql, facilityBookingRowMapper, bookingId);
        return bookings.isEmpty() ? Optional.empty() : Optional.of(bookings.get(0));
    }

    public List<FacilityBooking> findByReservationId(int reservationId) {
        String sql = "SELECT * FROM FacilityBooking WHERE reservation_id = ?";
        return jdbcTemplate.query(sql, facilityBookingRowMapper, reservationId);
    }

    public int save(FacilityBooking booking) {
        String sql = "INSERT INTO FacilityBooking (reservation_id, facility_id, start_date_time, end_date_time) VALUES (?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                booking.reservationId(),
                booking.facilityId(),
                booking.startDateTime(),
                booking.endDateTime()
        );
    }

    public int update(FacilityBooking booking) {
        String sql = "UPDATE FacilityBooking SET reservation_id = ?, facility_id = ?, start_date_time = ?, end_date_time = ? WHERE facility_booking_id = ?";
        return jdbcTemplate.update(sql,
                booking.reservationId(),
                booking.facilityId(),
                booking.startDateTime(),
                booking.endDateTime(),
                booking.facilityBookingId()
        );
    }
}
