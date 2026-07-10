package com.starchitex.backend.repository;

import com.starchitex.backend.model.ReservationRoom;
import com.starchitex.backend.model.Room;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class ReservationRoomRepository {

    private final JdbcTemplate jdbcTemplate;

    public ReservationRoomRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<ReservationRoom> reservationRoomRowMapper = (rs, rowNum) -> new ReservationRoom(
            rs.getInt("reservation_id"),
            rs.getInt("room_id")
    );

    private final RowMapper<Room> roomRowMapper = (rs, rowNum) -> new Room(
            rs.getInt("room_id"),
            rs.getString("room_number"),
            rs.getObject("floor") != null ? rs.getInt("floor") : null,
            rs.getInt("branch_id"),
            rs.getInt("room_type_id")
    );

    public List<ReservationRoom> findAll() {
        String sql = "SELECT * FROM ReservationRoom";
        return jdbcTemplate.query(sql, reservationRoomRowMapper);
    }

    public List<Room> findRoomsByReservationId(int reservationId) {
        String sql = "SELECT r.* FROM Room r JOIN ReservationRoom rr ON r.room_id = rr.room_id WHERE rr.reservation_id = ?";
        return jdbcTemplate.query(sql, roomRowMapper, reservationId);
    }

    public List<Integer> findReservationIdsByRoomId(int roomId) {
        String sql = "SELECT reservation_id FROM ReservationRoom WHERE room_id = ?";
        return jdbcTemplate.query(sql, (rs, rowNum) -> rs.getInt("reservation_id"), roomId);
    }

    public int save(ReservationRoom reservationRoom) {
        String sql = "INSERT INTO ReservationRoom (reservation_id, room_id) VALUES (?, ?)";
        return jdbcTemplate.update(sql,
                reservationRoom.reservationId(),
                reservationRoom.roomId()
        );
    }

    public int delete(int reservationId, int roomId) {
        String sql = "DELETE FROM ReservationRoom WHERE reservation_id = ? AND room_id = ?";
        return jdbcTemplate.update(sql, reservationId, roomId);
    }

    public int deleteByReservationId(int reservationId) {
        // Deleting all rows fires the sync_room_availability trigger on each deleted row,
        // which sets each room's RoomAvailability back to 'Available' for the freed dates.
        String sql = "DELETE FROM ReservationRoom WHERE reservation_id = ?";
        return jdbcTemplate.update(sql, reservationId);
    }
}
