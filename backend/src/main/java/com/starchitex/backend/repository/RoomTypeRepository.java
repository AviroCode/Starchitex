package com.starchitex.backend.repository;

import com.starchitex.backend.model.RoomType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class RoomTypeRepository {

    private final JdbcTemplate jdbcTemplate;

    public RoomTypeRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // RowMapper specifically handling BigDecimal mapping for decimal database values
    private final RowMapper<RoomType> roomTypeRowMapper = (rs, rowNum) -> new RoomType(
            rs.getInt("room_type_id"),
            rs.getString("type_name"),
            rs.getString("description"),
            rs.getBigDecimal("base_price"),
            rs.getInt("capacity")
    );

    public List<RoomType> findAll() {
        String sql = "SELECT * FROM RoomType";
        return jdbcTemplate.query(sql, roomTypeRowMapper);
    }

    public Optional<RoomType> findById(int id) {
        String sql = "SELECT * FROM RoomType WHERE room_type_id = ?";
        List<RoomType> roomTypes = jdbcTemplate.query(sql, roomTypeRowMapper, id);
        return roomTypes.isEmpty() ? Optional.empty() : Optional.of(roomTypes.get(0));
    }

    public int save(RoomType roomType) {
        String sql = "INSERT INTO RoomType (type_name, description, base_price, capacity) VALUES (?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                roomType.typeName(),
                roomType.description(),
                roomType.basePrice(),
                roomType.capacity()
        );
    }

    public int update(RoomType roomType) {
        String sql = "UPDATE RoomType SET type_name = ?, description = ?, base_price = ?, capacity = ? WHERE room_type_id = ?";
        return jdbcTemplate.update(sql,
                roomType.typeName(),
                roomType.description(),
                roomType.basePrice(),
                roomType.capacity(),
                roomType.roomTypeId()
        );
    }
}
