package com.starchitex.backend.model;

import java.time.LocalDateTime;

public record FacilityBooking(
    Integer facilityBookingId,
    Integer reservationId,
    Integer facilityId,
    LocalDateTime bookingDate,
    LocalDateTime startDateTime,
    LocalDateTime endDateTime
) {}
