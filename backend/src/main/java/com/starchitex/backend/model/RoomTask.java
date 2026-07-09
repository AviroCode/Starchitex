package com.starchitex.backend.model;

import java.time.LocalDateTime;

public record RoomTask(
    Integer roomtaskId,
    Integer roomId,
    Integer assignedEmployeeId,
    String description,
    LocalDateTime assignedTime,
    LocalDateTime completedTime,
    String status
) {}
