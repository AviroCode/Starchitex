package com.starchitex.backend.repository;

import com.starchitex.backend.model.Role;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class RoleRepository {

    private final JdbcTemplate jdbcTemplate;

    public RoleRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Role> roleRowMapper = (rs, rowNum) -> new Role(
            rs.getInt("role_id"),
            rs.getString("role_name"),
            rs.getString("description")
    );

    public List<Role> findAll() {
        String sql = "SELECT * FROM Role";
        return jdbcTemplate.query(sql, roleRowMapper);
    }

    public Optional<Role> findById(int id) {
        String sql = "SELECT * FROM Role WHERE role_id = ?";
        List<Role> roles = jdbcTemplate.query(sql, roleRowMapper, id);
        return roles.isEmpty() ? Optional.empty() : Optional.of(roles.get(0));
    }

    public int save(Role role) {
        String sql = "INSERT INTO Role (role_name, description) VALUES (?, ?)";
        return jdbcTemplate.update(sql,
                role.roleName(),
                role.description()
        );
    }

    public int update(Role role) {
        String sql = "UPDATE Role SET role_name = ?, description = ? WHERE role_id = ?";
        return jdbcTemplate.update(sql,
                role.roleName(),
                role.description(),
                role.roleId()
        );
    }
}
