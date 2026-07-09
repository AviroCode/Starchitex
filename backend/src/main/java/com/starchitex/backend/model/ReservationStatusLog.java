package com.starchitex.backend.model;

import java.time.LocalDateTime;

public record ReservationStatusLog(
    Integer logId,
    Integer reservationId,
    String status,
    Integer changedByEmployeeId,
    LocalDateTime actionTime,
    String remarks
) {}
