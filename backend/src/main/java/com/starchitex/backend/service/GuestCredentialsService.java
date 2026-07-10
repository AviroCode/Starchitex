package com.starchitex.backend.service;

import com.starchitex.backend.model.GuestCredentials;
import com.starchitex.backend.repository.GuestCredentialsRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class GuestCredentialsService {

    private final GuestCredentialsRepository guestCredentialsRepository;

    public GuestCredentialsService(GuestCredentialsRepository guestCredentialsRepository) {
        this.guestCredentialsRepository = guestCredentialsRepository;
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
        return guestCredentialsRepository.save(credentials) > 0;
    }

    public boolean updatePassword(int guestCredId, String newPasswordHash) {
        return guestCredentialsRepository.updatePassword(guestCredId, newPasswordHash) > 0;
    }

    public boolean updateLastLogin(int guestCredId, LocalDateTime lastLogin) {
        return guestCredentialsRepository.updateLastLogin(guestCredId, lastLogin) > 0;
    }
}
