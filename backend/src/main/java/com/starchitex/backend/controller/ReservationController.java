package com.starchitex.backend.controller;

import com.starchitex.backend.model.Reservation;
import com.starchitex.backend.service.ReservationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reservations")
public class ReservationController {

    private final ReservationService reservationService;

    public ReservationController(ReservationService reservationService) {
        this.reservationService = reservationService;
    }

    @GetMapping
    public List<Reservation> getAllReservations() {
        return reservationService.getAllReservations();
    }

    @GetMapping("/{reservationId}")
    public ResponseEntity<Reservation> getReservationById(@PathVariable int reservationId) {
        return reservationService.getReservationById(reservationId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/guest/{guestId}")
    public List<Reservation> getReservationsByGuestId(@PathVariable int guestId) {
        return reservationService.getReservationsByGuestId(guestId);
    }

    @PostMapping
    public ResponseEntity<String> createReservation(@RequestBody Reservation reservation) {
        boolean isCreated = reservationService.createReservation(reservation);
        if (isCreated) {
            return ResponseEntity.status(201).body("Reservation created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create reservation.");
        }
    }

    @PutMapping("/{reservationId}")
    public ResponseEntity<String> updateReservation(@PathVariable int reservationId, @RequestBody Reservation reservation) {
        Reservation reservationToUpdate = new Reservation(
                reservationId,
                reservation.branchId(),
                reservation.guestId(),
                reservation.checkInDate(),
                reservation.checkOutDate(),
                reservation.actualCheckinTime(),
                reservation.actualCheckoutTime(),
                reservation.bookingDate(),
                reservation.numOfGuests(),
                reservation.status()
        );

        boolean isUpdated = reservationService.updateReservation(reservationToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Reservation updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update reservation. Check if ID exists.");
        }
    }
}
