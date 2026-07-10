package com.starchitex.backend.controller;

import com.starchitex.backend.model.Facility;
import com.starchitex.backend.service.FacilityService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/facilities")
public class FacilityController {

    private final FacilityService facilityService;

    public FacilityController(FacilityService facilityService) {
        this.facilityService = facilityService;
    }

    @GetMapping
    public List<Facility> getAllFacilities() {
        return facilityService.getAllFacilities();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Facility> getFacilityById(@PathVariable int id) {
        return facilityService.getFacilityById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/branch/{branchId}")
    public List<Facility> getFacilitiesByBranchId(@PathVariable int branchId) {
        return facilityService.getFacilitiesByBranchId(branchId);
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping
    public ResponseEntity<String> createFacility(@RequestBody Facility facility) {
        boolean isCreated = facilityService.createFacility(facility);
        if (isCreated) {
            return ResponseEntity.status(201).body("Facility created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create facility.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PutMapping("/{id}")
    public ResponseEntity<String> updateFacility(@PathVariable int id, @RequestBody Facility facility) {
        Facility facilityToUpdate = new Facility(
                id,
                facility.branchId(),
                facility.facilityName(),
                facility.description(),
                facility.capacity(),
                facility.location()
        );

        boolean isUpdated = facilityService.updateFacility(facilityToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Facility updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update facility. Check if ID exists.");
        }
    }
}
