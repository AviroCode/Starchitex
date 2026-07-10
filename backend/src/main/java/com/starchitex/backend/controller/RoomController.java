package com.starchitex.backend.controller;

import com.starchitex.backend.model.Room;
import com.starchitex.backend.service.RoomService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/rooms")
public class RoomController {

    private final RoomService roomService;

    public RoomController(RoomService roomService) {
        this.roomService = roomService;
    }

    @GetMapping
    public List<Room> getAllRooms() {
        return roomService.getAllRooms();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Room> getRoomById(@PathVariable int id) {
        return roomService.getRoomById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/branch/{branchId}")
    public List<Room> getRoomsByBranchId(@PathVariable int branchId) {
        return roomService.getRoomsByBranchId(branchId);
    }

    @PreAuthorize("hasAuthority('ADMIN') or #room.branchId() == authentication.principal.branchId")
    @PostMapping
    public ResponseEntity<String> createRoom(@RequestBody Room room) {
        boolean isCreated = roomService.createRoom(room);
        if (isCreated) {
            return ResponseEntity.status(201).body("Room created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create room.");
        }
    }

    @PreAuthorize("hasAuthority('ADMIN') or #room.branchId() == authentication.principal.branchId")
    @PutMapping("/{id}")
    public ResponseEntity<String> updateRoom(@PathVariable int id, @RequestBody Room room) {
        Room roomToUpdate = new Room(
                id,
                room.roomNumber(),
                room.floor(),
                room.branchId(),
                room.roomTypeId()
        );

        boolean isUpdated = roomService.updateRoom(roomToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Room updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update room. Check if ID exists.");
        }
    }
}
