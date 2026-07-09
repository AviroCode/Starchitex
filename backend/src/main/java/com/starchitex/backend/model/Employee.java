package com.starchitex.backend.model;

import java.time.LocalDate;
import java.math.BigDecimal;

public record Employee(
    Integer employeeId,
    Integer branchId,
    String firstName,
    String lastName,
    String position,
    String gender,
    LocalDate dateOfBirth,
    String phone,
    String email,
    LocalDate hireDate,
    BigDecimal salary,
    String employmentStatus
) {}
