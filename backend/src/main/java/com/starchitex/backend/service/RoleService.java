package com.starchitex.backend.service;

import com.starchitex.backend.model.Role;
import com.starchitex.backend.repository.RoleRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class RoleService {

    private final RoleRepository roleRepository;

    public RoleService(RoleRepository roleRepository) {
        this.roleRepository = roleRepository;
    }

    public List<Role> getAllRoles() {
        return roleRepository.findAll();
    }

    public Optional<Role> getRoleById(int id) {
        return roleRepository.findById(id);
    }

    public boolean createRole(Role role) {
        return roleRepository.save(role) > 0;
    }

    public boolean updateRole(Role role) {
        return roleRepository.update(role) > 0;
    }
}
