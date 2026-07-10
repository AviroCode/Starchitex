package com.starchitex.backend.security;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;

import java.util.Collection;

public class CustomUserDetails extends User {
    private final Integer branchId;

    public CustomUserDetails(String username, String password, Collection<? extends GrantedAuthority> authorities, Integer branchId) {
        super(username, password, authorities);
        this.branchId = branchId;
    }

    public Integer getBranchId() {
        return branchId;
    }
}
