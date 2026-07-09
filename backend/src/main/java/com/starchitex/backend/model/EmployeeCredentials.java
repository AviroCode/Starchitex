package com.starchitex.backend.model;

import java.time.LocalDateTime;

public record EmployeeCredentials(
    Integer employeeId,
    String username,
    String passwordHash,
    Integer roleId,
    LocalDateTime createdAt,
    LocalDateTime lastLogin
) {}
