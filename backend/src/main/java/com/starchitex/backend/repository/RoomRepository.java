package com.starchitex.backend.repository;

import com.starchitex.backend.model.Room;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class RoomRepository {

    private final JdbcTemplate jdbcTemplate;

    public RoomRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Room> roomRowMapper = (rs, rowNum) -> new Room(
            rs.getInt("room_id"),
            rs.getString("room_number"),
            rs.getObject("floor") != null ? rs.getInt("floor") : null,
            rs.getInt("branch_id"),
            rs.getInt("room_type_id"),
            rs.getString("housekeeping_status")
    );

    public List<Room> findAll() {
        String sql = "SELECT * FROM Room";
        return jdbcTemplate.query(sql, roomRowMapper);
    }

    public Optional<Room> findById(int id) {
        String sql = "SELECT * FROM Room WHERE room_id = ?";
        List<Room> rooms = jdbcTemplate.query(sql, roomRowMapper, id);
        return rooms.isEmpty() ? Optional.empty() : Optional.of(rooms.get(0));
    }

    public List<Room> findByBranchId(int branchId) {
        String sql = "SELECT * FROM Room WHERE branch_id = ?";
        return jdbcTemplate.query(sql, roomRowMapper, branchId);
    }

    public int save(Room room) {
        String sql = "INSERT INTO Room (room_number, floor, branch_id, room_type_id) VALUES (?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                room.roomNumber(),
                room.floor(),
                room.branchId(),
                room.roomTypeId()
        );
    }

    public int update(Room room) {
        String sql = "UPDATE Room SET room_number = ?, floor = ?, branch_id = ?, room_type_id = ? WHERE room_id = ?";
        return jdbcTemplate.update(sql,
                room.roomNumber(),
                room.floor(),
                room.branchId(),
                room.roomTypeId(),
                room.roomId()
        );
    }

    private final RowMapper<com.starchitex.backend.model.AvailableRoomDTO> availableRoomRowMapper = (rs, rowNum) -> new com.starchitex.backend.model.AvailableRoomDTO(
            rs.getInt("room_id"),
            rs.getString("room_number"),
            rs.getObject("floor") != null ? rs.getInt("floor") : null,
            rs.getString("type_name"),
            rs.getBigDecimal("price_override"),
            rs.getString("status")
    );

    // Queries the 'AvailableRoomsToday' SQL View
    public List<com.starchitex.backend.model.AvailableRoomDTO> findAvailableRoomsForToday() {
        String sql = "SELECT * FROM AvailableRoomsToday";
        return jdbcTemplate.query(sql, availableRoomRowMapper);
    }
}
