package com.starchitex.backend.model;

import java.time.LocalDate;
import java.math.BigDecimal;

public record RoomAvailability(
    Integer availabilityId,
    Integer roomId,
    LocalDate calendarDate,
    String status,
    Integer reservationId,
    BigDecimal priceOverride
) {}
