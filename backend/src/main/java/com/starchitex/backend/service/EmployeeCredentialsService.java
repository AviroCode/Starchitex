package com.starchitex.backend.service;

import com.starchitex.backend.model.EmployeeCredentials;
import com.starchitex.backend.repository.EmployeeCredentialsRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class EmployeeCredentialsService {

    private final EmployeeCredentialsRepository employeeCredentialsRepository;
    private final PasswordEncoder passwordEncoder;

    public EmployeeCredentialsService(EmployeeCredentialsRepository employeeCredentialsRepository, PasswordEncoder passwordEncoder) {
        this.employeeCredentialsRepository = employeeCredentialsRepository;
        this.passwordEncoder = passwordEncoder;
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
        String hashed = passwordEncoder.encode(credentials.passwordHash());
        EmployeeCredentials securedCreds = new EmployeeCredentials(
                credentials.employeeId(),
                credentials.username(),
                hashed,
                credentials.roleId(),
                credentials.createdAt(),
                credentials.lastLogin()
        );
        return employeeCredentialsRepository.save(securedCreds) > 0;
    }

    public boolean updatePassword(int employeeId, String newPassword) {
        String hashed = passwordEncoder.encode(newPassword);
        return employeeCredentialsRepository.updatePassword(employeeId, hashed) > 0;
    }

    public boolean updateLastLogin(int employeeId, LocalDateTime lastLogin) {
        return employeeCredentialsRepository.updateLastLogin(employeeId, lastLogin) > 0;
    }
}
