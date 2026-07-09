package com.starchitex.backend.model;

import java.time.LocalDateTime;

public record FacilityMaintenance(
    Integer facilityMaintenanceId,
    Integer facilityId,
    Integer reportedBy,
    Integer assignedEmployeeId,
    LocalDateTime reportDate,
    String priority,
    LocalDateTime completionDate,
    String description,
    String status
) {}
