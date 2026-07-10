package com.starchitex.backend.controller;

import com.starchitex.backend.model.RoomAvailability;
import com.starchitex.backend.service.RoomAvailabilityService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/room-availabilities")
public class RoomAvailabilityController {

    private final RoomAvailabilityService roomAvailabilityService;

    public RoomAvailabilityController(RoomAvailabilityService roomAvailabilityService) {
        this.roomAvailabilityService = roomAvailabilityService;
    }

    @GetMapping
    public List<RoomAvailability> getAllAvailabilities() {
        return roomAvailabilityService.getAllAvailabilities();
    }

    @GetMapping("/{availabilityId}")
    public ResponseEntity<RoomAvailability> getAvailabilityById(@PathVariable int availabilityId) {
        return roomAvailabilityService.getAvailabilityById(availabilityId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/room/{roomId}")
    public List<RoomAvailability> getAvailabilitiesByRoomId(@PathVariable int roomId) {
        return roomAvailabilityService.getAvailabilitiesByRoomId(roomId);
    }

    @PostMapping
    public ResponseEntity<String> createAvailability(@RequestBody RoomAvailability availability) {
        boolean isCreated = roomAvailabilityService.createAvailability(availability);
        if (isCreated) {
            return ResponseEntity.status(201).body("Room availability created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create room availability.");
        }
    }

    @PutMapping("/{availabilityId}")
    public ResponseEntity<String> updateAvailability(@PathVariable int availabilityId, @RequestBody RoomAvailability availability) {
        RoomAvailability availabilityToUpdate = new RoomAvailability(
                availabilityId,
                availability.roomId(),
                availability.calendarDate(),
                availability.status(),
                availability.reservationId(),
                availability.priceOverride()
        );

        boolean isUpdated = roomAvailabilityService.updateAvailability(availabilityToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Room availability updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update room availability. Check if ID exists.");
        }
    }
}
