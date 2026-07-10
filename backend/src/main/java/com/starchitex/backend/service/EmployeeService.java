package com.starchitex.backend.service;

import com.starchitex.backend.model.Employee;
import com.starchitex.backend.repository.EmployeeRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class EmployeeService {

    private final EmployeeRepository employeeRepository;

    public EmployeeService(EmployeeRepository employeeRepository) {
        this.employeeRepository = employeeRepository;
    }

    public List<Employee> getAllEmployees() {
        return employeeRepository.findAll();
    }

    public Optional<Employee> getEmployeeById(int id) {
        return employeeRepository.findById(id);
    }

    public List<Employee> getEmployeesByBranchId(int branchId) {
        return employeeRepository.findByBranchId(branchId);
    }

    public boolean createEmployee(Employee employee) {
        return employeeRepository.save(employee) > 0;
    }

    public boolean updateEmployee(Employee employee) {
        return employeeRepository.update(employee) > 0;
    }
}
