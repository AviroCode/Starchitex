package com.starchitex.backend.controller;

import com.starchitex.backend.model.EmployeeCredentials;
import com.starchitex.backend.service.EmployeeCredentialsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/employee-credentials")
public class EmployeeCredentialsController {

    private final EmployeeCredentialsService employeeCredentialsService;

    public EmployeeCredentialsController(EmployeeCredentialsService employeeCredentialsService) {
        this.employeeCredentialsService = employeeCredentialsService;
    }

    @GetMapping
    public List<EmployeeCredentials> getAllCredentials() {
        return employeeCredentialsService.getAllCredentials();
    }

    @GetMapping("/{employeeId}")
    public ResponseEntity<EmployeeCredentials> getCredentialsById(@PathVariable int employeeId) {
        return employeeCredentialsService.getCredentialsById(employeeId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<String> createCredentials(@RequestBody EmployeeCredentials credentials) {
        boolean isCreated = employeeCredentialsService.createCredentials(credentials);
        if (isCreated) {
            return ResponseEntity.status(201).body("Credentials created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create credentials.");
        }
    }

    @PutMapping("/{employeeId}/password")
    public ResponseEntity<String> updatePassword(@PathVariable int employeeId, @RequestBody String newPasswordHash) {
        boolean isUpdated = employeeCredentialsService.updatePassword(employeeId, newPasswordHash);
        if (isUpdated) {
            return ResponseEntity.ok("Password updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update password.");
        }
    }
    
    @PutMapping("/{employeeId}/login")
    public ResponseEntity<String> recordLogin(@PathVariable int employeeId) {
        boolean isUpdated = employeeCredentialsService.updateLastLogin(employeeId, LocalDateTime.now());
        if (isUpdated) {
            return ResponseEntity.ok("Login time recorded successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to record login time.");
        }
    }
}
