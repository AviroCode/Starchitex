package com.starchitex.backend.controller;

import com.starchitex.backend.model.FacilityBooking;
import com.starchitex.backend.service.FacilityBookingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/facility-bookings")
public class FacilityBookingController {

    private final FacilityBookingService facilityBookingService;

    public FacilityBookingController(FacilityBookingService facilityBookingService) {
        this.facilityBookingService = facilityBookingService;
    }

    @GetMapping
    public List<FacilityBooking> getAllBookings() {
        return facilityBookingService.getAllBookings();
    }

    @GetMapping("/{bookingId}")
    public ResponseEntity<FacilityBooking> getBookingById(@PathVariable int bookingId) {
        return facilityBookingService.getBookingById(bookingId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/reservation/{reservationId}")
    public List<FacilityBooking> getBookingsByReservationId(@PathVariable int reservationId) {
        return facilityBookingService.getBookingsByReservationId(reservationId);
    }

    @PostMapping
    public ResponseEntity<String> createBooking(@RequestBody FacilityBooking booking) {
        boolean isCreated = facilityBookingService.createBooking(booking);
        if (isCreated) {
            return ResponseEntity.status(201).body("Facility booking created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create facility booking.");
        }
    }

    @PutMapping("/{bookingId}")
    public ResponseEntity<String> updateBooking(@PathVariable int bookingId, @RequestBody FacilityBooking booking) {
        FacilityBooking bookingToUpdate = new FacilityBooking(
                bookingId,
                booking.reservationId(),
                booking.facilityId(),
                booking.bookingDate(),
                booking.startDateTime(),
                booking.endDateTime()
        );

        boolean isUpdated = facilityBookingService.updateBooking(bookingToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Facility booking updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update facility booking. Check if ID exists.");
        }
    }
}
