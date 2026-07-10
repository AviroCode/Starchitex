package com.starchitex.backend.repository;

import com.starchitex.backend.model.Permission;
import com.starchitex.backend.model.Role;
import com.starchitex.backend.model.RolePermission;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class RolePermissionRepository {

    private final JdbcTemplate jdbcTemplate;

    public RolePermissionRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<RolePermission> rolePermissionRowMapper = (rs, rowNum) -> new RolePermission(
            rs.getInt("role_id"),
            rs.getInt("permission_id")
    );

    private final RowMapper<Permission> permissionRowMapper = (rs, rowNum) -> new Permission(
            rs.getInt("permission_id"),
            rs.getString("permission_name"),
            rs.getString("description")
    );

    private final RowMapper<Role> roleRowMapper = (rs, rowNum) -> new Role(
            rs.getInt("role_id"),
            rs.getString("role_name"),
            rs.getString("description")
    );

    public List<RolePermission> findAll() {
        String sql = "SELECT * FROM RolePermission";
        return jdbcTemplate.query(sql, rolePermissionRowMapper);
    }

    public List<Permission> findPermissionsByRoleId(int roleId) {
        String sql = "SELECT p.* FROM Permission p JOIN RolePermission rp ON p.permission_id = rp.permission_id WHERE rp.role_id = ?";
        return jdbcTemplate.query(sql, permissionRowMapper, roleId);
    }

    public List<Role> findRolesByPermissionId(int permissionId) {
        String sql = "SELECT r.* FROM Role r JOIN RolePermission rp ON r.role_id = rp.role_id WHERE rp.permission_id = ?";
        return jdbcTemplate.query(sql, roleRowMapper, permissionId);
    }

    public int save(RolePermission rolePermission) {
        String sql = "INSERT INTO RolePermission (role_id, permission_id) VALUES (?, ?)";
        return jdbcTemplate.update(sql,
                rolePermission.roleId(),
                rolePermission.permissionId()
        );
    }

    public int delete(int roleId, int permissionId) {
        String sql = "DELETE FROM RolePermission WHERE role_id = ? AND permission_id = ?";
        return jdbcTemplate.update(sql, roleId, permissionId);
    }
}
