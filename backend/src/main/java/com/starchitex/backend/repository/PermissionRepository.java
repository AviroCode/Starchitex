package com.starchitex.backend.repository;

import com.starchitex.backend.model.Permission;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class PermissionRepository {

    private final JdbcTemplate jdbcTemplate;

    public PermissionRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Permission> permissionRowMapper = (rs, rowNum) -> new Permission(
            rs.getInt("permission_id"),
            rs.getString("permission_name"),
            rs.getString("description")
    );

    public List<Permission> findAll() {
        String sql = "SELECT * FROM Permission";
        return jdbcTemplate.query(sql, permissionRowMapper);
    }

    public Optional<Permission> findById(int id) {
        String sql = "SELECT * FROM Permission WHERE permission_id = ?";
        List<Permission> permissions = jdbcTemplate.query(sql, permissionRowMapper, id);
        return permissions.isEmpty() ? Optional.empty() : Optional.of(permissions.get(0));
    }

    public int save(Permission permission) {
        String sql = "INSERT INTO Permission (permission_name, description) VALUES (?, ?)";
        return jdbcTemplate.update(sql,
                permission.permissionName(),
                permission.description()
        );
    }

    public int update(Permission permission) {
        String sql = "UPDATE Permission SET permission_name = ?, description = ? WHERE permission_id = ?";
        return jdbcTemplate.update(sql,
                permission.permissionName(),
                permission.description(),
                permission.permissionId()
        );
    }
}
