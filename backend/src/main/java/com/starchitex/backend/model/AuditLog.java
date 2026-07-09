package com.starchitex.backend.model;

import java.time.LocalDateTime;

public record AuditLog(
    Integer logId,
    Integer employeeId,
    String action,
    String tableName,
    String pkOfTable,
    String affectedCol,
    LocalDateTime actionTime,
    String oldValue,
    String newValue,
    String ipAddress
) {}
