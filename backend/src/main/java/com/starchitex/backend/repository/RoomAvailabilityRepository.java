package com.starchitex.backend.repository;

import com.starchitex.backend.model.RoomAvailability;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public class RoomAvailabilityRepository {

    private final JdbcTemplate jdbcTemplate;

    public RoomAvailabilityRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<RoomAvailability> roomAvailabilityRowMapper = (rs, rowNum) -> new RoomAvailability(
            rs.getInt("availability_id"),
            rs.getInt("room_id"),
            rs.getObject("calendar_date", LocalDate.class),
            rs.getString("status"),
            rs.getObject("reservation_id") != null ? rs.getInt("reservation_id") : null,
            rs.getBigDecimal("price_override")
    );

    public List<RoomAvailability> findAll() {
        String sql = "SELECT * FROM RoomAvailability";
        return jdbcTemplate.query(sql, roomAvailabilityRowMapper);
    }

    public Optional<RoomAvailability> findById(int availabilityId) {
        String sql = "SELECT * FROM RoomAvailability WHERE availability_id = ?";
        List<RoomAvailability> availabilities = jdbcTemplate.query(sql, roomAvailabilityRowMapper, availabilityId);
        return availabilities.isEmpty() ? Optional.empty() : Optional.of(availabilities.get(0));
    }

    public List<RoomAvailability> findByRoomId(int roomId) {
        String sql = "SELECT * FROM RoomAvailability WHERE room_id = ?";
        return jdbcTemplate.query(sql, roomAvailabilityRowMapper, roomId);
    }

    public int save(RoomAvailability availability) {
        String sql = "INSERT INTO RoomAvailability (room_id, calendar_date, status, reservation_id, price_override) VALUES (?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                availability.roomId(),
                availability.calendarDate(),
                availability.status(),
                availability.reservationId(),
                availability.priceOverride()
        );
    }

    public int update(RoomAvailability availability) {
        String sql = "UPDATE RoomAvailability SET room_id = ?, calendar_date = ?, status = ?, reservation_id = ?, price_override = ? WHERE availability_id = ?";
        return jdbcTemplate.update(sql,
                availability.roomId(),
                availability.calendarDate(),
                availability.status(),
                availability.reservationId(),
                availability.priceOverride(),
                availability.availabilityId()
        );
    }
}
