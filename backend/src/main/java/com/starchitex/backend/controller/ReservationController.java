package com.starchitex.backend.controller;

import com.starchitex.backend.model.Reservation;
import com.starchitex.backend.service.ReservationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/reservations")
public class ReservationController {

    private final ReservationService reservationService;

    public ReservationController(ReservationService reservationService) {
        this.reservationService = reservationService;
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @GetMapping
    public List<Reservation> getAllReservations() {
        return reservationService.getAllReservations();
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @GetMapping("/{reservationId}")
    public ResponseEntity<Reservation> getReservationById(@PathVariable int reservationId) {
        return reservationService.getReservationById(reservationId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    // Staff or the guest themselves can list a guest's reservations
    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null or #guestId == authentication.principal.guestId")
    @GetMapping("/guest/{guestId}")
    public List<Reservation> getReservationsByGuestId(@PathVariable int guestId) {
        return reservationService.getReservationsByGuestId(guestId);
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null or authentication.principal.guestId != null")
    @PostMapping
    public ResponseEntity<String> createReservation(@RequestBody Reservation reservation) {
        boolean isCreated = reservationService.createReservation(reservation);
        if (isCreated) {
            return ResponseEntity.status(201).body("Reservation created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create reservation.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null or authentication.principal.guestId != null")
    @PostMapping("/{reservationId}/confirm")
    public ResponseEntity<String> confirm(@PathVariable int reservationId) {
        try {
            boolean success = reservationService.confirm(reservationId);
            return success ? ResponseEntity.ok("Confirmed successfully!") : ResponseEntity.badRequest().body("Confirm failed.");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // Staff-only: a guest arriving and leaving is verified in person at the
    // front desk, not self-served — unlike confirm/cancel, this isn't
    // something a guest should be able to do to their own reservation.
    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping("/{reservationId}/check-in")
    public ResponseEntity<String> checkIn(@PathVariable int reservationId) {
        try {
            boolean success = reservationService.checkIn(reservationId);
            return success ? ResponseEntity.ok("Checked in successfully!") : ResponseEntity.badRequest().body("Check-in failed.");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // Staff-only — same reasoning as check-in above.
    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping("/{reservationId}/check-out")
    public ResponseEntity<String> checkOut(@PathVariable int reservationId) {
        try {
            boolean success = reservationService.checkOut(reservationId);
            return success ? ResponseEntity.ok("Checked out successfully!") : ResponseEntity.badRequest().body("Check-out failed.");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null or authentication.principal.guestId != null")
    @PostMapping("/{reservationId}/cancel")
    public ResponseEntity<String> cancel(@PathVariable int reservationId) {
        try {
            boolean success = reservationService.cancel(reservationId);
            return success ? ResponseEntity.ok("Cancelled successfully!") : ResponseEntity.badRequest().body("Cancellation failed.");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}