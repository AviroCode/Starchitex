package com.starchitex.backend.model;

import java.time.LocalDateTime;

public record FacilityTask(
    Integer facilitytaskId,
    Integer facilityId,
    Integer assignedEmployeeId,
    String description,
    LocalDateTime assignedTime,
    LocalDateTime completedTime,
    String status
) {}
