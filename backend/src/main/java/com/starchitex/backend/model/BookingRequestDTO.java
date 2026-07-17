package com.starchitex.backend.model;

import java.time.LocalDate;

public record BookingRequestDTO(
    Integer branchId,
    Integer guestId,
    LocalDate checkInDate,
    LocalDate checkOutDate,
    Integer numOfGuests,
    String specialRequests,
    Integer roomId
) {}
