package com.starchitex.backend.service;

import com.starchitex.backend.model.Reservation;
import com.starchitex.backend.repository.ReservationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;

import java.util.List;
import java.util.Optional;

@Service
public class ReservationService {

    private final ReservationRepository reservationRepository;

    public ReservationService(ReservationRepository reservationRepository) {
        this.reservationRepository = reservationRepository;
    }

    public List<Reservation> getAllReservations() {
        return reservationRepository.findAll();
    }

    public Optional<Reservation> getReservationById(int reservationId) {
        return reservationRepository.findById(reservationId);
    }
    
    public List<Reservation> getReservationsByGuestId(int guestId) {
        return reservationRepository.findByGuestId(guestId);
    }

    @Transactional
    public boolean createReservation(Reservation reservation) {
        if (reservation.checkOutDate().isBefore(reservation.checkInDate()) || reservation.checkOutDate().isEqual(reservation.checkInDate())) {
            throw new IllegalArgumentException("Check-out must be strictly after check-in");
        }
        
        Reservation forcedPending = new Reservation(
            reservation.reservationId(),
            reservation.branchId(),
            reservation.guestId(),
            reservation.checkInDate(),
            reservation.checkOutDate(),
            reservation.actualCheckinTime(),
            reservation.actualCheckoutTime(),
            reservation.bookingDate(),
            reservation.numOfGuests(),
            "Pending"
        );
        
        return reservationRepository.save(forcedPending) > 0;
    }

    @Transactional
    public boolean checkIn(int reservationId) {
        Reservation res = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new IllegalArgumentException("Reservation not found"));
        if (!res.status().equals("Confirmed")) {
            throw new IllegalStateException("Only Confirmed reservations can be checked in.");
        }
        Reservation updated = new Reservation(
            res.reservationId(), res.branchId(), res.guestId(), res.checkInDate(), res.checkOutDate(),
            LocalDateTime.now(), res.actualCheckoutTime(), res.bookingDate(), res.numOfGuests(), "Checked In"
        );
        return reservationRepository.update(updated) > 0;
    }

    @Transactional
    public boolean checkOut(int reservationId) {
        Reservation res = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new IllegalArgumentException("Reservation not found"));
        if (!res.status().equals("Checked In")) {
            throw new IllegalStateException("Only Checked In reservations can be checked out.");
        }
        Reservation updated = new Reservation(
            res.reservationId(), res.branchId(), res.guestId(), res.checkInDate(), res.checkOutDate(),
            res.actualCheckinTime(), LocalDateTime.now(), res.bookingDate(), res.numOfGuests(), "Checked Out"
        );
        return reservationRepository.update(updated) > 0;
    }

    @Transactional
    public boolean cancel(int reservationId) {
        Reservation res = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new IllegalArgumentException("Reservation not found"));
        if (res.status().equals("Checked In") || res.status().equals("Checked Out")) {
            throw new IllegalStateException("Cannot cancel a reservation that has already started.");
        }
        Reservation updated = new Reservation(
            res.reservationId(), res.branchId(), res.guestId(), res.checkInDate(), res.checkOutDate(),
            res.actualCheckinTime(), res.actualCheckoutTime(), res.bookingDate(), res.numOfGuests(), "Cancelled"
        );
        return reservationRepository.update(updated) > 0;
    }
}
