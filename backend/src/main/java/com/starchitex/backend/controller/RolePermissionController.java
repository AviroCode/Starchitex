package com.starchitex.backend.controller;

import com.starchitex.backend.model.Permission;
import com.starchitex.backend.model.Role;
import com.starchitex.backend.model.RolePermission;
import com.starchitex.backend.service.RolePermissionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/role-permissions")
public class RolePermissionController {

    private final RolePermissionService rolePermissionService;

    public RolePermissionController(RolePermissionService rolePermissionService) {
        this.rolePermissionService = rolePermissionService;
    }

    @GetMapping
    public List<RolePermission> getAllRolePermissions() {
        return rolePermissionService.getAllRolePermissions();
    }

    @GetMapping("/role/{roleId}")
    public List<Permission> getPermissionsByRoleId(@PathVariable int roleId) {
        return rolePermissionService.getPermissionsByRoleId(roleId);
    }

    @GetMapping("/permission/{permissionId}")
    public List<Role> getRolesByPermissionId(@PathVariable int permissionId) {
        return rolePermissionService.getRolesByPermissionId(permissionId);
    }

    @PostMapping
    public ResponseEntity<String> assignPermissionToRole(@RequestBody RolePermission rolePermission) {
        boolean isAssigned = rolePermissionService.assignPermissionToRole(rolePermission);
        if (isAssigned) {
            return ResponseEntity.status(201).body("Permission assigned to role successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to assign permission to role.");
        }
    }

    @DeleteMapping("/role/{roleId}/permission/{permissionId}")
    public ResponseEntity<String> revokePermissionFromRole(@PathVariable int roleId, @PathVariable int permissionId) {
        boolean isRevoked = rolePermissionService.revokePermissionFromRole(roleId, permissionId);
        if (isRevoked) {
            return ResponseEntity.ok("Permission revoked from role successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to revoke permission from role.");
        }
    }
}
