package com.starchitex.backend.controller;

import com.starchitex.backend.model.Permission;
import com.starchitex.backend.service.PermissionService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/permissions")
public class PermissionController {

    private final PermissionService permissionService;

    public PermissionController(PermissionService permissionService) {
        this.permissionService = permissionService;
    }

    @GetMapping
    public List<Permission> getAllPermissions() {
        return permissionService.getAllPermissions();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Permission> getPermissionById(@PathVariable int id) {
        return permissionService.getPermissionById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PreAuthorize("hasAnyRole('System Administrator')")
    @PostMapping
    public ResponseEntity<String> createPermission(@RequestBody Permission permission) {
        boolean isCreated = permissionService.createPermission(permission);
        if (isCreated) {
            return ResponseEntity.status(201).body("Permission created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create permission.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator')")
    @PutMapping("/{id}")
    public ResponseEntity<String> updatePermission(@PathVariable int id, @RequestBody Permission permission) {
        Permission permissionToUpdate = new Permission(
                id,
                permission.permissionName(),
                permission.description()
        );

        boolean isUpdated = permissionService.updatePermission(permissionToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Permission updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update permission. Check if ID exists.");
        }
    }
}
