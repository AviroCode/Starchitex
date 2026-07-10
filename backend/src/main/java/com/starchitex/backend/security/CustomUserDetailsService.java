package com.starchitex.backend.security;

import com.starchitex.backend.model.EmployeeCredentials;
import com.starchitex.backend.model.GuestCredentials;
import com.starchitex.backend.model.Permission;
import com.starchitex.backend.repository.EmployeeCredentialsRepository;
import com.starchitex.backend.repository.GuestCredentialsRepository;
import com.starchitex.backend.repository.RolePermissionRepository;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    private final EmployeeCredentialsRepository employeeRepo;
    private final GuestCredentialsRepository guestRepo;
    private final RolePermissionRepository rolePermissionRepo;

    public CustomUserDetailsService(EmployeeCredentialsRepository employeeRepo, GuestCredentialsRepository guestRepo, RolePermissionRepository rolePermissionRepo) {
        this.employeeRepo = employeeRepo;
        this.guestRepo = guestRepo;
        this.rolePermissionRepo = rolePermissionRepo;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // 1. Try finding an employee
        Optional<EmployeeCredentials> employeeOpt = employeeRepo.findByUsername(username);
        if (employeeOpt.isPresent()) {
            EmployeeCredentials emp = employeeOpt.get();
            return new User(emp.username(), emp.passwordHash(), getAuthorities(emp.roleId()));
        }

        // 2. If no employee, try finding a guest
        Optional<GuestCredentials> guestOpt = guestRepo.findByUsername(username);
        if (guestOpt.isPresent()) {
            GuestCredentials guest = guestOpt.get();
            return new User(guest.username(), guest.passwordHash(), getAuthorities(guest.roleId()));
        }

        throw new UsernameNotFoundException("User not found with username: " + username);
    }

    private Collection<? extends GrantedAuthority> getAuthorities(int roleId) {
        List<Permission> permissions = rolePermissionRepo.findPermissionsByRoleId(roleId);
        return permissions.stream()
                .map(p -> new SimpleGrantedAuthority(p.permissionName()))
                .collect(Collectors.toList());
    }
}
