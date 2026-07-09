package com.starchitex.backend.controller;

import com.starchitex.backend.model.RoomType;
import com.starchitex.backend.service.RoomTypeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/room-types")
public class RoomTypeController {

    private final RoomTypeService roomTypeService;

    public RoomTypeController(RoomTypeService roomTypeService) {
        this.roomTypeService = roomTypeService;
    }

    @GetMapping
    public List<RoomType> getAllRoomTypes() {
        return roomTypeService.getAllRoomTypes();
    }

    @GetMapping("/{id}")
    public ResponseEntity<RoomType> getRoomTypeById(@PathVariable int id) {
        return roomTypeService.getRoomTypeById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<String> createRoomType(@RequestBody RoomType roomType) {
        boolean isCreated = roomTypeService.createRoomType(roomType);
        if (isCreated) {
            return ResponseEntity.status(201).body("Room type created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create room type.");
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<String> updateRoomType(@PathVariable int id, @RequestBody RoomType roomType) {
        RoomType roomTypeToUpdate = new RoomType(
                id,
                roomType.typeName(),
                roomType.description(),
                roomType.basePrice(),
                roomType.capacity()
        );

        boolean isUpdated = roomTypeService.updateRoomType(roomTypeToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Room type updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update room type. Check if ID exists.");
        }
    }
}
