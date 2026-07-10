package com.starchitex.backend.repository;

import com.starchitex.backend.model.ReservationStatusLog;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class ReservationStatusLogRepository {

    private final JdbcTemplate jdbcTemplate;

    public ReservationStatusLogRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<ReservationStatusLog> reservationStatusLogRowMapper = (rs, rowNum) -> new ReservationStatusLog(
            rs.getInt("log_id"),
            rs.getInt("reservation_id"),
            rs.getString("status"),
            rs.getObject("changed_by_employee_id") != null ? rs.getInt("changed_by_employee_id") : null,
            rs.getObject("action_time", LocalDateTime.class),
            rs.getString("remarks")
    );

    public List<ReservationStatusLog> findAll() {
        String sql = "SELECT * FROM ReservationStatusLog";
        return jdbcTemplate.query(sql, reservationStatusLogRowMapper);
    }

    public Optional<ReservationStatusLog> findById(int logId) {
        String sql = "SELECT * FROM ReservationStatusLog WHERE log_id = ?";
        List<ReservationStatusLog> logs = jdbcTemplate.query(sql, reservationStatusLogRowMapper, logId);
        return logs.isEmpty() ? Optional.empty() : Optional.of(logs.get(0));
    }

    public List<ReservationStatusLog> findByReservationId(int reservationId) {
        String sql = "SELECT * FROM ReservationStatusLog WHERE reservation_id = ?";
        return jdbcTemplate.query(sql, reservationStatusLogRowMapper, reservationId);
    }

    public int save(ReservationStatusLog log) {
        String sql = "INSERT INTO ReservationStatusLog (reservation_id, status, changed_by_employee_id, remarks) VALUES (?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                log.reservationId(),
                log.status(),
                log.changedByEmployeeId(),
                log.remarks()
        );
    }
}
