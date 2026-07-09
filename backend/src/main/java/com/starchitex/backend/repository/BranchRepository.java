package com.starchitex.backend.repository;

import com.starchitex.backend.model.Branch;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class BranchRepository {

    private final JdbcTemplate jdbcTemplate;

    public BranchRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // RowMapper explicitly mapping SQL columns to the Branch Record
    private final RowMapper<Branch> branchRowMapper = (rs, rowNum) -> new Branch(
            rs.getInt("branch_id"),
            rs.getString("name"),
            rs.getString("address"),
            rs.getString("city"),
            rs.getString("province"),
            rs.getString("postal_code"),
            rs.getString("email"),
            rs.getString("phone"),
            rs.getString("status"));

    public List<Branch> findAll() {
        String sql = "SELECT * FROM Branch";
        return jdbcTemplate.query(sql, branchRowMapper);
    }

    public Optional<Branch> findById(int id) {
        String sql = "SELECT * FROM Branch WHERE branch_id = ?";
        List<Branch> branches = jdbcTemplate.query(sql, branchRowMapper, id);
        return branches.isEmpty() ? Optional.empty() : Optional.of(branches.get(0));
    }

    public int save(Branch branch) {
        String sql = "INSERT INTO Branch(name , address , city , province , postal_code , email , phone , status )" +
                "VALUES(?, ?, ?, ?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql, branch.name(), branch.address(), branch.city(), branch.province(),
                branch.postalCode(), branch.email(), branch.phone(), branch.status());
    }

    public int update(Branch branch) {
        String sql = "UPDATE Branch SET name = ? , address = ? , city = ? , province = ? , postal_code = ? , email = ? , phone = ? , status = ? "
                + "WHERE branch_id = ?";
        return jdbcTemplate.update(sql, branch.name(), branch.address(), branch.city(), branch.province(),
                branch.postalCode(), branch.email(), branch.phone(), branch.status(), branch.branchId());
    }
}
