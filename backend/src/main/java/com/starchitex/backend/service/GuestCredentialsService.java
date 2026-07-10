package com.starchitex.backend.service;

import com.starchitex.backend.model.GuestCredentials;
import com.starchitex.backend.repository.GuestCredentialsRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class GuestCredentialsService {

    private final GuestCredentialsRepository guestCredentialsRepository;
    private final PasswordEncoder passwordEncoder;

    public GuestCredentialsService(GuestCredentialsRepository guestCredentialsRepository, PasswordEncoder passwordEncoder) {
        this.guestCredentialsRepository = guestCredentialsRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public List<GuestCredentials> getAllCredentials() {
        return guestCredentialsRepository.findAll();
    }

    public Optional<GuestCredentials> getCredentialsById(int guestCredId) {
        return guestCredentialsRepository.findById(guestCredId);
    }
    
    public Optional<GuestCredentials> getCredentialsByGuestId(int guestId) {
        return guestCredentialsRepository.findByGuestId(guestId);
    }

    public Optional<GuestCredentials> getCredentialsByUsername(String username) {
        return guestCredentialsRepository.findByUsername(username);
    }

    public boolean createCredentials(GuestCredentials credentials) {
        String hashed = passwordEncoder.encode(credentials.passwordHash());
        GuestCredentials securedCreds = new GuestCredentials(
                credentials.guestCredId(),
                credentials.guestId(),
                credentials.username(),
                hashed,
                credentials.roleId(),
                credentials.createdAt(),
                credentials.lastLogin()
        );
        return guestCredentialsRepository.save(securedCreds) > 0;
    }

    public boolean updatePassword(int guestCredId, String newPassword) {
        String hashed = passwordEncoder.encode(newPassword);
        return guestCredentialsRepository.updatePassword(guestCredId, hashed) > 0;
    }

    public boolean updateLastLogin(int guestCredId, LocalDateTime lastLogin) {
        return guestCredentialsRepository.updateLastLogin(guestCredId, lastLogin) > 0;
    }
}
