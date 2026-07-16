package com.starchitex.backend.controller;

import com.starchitex.backend.model.Role;
import com.starchitex.backend.service.RoleService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/roles")
public class RoleController {

    private final RoleService roleService;

    public RoleController(RoleService roleService) {
        this.roleService = roleService;
    }

    @GetMapping
    public List<Role> getAllRoles() {
        return roleService.getAllRoles();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Role> getRoleById(@PathVariable int id) {
        return roleService.getRoleById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PreAuthorize("hasAnyRole('System Administrator')")
    @PostMapping
    public ResponseEntity<String> createRole(@RequestBody Role role) {
        boolean isCreated = roleService.createRole(role);
        if (isCreated) {
            return ResponseEntity.status(201).body("Role created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create role.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator')")
    @PutMapping("/{id}")
    public ResponseEntity<String> updateRole(@PathVariable int id, @RequestBody Role role) {
        Role roleToUpdate = new Role(
                id,
                role.roleName(),
                role.description()
        );

        boolean isUpdated = roleService.updateRole(roleToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Role updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update role. Check if ID exists.");
        }
    }
}
