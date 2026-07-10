package com.starchitex.backend.security;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;

import java.util.Collection;

public class CustomUserDetails extends User {
    private final Integer branchId;
    private final Integer guestId;

    public CustomUserDetails(String username, String password, Collection<? extends GrantedAuthority> authorities, Integer branchId, Integer guestId) {
        super(username, password, authorities);
        this.branchId = branchId;
        this.guestId = guestId;
    }

    public Integer getBranchId() {
        return branchId;
    }

    public Integer getGuestId() {
        return guestId;
    }
}
