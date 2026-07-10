package com.starchitex.backend.controller;

import com.starchitex.backend.model.ReservationStatusLog;
import com.starchitex.backend.service.ReservationStatusLogService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reservation-status-logs")
public class ReservationStatusLogController {

    private final ReservationStatusLogService reservationStatusLogService;

    public ReservationStatusLogController(ReservationStatusLogService reservationStatusLogService) {
        this.reservationStatusLogService = reservationStatusLogService;
    }

    @GetMapping
    public List<ReservationStatusLog> getAllStatusLogs() {
        return reservationStatusLogService.getAllStatusLogs();
    }

    @GetMapping("/{logId}")
    public ResponseEntity<ReservationStatusLog> getStatusLogById(@PathVariable int logId) {
        return reservationStatusLogService.getStatusLogById(logId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/reservation/{reservationId}")
    public List<ReservationStatusLog> getStatusLogsByReservationId(@PathVariable int reservationId) {
        return reservationStatusLogService.getStatusLogsByReservationId(reservationId);
    }

    @PostMapping
    public ResponseEntity<String> createStatusLog(@RequestBody ReservationStatusLog log) {
        boolean isCreated = reservationStatusLogService.createStatusLog(log);
        if (isCreated) {
            return ResponseEntity.status(201).body("Reservation status log created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create reservation status log.");
        }
    }
}
