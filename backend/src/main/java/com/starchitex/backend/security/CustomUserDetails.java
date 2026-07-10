package com.starchitex.backend.security;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;

import java.util.Collection;

public class CustomUserDetails extends User {
    private final Integer branchId;
    private final Integer guestId;
    private final Integer employeeId;

    public CustomUserDetails(String username, String password, Collection<? extends GrantedAuthority> authorities, Integer branchId, Integer guestId, Integer employeeId) {
        super(username, password, authorities);
        this.branchId = branchId;
        this.guestId = guestId;
        this.employeeId = employeeId;
    }

    public Integer getBranchId() {
        return branchId;
    }

    public Integer getGuestId() {
        return guestId;
    }

    public Integer getEmployeeId() {
        return employeeId;
    }
}
