package com.starchitex.backend.service;

import com.starchitex.backend.model.BookingRequestDTO;
import com.starchitex.backend.model.Reservation;
import com.starchitex.backend.model.ReservationRoom;
import com.starchitex.backend.repository.ReservationRepository;
import com.starchitex.backend.repository.ReservationRoomRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;

import java.util.List;
import java.util.Optional;

@Service
public class ReservationService {

    private final ReservationRepository reservationRepository;
    private final ReservationRoomRepository reservationRoomRepository;

    public ReservationService(ReservationRepository reservationRepository, ReservationRoomRepository reservationRoomRepository) {
        this.reservationRepository = reservationRepository;
        this.reservationRoomRepository = reservationRoomRepository;
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
            "Pending",
            reservation.specialRequests()
        );
        
        return reservationRepository.save(forcedPending) > 0;
    }

    // Combines createReservation + assignRoomToReservation into one
    // transaction. Without this, the guest/staff booking UIs had to make two
    // separate HTTP calls, and a rejected room assignment (double-booked or
    // maintenance-blocked room) left a dangling Pending reservation with no
    // room ever attached. @Transactional here means a trigger rejection on
    // the ReservationRoom insert rolls back the Reservation insert too.
    @Transactional
    public boolean bookRoom(BookingRequestDTO req) {
        if (req.checkOutDate().isBefore(req.checkInDate()) || req.checkOutDate().isEqual(req.checkInDate())) {
            throw new IllegalArgumentException("Check-out must be strictly after check-in");
        }

        Reservation pending = new Reservation(
            null, req.branchId(), req.guestId(), req.checkInDate(), req.checkOutDate(),
            null, null, null, req.numOfGuests(), "Pending", req.specialRequests()
        );

        int reservationId = reservationRepository.saveReturningId(pending);
        return reservationRoomRepository.save(new ReservationRoom(reservationId, req.roomId())) > 0;
    }

    @Transactional
    public boolean confirm(int reservationId) {
        Reservation res = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new IllegalArgumentException("Reservation not found"));
        Reservation updated = new Reservation(
            res.reservationId(), res.branchId(), res.guestId(), res.checkInDate(), res.checkOutDate(),
            res.actualCheckinTime(), res.actualCheckoutTime(), res.bookingDate(), res.numOfGuests(), "Confirmed",
            res.specialRequests()
        );
        return reservationRepository.update(updated) > 0;
    }

    @Transactional
    public boolean checkIn(int reservationId) {
        Reservation res = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new IllegalArgumentException("Reservation not found"));
        Reservation updated = new Reservation(
            res.reservationId(), res.branchId(), res.guestId(), res.checkInDate(), res.checkOutDate(),
            LocalDateTime.now(), res.actualCheckoutTime(), res.bookingDate(), res.numOfGuests(), "Checked In",
            res.specialRequests()
        );
        return reservationRepository.update(updated) > 0;
    }

    @Transactional
    public boolean checkOut(int reservationId) {
        Reservation res = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new IllegalArgumentException("Reservation not found"));
        Reservation updated = new Reservation(
            res.reservationId(), res.branchId(), res.guestId(), res.checkInDate(), res.checkOutDate(),
            res.actualCheckinTime(), LocalDateTime.now(), res.bookingDate(), res.numOfGuests(), "Checked Out",
            res.specialRequests()
        );
        return reservationRepository.update(updated) > 0;
    }

    @Transactional
    public boolean cancel(int reservationId) {
        Reservation res = reservationRepository.findById(reservationId)
            .orElseThrow(() -> new IllegalArgumentException("Reservation not found"));
        Reservation updated = new Reservation(
            res.reservationId(), res.branchId(), res.guestId(), res.checkInDate(), res.checkOutDate(),
            res.actualCheckinTime(), res.actualCheckoutTime(), res.bookingDate(), res.numOfGuests(), "Cancelled",
            res.specialRequests()
        );
        return reservationRepository.update(updated) > 0;
    }
}
