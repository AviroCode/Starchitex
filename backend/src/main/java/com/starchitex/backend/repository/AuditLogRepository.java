package com.starchitex.backend.repository;

import com.starchitex.backend.model.AuditLog;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public class AuditLogRepository {

    private final JdbcTemplate jdbcTemplate;

    public AuditLogRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<AuditLog> auditLogRowMapper = (rs, rowNum) -> new AuditLog(
            rs.getInt("log_id"),
            rs.getObject("employee_id") != null ? rs.getInt("employee_id") : null,
            rs.getString("action"),
            rs.getString("table_name"),
            rs.getString("pk_of_table"),
            rs.getString("affected_col"),
            rs.getObject("action_time", LocalDateTime.class),
            rs.getString("old_value"),
            rs.getString("new_value"),
            rs.getString("IP_address")
    );

    public List<AuditLog> findAll() {
        String sql = "SELECT * FROM AuditLog";
        return jdbcTemplate.query(sql, auditLogRowMapper);
    }
    
    public List<AuditLog> findByEmployeeId(int employeeId) {
        String sql = "SELECT * FROM AuditLog WHERE employee_id = ?";
        return jdbcTemplate.query(sql, auditLogRowMapper, employeeId);
    }
    
    public List<AuditLog> findByTableName(String tableName) {
        String sql = "SELECT * FROM AuditLog WHERE table_name = ?";
        return jdbcTemplate.query(sql, auditLogRowMapper, tableName);
    }

    public int save(AuditLog log) {
        String sql = "INSERT INTO AuditLog (employee_id, action, table_name, pk_of_table, affected_col, old_value, new_value, IP_address) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                log.employeeId(),
                log.action(),
                log.tableName(),
                log.pkOfTable(),
                log.affectedCol(),
                log.oldValue(),
                log.newValue(),
                log.ipAddress()
        );
    }
}
