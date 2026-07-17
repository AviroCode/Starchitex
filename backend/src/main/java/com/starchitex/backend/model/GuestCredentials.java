package com.starchitex.backend.model;

import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonProperty;

public record GuestCredentials(
    Integer guestCredId,
    Integer guestId,
    String username,
    // WRITE_ONLY: readable from an incoming POST body, never echoed back in
    // a GET response (this previously had no annotation at all, so every
    // GET leaked the bcrypt hash — matches EmployeeCredentials' pattern).
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY) String passwordHash,
    Integer roleId,
    LocalDateTime createdAt,
    LocalDateTime lastLogin
) {}
