package com.starchitex.backend.repository;

import com.starchitex.backend.model.Facility;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class FacilityRepository {

    private final JdbcTemplate jdbcTemplate;

    public FacilityRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Facility> facilityRowMapper = (rs, rowNum) -> new Facility(
            rs.getInt("facility_id"),
            rs.getInt("branch_id"),
            rs.getString("facility_name"),
            rs.getString("description"),
            rs.getObject("capacity") != null ? rs.getInt("capacity") : null,
            rs.getString("location")
    );

    public List<Facility> findAll() {
        String sql = "SELECT * FROM Facility";
        return jdbcTemplate.query(sql, facilityRowMapper);
    }

    public Optional<Facility> findById(int id) {
        String sql = "SELECT * FROM Facility WHERE facility_id = ?";
        List<Facility> facilities = jdbcTemplate.query(sql, facilityRowMapper, id);
        return facilities.isEmpty() ? Optional.empty() : Optional.of(facilities.get(0));
    }

    public List<Facility> findByBranchId(int branchId) {
        String sql = "SELECT * FROM Facility WHERE branch_id = ?";
        return jdbcTemplate.query(sql, facilityRowMapper, branchId);
    }

    public int save(Facility facility) {
        String sql = "INSERT INTO Facility (branch_id, facility_name, description, capacity, location) VALUES (?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                facility.branchId(),
                facility.facilityName(),
                facility.description(),
                facility.capacity(),
                facility.location()
        );
    }

    public int update(Facility facility) {
        String sql = "UPDATE Facility SET branch_id = ?, facility_name = ?, description = ?, capacity = ?, location = ? WHERE facility_id = ?";
        return jdbcTemplate.update(sql,
                facility.branchId(),
                facility.facilityName(),
                facility.description(),
                facility.capacity(),
                facility.location(),
                facility.facilityId()
        );
    }
}
