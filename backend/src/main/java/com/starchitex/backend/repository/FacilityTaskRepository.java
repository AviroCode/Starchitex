package com.starchitex.backend.repository;

import com.starchitex.backend.model.FacilityTask;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class FacilityTaskRepository {

    private final JdbcTemplate jdbcTemplate;

    public FacilityTaskRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<FacilityTask> facilityTaskRowMapper = (rs, rowNum) -> new FacilityTask(
            rs.getInt("facilitytask_id"),
            rs.getInt("facility_id"),
            rs.getObject("assigned_employee_id") != null ? rs.getInt("assigned_employee_id") : null,
            rs.getString("description"),
            rs.getObject("assigned_time", LocalDateTime.class),
            rs.getObject("completed_time", LocalDateTime.class),
            rs.getString("status")
    );

    public List<FacilityTask> findAll() {
        String sql = "SELECT * FROM FacilityTask";
        return jdbcTemplate.query(sql, facilityTaskRowMapper);
    }

    public Optional<FacilityTask> findById(int facilitytaskId) {
        String sql = "SELECT * FROM FacilityTask WHERE facilitytask_id = ?";
        List<FacilityTask> tasks = jdbcTemplate.query(sql, facilityTaskRowMapper, facilitytaskId);
        return tasks.isEmpty() ? Optional.empty() : Optional.of(tasks.get(0));
    }

    public List<FacilityTask> findByFacilityId(int facilityId) {
        String sql = "SELECT * FROM FacilityTask WHERE facility_id = ?";
        return jdbcTemplate.query(sql, facilityTaskRowMapper, facilityId);
    }

    public int save(FacilityTask task) {
        String sql = "INSERT INTO FacilityTask (facility_id, assigned_employee_id, description, completed_time, status) VALUES (?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                task.facilityId(),
                task.assignedEmployeeId(),
                task.description(),
                task.completedTime(),
                task.status()
        );
    }

    public int update(FacilityTask task) {
        String sql = "UPDATE FacilityTask SET facility_id = ?, assigned_employee_id = ?, description = ?, completed_time = ?, status = ? WHERE facilitytask_id = ?";
        return jdbcTemplate.update(sql,
                task.facilityId(),
                task.assignedEmployeeId(),
                task.description(),
                task.completedTime(),
                task.status(),
                task.facilitytaskId()
        );
    }
}
