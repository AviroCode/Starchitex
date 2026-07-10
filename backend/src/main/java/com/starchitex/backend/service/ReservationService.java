package com.starchitex.backend.service;

import com.starchitex.backend.model.Reservation;
import com.starchitex.backend.repository.ReservationRepository;
import org.springframework.stereotype.Service;

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

    public boolean createReservation(Reservation reservation) {
        return reservationRepository.save(reservation) > 0;
    }

    public boolean updateReservation(Reservation reservation) {
        return reservationRepository.update(reservation) > 0;
    }
}
