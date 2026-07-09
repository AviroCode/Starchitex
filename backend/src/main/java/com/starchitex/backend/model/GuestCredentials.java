package com.starchitex.backend.model;

import java.time.LocalDateTime;

public record GuestCredentials(
    Integer guestCredId,
    Integer guestId,
    String username,
    String passwordHash,
    Integer roleId,
    LocalDateTime createdAt,
    LocalDateTime lastLogin
) {}
