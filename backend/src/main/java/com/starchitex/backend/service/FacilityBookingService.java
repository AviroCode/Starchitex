package com.starchitex.backend.service;

import com.starchitex.backend.model.FacilityBooking;
import com.starchitex.backend.repository.FacilityBookingRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class FacilityBookingService {

    private final FacilityBookingRepository facilityBookingRepository;

    public FacilityBookingService(FacilityBookingRepository facilityBookingRepository) {
        this.facilityBookingRepository = facilityBookingRepository;
    }

    public List<FacilityBooking> getAllBookings() {
        return facilityBookingRepository.findAll();
    }

    public Optional<FacilityBooking> getBookingById(int bookingId) {
        return facilityBookingRepository.findById(bookingId);
    }

    public List<FacilityBooking> getBookingsByReservationId(int reservationId) {
        return facilityBookingRepository.findByReservationId(reservationId);
    }

    public boolean createBooking(FacilityBooking booking) {
        return facilityBookingRepository.save(booking) > 0;
    }

    public boolean updateBooking(FacilityBooking booking) {
        return facilityBookingRepository.update(booking) > 0;
    }
}
