package com.starchitex.backend.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record Reservation(
    Integer reservationId,
    Integer guestId,
    LocalDate checkInDate,
    LocalDate checkOutDate,
    LocalDateTime actualCheckinTime,
    LocalDateTime actualCheckoutTime,
    LocalDateTime bookingDate,
    Integer numOfGuests,
    String status
) {}
