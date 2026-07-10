package com.starchitex.backend.controller;

import com.starchitex.backend.model.FacilityMaintenance;
import com.starchitex.backend.service.FacilityMaintenanceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/facility-maintenances")
public class FacilityMaintenanceController {

    private final FacilityMaintenanceService facilityMaintenanceService;

    public FacilityMaintenanceController(FacilityMaintenanceService facilityMaintenanceService) {
        this.facilityMaintenanceService = facilityMaintenanceService;
    }

    @GetMapping
    public List<FacilityMaintenance> getAllMaintenanceTickets() {
        return facilityMaintenanceService.getAllMaintenanceTickets();
    }

    @GetMapping("/{facilityMaintenanceId}")
    public ResponseEntity<FacilityMaintenance> getMaintenanceTicketById(@PathVariable int facilityMaintenanceId) {
        return facilityMaintenanceService.getMaintenanceTicketById(facilityMaintenanceId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/facility/{facilityId}")
    public List<FacilityMaintenance> getMaintenanceTicketsByFacilityId(@PathVariable int facilityId) {
        return facilityMaintenanceService.getMaintenanceTicketsByFacilityId(facilityId);
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping
    public ResponseEntity<String> createMaintenanceTicket(@RequestBody FacilityMaintenance maintenance) {
        boolean isCreated = facilityMaintenanceService.createMaintenanceTicket(maintenance);
        if (isCreated) {
            return ResponseEntity.status(201).body("Facility maintenance ticket created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create facility maintenance ticket.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PutMapping("/{facilityMaintenanceId}")
    public ResponseEntity<String> updateMaintenanceTicket(@PathVariable int facilityMaintenanceId, @RequestBody FacilityMaintenance maintenance) {
        FacilityMaintenance maintenanceToUpdate = new FacilityMaintenance(
                facilityMaintenanceId,
                maintenance.facilityId(),
                maintenance.reportedBy(),
                maintenance.assignedEmployeeId(),
                maintenance.reportDate(),
                maintenance.priority(),
                maintenance.completionDate(),
                maintenance.description(),
                maintenance.status()
        );

        boolean isUpdated = facilityMaintenanceService.updateMaintenanceTicket(maintenanceToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Facility maintenance ticket updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update facility maintenance ticket. Check if ID exists.");
        }
    }
}
