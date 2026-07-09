package com.starchitex.backend.model;

import java.time.LocalDateTime;

public record ServiceRequest(
    Integer requestId,
    Integer reservationId,
    Integer serviceId,
    String description,
    LocalDateTime requestDate,
    String status,
    Integer handledBy
) {}
