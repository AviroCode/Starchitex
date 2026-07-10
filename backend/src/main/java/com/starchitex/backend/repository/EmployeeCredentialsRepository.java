package com.starchitex.backend.repository;

import com.starchitex.backend.model.EmployeeCredentials;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class EmployeeCredentialsRepository {

    private final JdbcTemplate jdbcTemplate;

    public EmployeeCredentialsRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<EmployeeCredentials> employeeCredentialsRowMapper = (rs, rowNum) -> new EmployeeCredentials(
            rs.getInt("employee_id"),
            rs.getString("username"),
            rs.getString("password_hash"),
            rs.getInt("role_id"),
            rs.getObject("created_at", LocalDateTime.class),
            rs.getObject("last_login", LocalDateTime.class)
    );

    public List<EmployeeCredentials> findAll() {
        String sql = "SELECT * FROM EmployeeCredentials";
        return jdbcTemplate.query(sql, employeeCredentialsRowMapper);
    }

    public Optional<EmployeeCredentials> findById(int employeeId) {
        String sql = "SELECT * FROM EmployeeCredentials WHERE employee_id = ?";
        List<EmployeeCredentials> creds = jdbcTemplate.query(sql, employeeCredentialsRowMapper, employeeId);
        return creds.isEmpty() ? Optional.empty() : Optional.of(creds.get(0));
    }

    public Optional<EmployeeCredentials> findByUsername(String username) {
        String sql = "SELECT * FROM EmployeeCredentials WHERE username = ?";
        List<EmployeeCredentials> creds = jdbcTemplate.query(sql, employeeCredentialsRowMapper, username);
        return creds.isEmpty() ? Optional.empty() : Optional.of(creds.get(0));
    }

    public int save(EmployeeCredentials credentials) {
        String sql = "INSERT INTO EmployeeCredentials (employee_id, username, password_hash, role_id) VALUES (?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                credentials.employeeId(),
                credentials.username(),
                credentials.passwordHash(),
                credentials.roleId()
        );
    }

    public int updatePassword(int employeeId, String newPasswordHash) {
        String sql = "UPDATE EmployeeCredentials SET password_hash = ? WHERE employee_id = ?";
        return jdbcTemplate.update(sql, newPasswordHash, employeeId);
    }

    public int updateLastLogin(int employeeId, LocalDateTime lastLogin) {
        String sql = "UPDATE EmployeeCredentials SET last_login = ? WHERE employee_id = ?";
        return jdbcTemplate.update(sql, lastLogin, employeeId);
    }
}
