package com.starchitex.backend.repository;

import com.starchitex.backend.model.FacilityMaintenance;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class FacilityMaintenanceRepository {

    private final JdbcTemplate jdbcTemplate;

    public FacilityMaintenanceRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<FacilityMaintenance> facilityMaintenanceRowMapper = (rs, rowNum) -> new FacilityMaintenance(
            rs.getInt("facility_maintenance_id"),
            rs.getInt("facility_id"),
            rs.getObject("reported_by") != null ? rs.getInt("reported_by") : null,
            rs.getObject("assigned_employee_id") != null ? rs.getInt("assigned_employee_id") : null,
            rs.getObject("report_date", LocalDateTime.class),
            rs.getString("priority"),
            rs.getObject("completion_date", LocalDateTime.class),
            rs.getString("description"),
            rs.getString("status")
    );

    public List<FacilityMaintenance> findAll() {
        String sql = "SELECT * FROM FacilityMaintenance";
        return jdbcTemplate.query(sql, facilityMaintenanceRowMapper);
    }

    public Optional<FacilityMaintenance> findById(int facilityMaintenanceId) {
        String sql = "SELECT * FROM FacilityMaintenance WHERE facility_maintenance_id = ?";
        List<FacilityMaintenance> tickets = jdbcTemplate.query(sql, facilityMaintenanceRowMapper, facilityMaintenanceId);
        return tickets.isEmpty() ? Optional.empty() : Optional.of(tickets.get(0));
    }

    public List<FacilityMaintenance> findByFacilityId(int facilityId) {
        String sql = "SELECT * FROM FacilityMaintenance WHERE facility_id = ?";
        return jdbcTemplate.query(sql, facilityMaintenanceRowMapper, facilityId);
    }

    public int save(FacilityMaintenance maintenance) {
        String sql = "INSERT INTO FacilityMaintenance (facility_id, reported_by, assigned_employee_id, priority, completion_date, description, status) VALUES (?, ?, ?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                maintenance.facilityId(),
                maintenance.reportedBy(),
                maintenance.assignedEmployeeId(),
                maintenance.priority(),
                maintenance.completionDate(),
                maintenance.description(),
                maintenance.status()
        );
    }

    public int update(FacilityMaintenance maintenance) {
        String sql = "UPDATE FacilityMaintenance SET facility_id = ?, reported_by = ?, assigned_employee_id = ?, priority = ?, completion_date = ?, description = ?, status = ? WHERE facility_maintenance_id = ?";
        return jdbcTemplate.update(sql,
                maintenance.facilityId(),
                maintenance.reportedBy(),
                maintenance.assignedEmployeeId(),
                maintenance.priority(),
                maintenance.completionDate(),
                maintenance.description(),
                maintenance.status(),
                maintenance.facilityMaintenanceId()
        );
    }
}
