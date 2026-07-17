package com.starchitex.backend.repository;

import com.starchitex.backend.model.Employee;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public class EmployeeRepository {

    private final JdbcTemplate jdbcTemplate;

    public EmployeeRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Employee> employeeRowMapper = (rs, rowNum) -> new Employee(
            rs.getInt("employee_id"),
            rs.getInt("branch_id"),
            rs.getString("first_name"),
            rs.getString("last_name"),
            rs.getString("position"),
            rs.getString("gender"),
            rs.getObject("date_of_birth", LocalDate.class),
            rs.getString("phone"),
            rs.getString("email"),
            rs.getObject("hire_date", LocalDate.class),
            rs.getBigDecimal("salary"),
            rs.getString("employment_status")
    );

    public List<Employee> findAll() {
        String sql = "SELECT * FROM Employee";
        return jdbcTemplate.query(sql, employeeRowMapper);
    }

    public Optional<Employee> findById(int id) {
        String sql = "SELECT * FROM Employee WHERE employee_id = ?";
        List<Employee> employees = jdbcTemplate.query(sql, employeeRowMapper, id);
        return employees.isEmpty() ? Optional.empty() : Optional.of(employees.get(0));
    }

    public List<Employee> findByBranchId(int branchId) {
        String sql = "SELECT * FROM Employee WHERE branch_id = ?";
        return jdbcTemplate.query(sql, employeeRowMapper, branchId);
    }

    public Optional<Employee> findByEmail(String email) {
        String sql = "SELECT * FROM Employee WHERE email = ?";
        List<Employee> employees = jdbcTemplate.query(sql, employeeRowMapper, email);
        return employees.isEmpty() ? Optional.empty() : Optional.of(employees.get(0));
    }

    public int save(Employee employee) {
        String sql = "INSERT INTO Employee (branch_id, first_name, last_name, position, gender, date_of_birth, phone, email, hire_date, salary, employment_status) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                employee.branchId(),
                employee.firstName(),
                employee.lastName(),
                employee.position(),
                employee.gender(),
                employee.dateOfBirth(),
                employee.phone(),
                employee.email(),
                employee.hireDate(),
                employee.salary(),
                employee.employmentStatus()
        );
    }

    public int update(Employee employee) {
        String sql = "UPDATE Employee SET branch_id = ?, first_name = ?, last_name = ?, position = ?, gender = ?, date_of_birth = ?, phone = ?, email = ?, hire_date = ?, salary = ?, employment_status = ? " +
                     "WHERE employee_id = ?";
        return jdbcTemplate.update(sql,
                employee.branchId(),
                employee.firstName(),
                employee.lastName(),
                employee.position(),
                employee.gender(),
                employee.dateOfBirth(),
                employee.phone(),
                employee.email(),
                employee.hireDate(),
                employee.salary(),
                employee.employmentStatus(),
                employee.employeeId()
        );
    }
}
