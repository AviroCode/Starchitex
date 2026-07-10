package com.starchitex.backend.repository;

import com.starchitex.backend.model.GuestCredentials;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class GuestCredentialsRepository {

    private final JdbcTemplate jdbcTemplate;

    public GuestCredentialsRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<GuestCredentials> guestCredentialsRowMapper = (rs, rowNum) -> new GuestCredentials(
            rs.getInt("guest_cred_id"),
            rs.getInt("guest_id"),
            rs.getString("username"),
            rs.getString("password_hash"),
            rs.getInt("role_id"),
            rs.getObject("created_at", LocalDateTime.class),
            rs.getObject("last_login", LocalDateTime.class)
    );

    public List<GuestCredentials> findAll() {
        String sql = "SELECT * FROM GuestCredentials";
        return jdbcTemplate.query(sql, guestCredentialsRowMapper);
    }

    public Optional<GuestCredentials> findById(int guestCredId) {
        String sql = "SELECT * FROM GuestCredentials WHERE guest_cred_id = ?";
        List<GuestCredentials> creds = jdbcTemplate.query(sql, guestCredentialsRowMapper, guestCredId);
        return creds.isEmpty() ? Optional.empty() : Optional.of(creds.get(0));
    }
    
    public Optional<GuestCredentials> findByGuestId(int guestId) {
        String sql = "SELECT * FROM GuestCredentials WHERE guest_id = ?";
        List<GuestCredentials> creds = jdbcTemplate.query(sql, guestCredentialsRowMapper, guestId);
        return creds.isEmpty() ? Optional.empty() : Optional.of(creds.get(0));
    }

    public Optional<GuestCredentials> findByUsername(String username) {
        String sql = "SELECT * FROM GuestCredentials WHERE username = ?";
        List<GuestCredentials> creds = jdbcTemplate.query(sql, guestCredentialsRowMapper, username);
        return creds.isEmpty() ? Optional.empty() : Optional.of(creds.get(0));
    }

    public int save(GuestCredentials credentials) {
        String sql = "INSERT INTO GuestCredentials (guest_id, username, password_hash, role_id) VALUES (?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                credentials.guestId(),
                credentials.username(),
                credentials.passwordHash(),
                credentials.roleId()
        );
    }

    public int updatePassword(int guestCredId, String newPasswordHash) {
        String sql = "UPDATE GuestCredentials SET password_hash = ? WHERE guest_cred_id = ?";
        return jdbcTemplate.update(sql, newPasswordHash, guestCredId);
    }

    public int updateLastLogin(int guestCredId, LocalDateTime lastLogin) {
        String sql = "UPDATE GuestCredentials SET last_login = ? WHERE guest_cred_id = ?";
        return jdbcTemplate.update(sql, lastLogin, guestCredId);
    }
}
