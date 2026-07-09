package com.starchitex.backend.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record Guest(
    Integer guestId,
    String firstName,
    String lastName,
    String gender,
    LocalDate dateOfBirth,
    String nationality,
    String passportNumber,
    String phoneNumber,
    String email,
    String address,
    LocalDateTime createdAt
) {}
