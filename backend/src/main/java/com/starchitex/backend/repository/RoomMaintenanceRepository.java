package com.starchitex.backend.repository;

import com.starchitex.backend.model.RoomMaintenance;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class RoomMaintenanceRepository {

    private final JdbcTemplate jdbcTemplate;

    public RoomMaintenanceRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<RoomMaintenance> roomMaintenanceRowMapper = (rs, rowNum) -> new RoomMaintenance(
            rs.getInt("room_maintenance_id"),
            rs.getInt("room_id"),
            rs.getObject("reported_by") != null ? rs.getInt("reported_by") : null,
            rs.getObject("assigned_employee_id") != null ? rs.getInt("assigned_employee_id") : null,
            rs.getObject("report_date", LocalDateTime.class),
            rs.getString("priority"),
            rs.getObject("completion_date", LocalDateTime.class),
            rs.getString("description"),
            rs.getString("status")
    );

    public List<RoomMaintenance> findAll() {
        String sql = "SELECT * FROM RoomMaintenance";
        return jdbcTemplate.query(sql, roomMaintenanceRowMapper);
    }

    public Optional<RoomMaintenance> findById(int roomMaintenanceId) {
        String sql = "SELECT * FROM RoomMaintenance WHERE room_maintenance_id = ?";
        List<RoomMaintenance> tickets = jdbcTemplate.query(sql, roomMaintenanceRowMapper, roomMaintenanceId);
        return tickets.isEmpty() ? Optional.empty() : Optional.of(tickets.get(0));
    }

    public List<RoomMaintenance> findByRoomId(int roomId) {
        String sql = "SELECT * FROM RoomMaintenance WHERE room_id = ?";
        return jdbcTemplate.query(sql, roomMaintenanceRowMapper, roomId);
    }

    public int save(RoomMaintenance maintenance) {
        String sql = "INSERT INTO RoomMaintenance (room_id, reported_by, assigned_employee_id, priority, completion_date, description, status) VALUES (?, ?, ?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                maintenance.roomId(),
                maintenance.reportedBy(),
                maintenance.assignedEmployeeId(),
                maintenance.priority(),
                maintenance.completionDate(),
                maintenance.description(),
                maintenance.status()
        );
    }

    public int update(RoomMaintenance maintenance) {
        String sql = "UPDATE RoomMaintenance SET room_id = ?, reported_by = ?, assigned_employee_id = ?, priority = ?, completion_date = ?, description = ?, status = ? WHERE room_maintenance_id = ?";
        return jdbcTemplate.update(sql,
                maintenance.roomId(),
                maintenance.reportedBy(),
                maintenance.assignedEmployeeId(),
                maintenance.priority(),
                maintenance.completionDate(),
                maintenance.description(),
                maintenance.status(),
                maintenance.roomMaintenanceId()
        );
    }
}
