package com.starchitex.backend.controller;

import com.starchitex.backend.model.Service;
import com.starchitex.backend.service.ServiceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/services")
public class ServiceController {

    private final ServiceService serviceService;

    public ServiceController(ServiceService serviceService) {
        this.serviceService = serviceService;
    }

    @GetMapping
    public List<Service> getAllServices() {
        return serviceService.getAllServices();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Service> getServiceById(@PathVariable int id) {
        return serviceService.getServiceById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<String> createService(@RequestBody Service service) {
        boolean isCreated = serviceService.createService(service);
        if (isCreated) {
            return ResponseEntity.status(201).body("Service created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create service.");
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<String> updateService(@PathVariable int id, @RequestBody Service service) {
        Service serviceToUpdate = new Service(
                id,
                service.serviceName(),
                service.category(),
                service.price(),
                service.description()
        );

        boolean isUpdated = serviceService.updateService(serviceToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Service updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update service. Check if ID exists.");
        }
    }
}
