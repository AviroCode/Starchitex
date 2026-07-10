package com.starchitex.backend.controller;

import com.starchitex.backend.model.Employee;
import com.starchitex.backend.service.EmployeeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/employees")
public class EmployeeController {

    private final EmployeeService employeeService;

    public EmployeeController(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    @GetMapping
    public List<Employee> getAllEmployees() {
        return employeeService.getAllEmployees();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Employee> getEmployeeById(@PathVariable int id) {
        return employeeService.getEmployeeById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/branch/{branchId}")
    public List<Employee> getEmployeesByBranchId(@PathVariable int branchId) {
        return employeeService.getEmployeesByBranchId(branchId);
    }

    @PreAuthorize("hasAuthority('ADMIN') or #employee.branchId() == authentication.principal.branchId")
    @PostMapping
    public ResponseEntity<String> createEmployee(@RequestBody Employee employee) {
        boolean isCreated = employeeService.createEmployee(employee);
        if (isCreated) {
            return ResponseEntity.status(201).body("Employee created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create employee.");
        }
    }

    @PreAuthorize("hasAuthority('ADMIN') or #employee.branchId() == authentication.principal.branchId")
    @PutMapping("/{id}")
    public ResponseEntity<String> updateEmployee(@PathVariable int id, @RequestBody Employee employee) {
        Employee employeeToUpdate = new Employee(
                id,
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

        boolean isUpdated = employeeService.updateEmployee(employeeToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Employee updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update employee. Check if ID exists.");
        }
    }
}
