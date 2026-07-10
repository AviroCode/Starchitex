package com.starchitex.backend.controller;

import com.starchitex.backend.model.RoomMaintenance;
import com.starchitex.backend.service.RoomMaintenanceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/room-maintenances")
public class RoomMaintenanceController {

    private final RoomMaintenanceService roomMaintenanceService;

    public RoomMaintenanceController(RoomMaintenanceService roomMaintenanceService) {
        this.roomMaintenanceService = roomMaintenanceService;
    }

    @GetMapping
    public List<RoomMaintenance> getAllMaintenanceTickets() {
        return roomMaintenanceService.getAllMaintenanceTickets();
    }

    @GetMapping("/{roomMaintenanceId}")
    public ResponseEntity<RoomMaintenance> getMaintenanceTicketById(@PathVariable int roomMaintenanceId) {
        return roomMaintenanceService.getMaintenanceTicketById(roomMaintenanceId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/room/{roomId}")
    public List<RoomMaintenance> getMaintenanceTicketsByRoomId(@PathVariable int roomId) {
        return roomMaintenanceService.getMaintenanceTicketsByRoomId(roomId);
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping
    public ResponseEntity<String> createMaintenanceTicket(@RequestBody RoomMaintenance maintenance) {
        boolean isCreated = roomMaintenanceService.createMaintenanceTicket(maintenance);
        if (isCreated) {
            return ResponseEntity.status(201).body("Room maintenance ticket created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create room maintenance ticket.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PutMapping("/{roomMaintenanceId}")
    public ResponseEntity<String> updateMaintenanceTicket(@PathVariable int roomMaintenanceId, @RequestBody RoomMaintenance maintenance) {
        RoomMaintenance maintenanceToUpdate = new RoomMaintenance(
                roomMaintenanceId,
                maintenance.roomId(),
                maintenance.reportedBy(),
                maintenance.assignedEmployeeId(),
                maintenance.reportDate(),
                maintenance.priority(),
                maintenance.completionDate(),
                maintenance.description(),
                maintenance.status()
        );

        boolean isUpdated = roomMaintenanceService.updateMaintenanceTicket(maintenanceToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Room maintenance ticket updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update room maintenance ticket. Check if ID exists.");
        }
    }
}
