package com.starchitex.backend.controller;

import com.starchitex.backend.model.ReservationRoom;
import com.starchitex.backend.model.Room;
import com.starchitex.backend.service.ReservationRoomService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reservation-rooms")
public class ReservationRoomController {

    private final ReservationRoomService reservationRoomService;

    public ReservationRoomController(ReservationRoomService reservationRoomService) {
        this.reservationRoomService = reservationRoomService;
    }

    @GetMapping
    public List<ReservationRoom> getAllReservationRooms() {
        return reservationRoomService.getAllReservationRooms();
    }

    @GetMapping("/reservation/{reservationId}")
    public List<Room> getRoomsByReservationId(@PathVariable int reservationId) {
        return reservationRoomService.getRoomsByReservationId(reservationId);
    }

    @GetMapping("/room/{roomId}")
    public List<Integer> getReservationIdsByRoomId(@PathVariable int roomId) {
        return reservationRoomService.getReservationIdsByRoomId(roomId);
    }

    @PostMapping
    public ResponseEntity<String> assignRoomToReservation(@RequestBody ReservationRoom reservationRoom) {
        boolean isAssigned = reservationRoomService.assignRoomToReservation(reservationRoom);
        if (isAssigned) {
            return ResponseEntity.status(201).body("Room assigned to reservation successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to assign room to reservation.");
        }
    }

    @DeleteMapping("/reservation/{reservationId}/room/{roomId}")
    public ResponseEntity<String> removeRoomFromReservation(@PathVariable int reservationId, @PathVariable int roomId) {
        boolean isRemoved = reservationRoomService.removeRoomFromReservation(reservationId, roomId);
        if (isRemoved) {
            return ResponseEntity.ok("Room removed from reservation successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to remove room from reservation.");
        }
    }
}
