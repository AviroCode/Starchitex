package com.starchitex.backend.repository;

import com.starchitex.backend.model.Service;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class ServiceRepository {

    private final JdbcTemplate jdbcTemplate;

    public ServiceRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // RowMapper specifically handling BigDecimal mapping for preserving precise currency numbers
    private final RowMapper<Service> serviceRowMapper = (rs, rowNum) -> new Service(
            rs.getInt("service_id"),
            rs.getString("service_name"),
            rs.getString("category"),
            rs.getBigDecimal("price"),
            rs.getString("description")
    );

    public List<Service> findAll() {
        String sql = "SELECT * FROM Service";
        return jdbcTemplate.query(sql, serviceRowMapper);
    }

    public Optional<Service> findById(int id) {
        String sql = "SELECT * FROM Service WHERE service_id = ?";
        List<Service> services = jdbcTemplate.query(sql, serviceRowMapper, id);
        return services.isEmpty() ? Optional.empty() : Optional.of(services.get(0));
    }

    public int save(Service service) {
        String sql = "INSERT INTO Service (service_name, category, price, description) VALUES (?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                service.serviceName(),
                service.category(),
                service.price(),
                service.description()
        );
    }

    public int update(Service service) {
        String sql = "UPDATE Service SET service_name = ?, category = ?, price = ?, description = ? WHERE service_id = ?";
        return jdbcTemplate.update(sql,
                service.serviceName(),
                service.category(),
                service.price(),
                service.description(),
                service.serviceId()
        );
    }
}
