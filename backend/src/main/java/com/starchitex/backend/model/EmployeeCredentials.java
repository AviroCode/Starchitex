package com.starchitex.backend.model;

import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonIgnore;

public record EmployeeCredentials(
    Integer employeeId,
    String username,
    @JsonIgnore String passwordHash,
    Integer roleId,
    LocalDateTime createdAt,
    LocalDateTime lastLogin
) {}
