package com.starchitex.backend.model;

import java.time.LocalDateTime;

public record RoomMaintenance(
    Integer roomMaintenanceId,
    Integer roomId,
    Integer reportedBy,
    Integer assignedEmployeeId,
    LocalDateTime reportDate,
    String priority,
    LocalDateTime completionDate,
    String description,
    String status
) {}
