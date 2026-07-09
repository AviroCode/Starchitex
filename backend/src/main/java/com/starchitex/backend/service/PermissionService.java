package com.starchitex.backend.service;

import com.starchitex.backend.model.Permission;
import com.starchitex.backend.repository.PermissionRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PermissionService {

    private final PermissionRepository permissionRepository;

    public PermissionService(PermissionRepository permissionRepository) {
        this.permissionRepository = permissionRepository;
    }

    public List<Permission> getAllPermissions() {
        return permissionRepository.findAll();
    }

    public Optional<Permission> getPermissionById(int id) {
        return permissionRepository.findById(id);
    }

    public boolean createPermission(Permission permission) {
        return permissionRepository.save(permission) > 0;
    }

    public boolean updatePermission(Permission permission) {
        return permissionRepository.update(permission) > 0;
    }
}
