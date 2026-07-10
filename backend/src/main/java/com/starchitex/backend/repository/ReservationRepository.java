package com.starchitex.backend.repository;

import com.starchitex.backend.model.Reservation;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class ReservationRepository {

    private final JdbcTemplate jdbcTemplate;

    public ReservationRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Reservation> reservationRowMapper = (rs, rowNum) -> new Reservation(
            rs.getInt("reservation_id"),
            rs.getInt("branch_id"),
            rs.getInt("guest_id"),
            rs.getObject("check_in_date", LocalDate.class),
            rs.getObject("check_out_date", LocalDate.class),
            rs.getObject("actual_checkin_time", LocalDateTime.class),
            rs.getObject("actual_checkout_time", LocalDateTime.class),
            rs.getObject("booking_date", LocalDateTime.class),
            rs.getInt("num_of_guests"),
            rs.getString("status")
    );

    public List<Reservation> findAll() {
        String sql = "SELECT * FROM Reservation";
        return jdbcTemplate.query(sql, reservationRowMapper);
    }

    public Optional<Reservation> findById(int reservationId) {
        String sql = "SELECT * FROM Reservation WHERE reservation_id = ?";
        List<Reservation> reservations = jdbcTemplate.query(sql, reservationRowMapper, reservationId);
        return reservations.isEmpty() ? Optional.empty() : Optional.of(reservations.get(0));
    }
    
    public List<Reservation> findByGuestId(int guestId) {
        String sql = "SELECT * FROM Reservation WHERE guest_id = ?";
        return jdbcTemplate.query(sql, reservationRowMapper, guestId);
    }

    public int save(Reservation reservation) {
        String sql = "INSERT INTO Reservation (branch_id, guest_id, check_in_date, check_out_date, actual_checkin_time, actual_checkout_time, num_of_guests, status) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                reservation.branchId(),
                reservation.guestId(),
                reservation.checkInDate(),
                reservation.checkOutDate(),
                reservation.actualCheckinTime(),
                reservation.actualCheckoutTime(),
                reservation.numOfGuests(),
                reservation.status()
        );
    }

    public int update(Reservation reservation) {
        String sql = "UPDATE Reservation SET branch_id = ?, guest_id = ?, check_in_date = ?, check_out_date = ?, actual_checkin_time = ?, actual_checkout_time = ?, num_of_guests = ?, status = ? " +
                     "WHERE reservation_id = ?";
        return jdbcTemplate.update(sql,
                reservation.branchId(),
                reservation.guestId(),
                reservation.checkInDate(),
                reservation.checkOutDate(),
                reservation.actualCheckinTime(),
                reservation.actualCheckoutTime(),
                reservation.numOfGuests(),
                reservation.status(),
                reservation.reservationId()
        );
    }
}
