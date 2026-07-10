package com.starchitex.backend.repository;

import com.starchitex.backend.model.RoomTask;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class RoomTaskRepository {

    private final JdbcTemplate jdbcTemplate;

    public RoomTaskRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<RoomTask> roomTaskRowMapper = (rs, rowNum) -> new RoomTask(
            rs.getInt("roomtask_id"),
            rs.getInt("room_id"),
            rs.getObject("assigned_employee_id") != null ? rs.getInt("assigned_employee_id") : null,
            rs.getString("description"),
            rs.getObject("assigned_time", LocalDateTime.class),
            rs.getObject("completed_time", LocalDateTime.class),
            rs.getString("status")
    );

    public List<RoomTask> findAll() {
        String sql = "SELECT * FROM RoomTask";
        return jdbcTemplate.query(sql, roomTaskRowMapper);
    }

    public Optional<RoomTask> findById(int roomtaskId) {
        String sql = "SELECT * FROM RoomTask WHERE roomtask_id = ?";
        List<RoomTask> tasks = jdbcTemplate.query(sql, roomTaskRowMapper, roomtaskId);
        return tasks.isEmpty() ? Optional.empty() : Optional.of(tasks.get(0));
    }

    public List<RoomTask> findByRoomId(int roomId) {
        String sql = "SELECT * FROM RoomTask WHERE room_id = ?";
        return jdbcTemplate.query(sql, roomTaskRowMapper, roomId);
    }

    public int save(RoomTask task) {
        String sql = "INSERT INTO RoomTask (room_id, assigned_employee_id, description, completed_time, status) VALUES (?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                task.roomId(),
                task.assignedEmployeeId(),
                task.description(),
                task.completedTime(),
                task.status()
        );
    }

    public int update(RoomTask task) {
        String sql = "UPDATE RoomTask SET room_id = ?, assigned_employee_id = ?, description = ?, completed_time = ?, status = ? WHERE roomtask_id = ?";
        return jdbcTemplate.update(sql,
                task.roomId(),
                task.assignedEmployeeId(),
                task.description(),
                task.completedTime(),
                task.status(),
                task.roomtaskId()
        );
    }
}
