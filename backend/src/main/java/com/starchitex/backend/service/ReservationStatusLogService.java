package com.starchitex.backend.service;

import com.starchitex.backend.model.ReservationStatusLog;
import com.starchitex.backend.repository.ReservationStatusLogRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ReservationStatusLogService {

    private final ReservationStatusLogRepository reservationStatusLogRepository;

    public ReservationStatusLogService(ReservationStatusLogRepository reservationStatusLogRepository) {
        this.reservationStatusLogRepository = reservationStatusLogRepository;
    }

    public List<ReservationStatusLog> getAllStatusLogs() {
        return reservationStatusLogRepository.findAll();
    }

    public Optional<ReservationStatusLog> getStatusLogById(int logId) {
        return reservationStatusLogRepository.findById(logId);
    }

    public List<ReservationStatusLog> getStatusLogsByReservationId(int reservationId) {
        return reservationStatusLogRepository.findByReservationId(reservationId);
    }

    public boolean createStatusLog(ReservationStatusLog log) {
        return reservationStatusLogRepository.save(log) > 0;
    }
}
