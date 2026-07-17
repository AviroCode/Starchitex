package com.starchitex.backend.model;

import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonProperty;

public record EmployeeCredentials(
    Integer employeeId,
    String username,
    // WRITE_ONLY (not @JsonIgnore): the raw password must still be readable
    // from an incoming POST body (createCredentials hashes it), but the
    // stored hash must never be echoed back in any GET response.
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY) String passwordHash,
    Integer roleId,
    LocalDateTime createdAt,
    LocalDateTime lastLogin
) {}
