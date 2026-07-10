package com.starchitex.backend.controller;

import com.starchitex.backend.model.RoomTask;
import com.starchitex.backend.service.RoomTaskService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/room-tasks")
public class RoomTaskController {

    private final RoomTaskService roomTaskService;

    public RoomTaskController(RoomTaskService roomTaskService) {
        this.roomTaskService = roomTaskService;
    }

    @GetMapping
    public List<RoomTask> getAllTasks() {
        return roomTaskService.getAllTasks();
    }

    @GetMapping("/{roomtaskId}")
    public ResponseEntity<RoomTask> getTaskById(@PathVariable int roomtaskId) {
        return roomTaskService.getTaskById(roomtaskId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/room/{roomId}")
    public List<RoomTask> getTasksByRoomId(@PathVariable int roomId) {
        return roomTaskService.getTasksByRoomId(roomId);
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping
    public ResponseEntity<String> createTask(@RequestBody RoomTask task) {
        boolean isCreated = roomTaskService.createTask(task);
        if (isCreated) {
            return ResponseEntity.status(201).body("Room task created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create room task.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PutMapping("/{roomtaskId}")
    public ResponseEntity<String> updateTask(@PathVariable int roomtaskId, @RequestBody RoomTask task) {
        RoomTask taskToUpdate = new RoomTask(
                roomtaskId,
                task.roomId(),
                task.assignedEmployeeId(),
                task.description(),
                task.assignedTime(),
                task.completedTime(),
                task.status()
        );

        boolean isUpdated = roomTaskService.updateTask(taskToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Room task updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update room task. Check if ID exists.");
        }
    }
}
