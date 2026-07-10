package com.starchitex.backend.service;

import com.starchitex.backend.model.Permission;
import com.starchitex.backend.model.Role;
import com.starchitex.backend.model.RolePermission;
import com.starchitex.backend.repository.RolePermissionRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RolePermissionService {

    private final RolePermissionRepository rolePermissionRepository;

    public RolePermissionService(RolePermissionRepository rolePermissionRepository) {
        this.rolePermissionRepository = rolePermissionRepository;
    }

    public List<RolePermission> getAllRolePermissions() {
        return rolePermissionRepository.findAll();
    }

    public List<Permission> getPermissionsByRoleId(int roleId) {
        return rolePermissionRepository.findPermissionsByRoleId(roleId);
    }

    public List<Role> getRolesByPermissionId(int permissionId) {
        return rolePermissionRepository.findRolesByPermissionId(permissionId);
    }

    public boolean assignPermissionToRole(RolePermission rolePermission) {
        return rolePermissionRepository.save(rolePermission) > 0;
    }

    public boolean revokePermissionFromRole(int roleId, int permissionId) {
        return rolePermissionRepository.delete(roleId, permissionId) > 0;
    }
}
