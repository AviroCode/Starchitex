package com.starchitex.backend.controller;

import com.starchitex.backend.model.ServiceRequest;
import com.starchitex.backend.service.ServiceRequestService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/service-requests")
public class ServiceRequestController {

    private final ServiceRequestService serviceRequestService;

    public ServiceRequestController(ServiceRequestService serviceRequestService) {
        this.serviceRequestService = serviceRequestService;
    }

    @GetMapping
    public List<ServiceRequest> getAllServiceRequests() {
        return serviceRequestService.getAllServiceRequests();
    }

    @GetMapping("/{requestId}")
    public ResponseEntity<ServiceRequest> getServiceRequestById(@PathVariable int requestId) {
        return serviceRequestService.getServiceRequestById(requestId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/reservation/{reservationId}")
    public List<ServiceRequest> getServiceRequestsByReservationId(@PathVariable int reservationId) {
        return serviceRequestService.getServiceRequestsByReservationId(reservationId);
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping
    public ResponseEntity<String> createServiceRequest(@RequestBody ServiceRequest request) {
        boolean isCreated = serviceRequestService.createServiceRequest(request);
        if (isCreated) {
            return ResponseEntity.status(201).body("Service request created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create service request.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PutMapping("/{requestId}")
    public ResponseEntity<String> updateServiceRequest(@PathVariable int requestId, @RequestBody ServiceRequest request) {
        ServiceRequest requestToUpdate = new ServiceRequest(
                requestId,
                request.reservationId(),
                request.serviceId(),
                request.description(),
                request.requestDate(),
                request.status(),
                request.handledBy()
        );

        boolean isUpdated = serviceRequestService.updateServiceRequest(requestToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Service request updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update service request. Check if ID exists.");
        }
    }
}
