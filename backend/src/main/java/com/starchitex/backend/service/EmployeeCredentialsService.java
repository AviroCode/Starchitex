package com.starchitex.backend.service;

import com.starchitex.backend.model.EmployeeCredentials;
import com.starchitex.backend.repository.EmployeeCredentialsRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class EmployeeCredentialsService {

    private final EmployeeCredentialsRepository employeeCredentialsRepository;

    public EmployeeCredentialsService(EmployeeCredentialsRepository employeeCredentialsRepository) {
        this.employeeCredentialsRepository = employeeCredentialsRepository;
    }

    public List<EmployeeCredentials> getAllCredentials() {
        return employeeCredentialsRepository.findAll();
    }

    public Optional<EmployeeCredentials> getCredentialsById(int employeeId) {
        return employeeCredentialsRepository.findById(employeeId);
    }

    public Optional<EmployeeCredentials> getCredentialsByUsername(String username) {
        return employeeCredentialsRepository.findByUsername(username);
    }

    public boolean createCredentials(EmployeeCredentials credentials) {
        return employeeCredentialsRepository.save(credentials) > 0;
    }

    public boolean updatePassword(int employeeId, String newPasswordHash) {
        return employeeCredentialsRepository.updatePassword(employeeId, newPasswordHash) > 0;
    }

    public boolean updateLastLogin(int employeeId, LocalDateTime lastLogin) {
        return employeeCredentialsRepository.updateLastLogin(employeeId, lastLogin) > 0;
    }
}
