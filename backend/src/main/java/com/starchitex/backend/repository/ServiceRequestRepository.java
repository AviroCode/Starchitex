package com.starchitex.backend.repository;

import com.starchitex.backend.model.ServiceRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class ServiceRequestRepository {

    private final JdbcTemplate jdbcTemplate;

    public ServiceRequestRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<ServiceRequest> serviceRequestRowMapper = (rs, rowNum) -> new ServiceRequest(
            rs.getInt("request_id"),
            rs.getInt("reservation_id"),
            rs.getInt("service_id"),
            rs.getString("description"),
            rs.getObject("request_date", LocalDateTime.class),
            rs.getString("status"),
            rs.getObject("handled_by") != null ? rs.getInt("handled_by") : null
    );

    public List<ServiceRequest> findAll() {
        String sql = "SELECT * FROM ServiceRequest";
        return jdbcTemplate.query(sql, serviceRequestRowMapper);
    }

    public Optional<ServiceRequest> findById(int requestId) {
        String sql = "SELECT * FROM ServiceRequest WHERE request_id = ?";
        List<ServiceRequest> requests = jdbcTemplate.query(sql, serviceRequestRowMapper, requestId);
        return requests.isEmpty() ? Optional.empty() : Optional.of(requests.get(0));
    }

    public List<ServiceRequest> findByReservationId(int reservationId) {
        String sql = "SELECT * FROM ServiceRequest WHERE reservation_id = ?";
        return jdbcTemplate.query(sql, serviceRequestRowMapper, reservationId);
    }

    public int save(ServiceRequest request) {
        String sql = "INSERT INTO ServiceRequest (reservation_id, service_id, description, status, handled_by) VALUES (?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                request.reservationId(),
                request.serviceId(),
                request.description(),
                request.status(),
                request.handledBy()
        );
    }

    public int update(ServiceRequest request) {
        String sql = "UPDATE ServiceRequest SET reservation_id = ?, service_id = ?, description = ?, status = ?, handled_by = ? WHERE request_id = ?";
        return jdbcTemplate.update(sql,
                request.reservationId(),
                request.serviceId(),
                request.description(),
                request.status(),
                request.handledBy(),
                request.requestId()
        );
    }
}
