package com.starchitex.backend.controller;

import com.starchitex.backend.model.FacilityTask;
import com.starchitex.backend.service.FacilityTaskService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/facility-tasks")
public class FacilityTaskController {

    private final FacilityTaskService facilityTaskService;

    public FacilityTaskController(FacilityTaskService facilityTaskService) {
        this.facilityTaskService = facilityTaskService;
    }

    @GetMapping
    public List<FacilityTask> getAllTasks() {
        return facilityTaskService.getAllTasks();
    }

    @GetMapping("/{facilitytaskId}")
    public ResponseEntity<FacilityTask> getTaskById(@PathVariable int facilitytaskId) {
        return facilityTaskService.getTaskById(facilitytaskId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/facility/{facilityId}")
    public List<FacilityTask> getTasksByFacilityId(@PathVariable int facilityId) {
        return facilityTaskService.getTasksByFacilityId(facilityId);
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping
    public ResponseEntity<String> createTask(@RequestBody FacilityTask task) {
        boolean isCreated = facilityTaskService.createTask(task);
        if (isCreated) {
            return ResponseEntity.status(201).body("Facility task created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create facility task.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PutMapping("/{facilitytaskId}")
    public ResponseEntity<String> updateTask(@PathVariable int facilitytaskId, @RequestBody FacilityTask task) {
        FacilityTask taskToUpdate = new FacilityTask(
                facilitytaskId,
                task.facilityId(),
                task.assignedEmployeeId(),
                task.description(),
                task.assignedTime(),
                task.completedTime(),
                task.status()
        );

        boolean isUpdated = facilityTaskService.updateTask(taskToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Facility task updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update facility task. Check if ID exists.");
        }
    }
}
