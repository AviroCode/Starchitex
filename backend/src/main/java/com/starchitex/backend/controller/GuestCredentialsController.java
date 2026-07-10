package com.starchitex.backend.controller;

import com.starchitex.backend.model.GuestCredentials;
import com.starchitex.backend.service.GuestCredentialsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/guest-credentials")
public class GuestCredentialsController {

    private final GuestCredentialsService guestCredentialsService;

    public GuestCredentialsController(GuestCredentialsService guestCredentialsService) {
        this.guestCredentialsService = guestCredentialsService;
    }

    // NOTE: these endpoints key off guestCredId (the credentials row), not guestId,
    // so a clean "self or admin" check would need an extra DB lookup to resolve
    // guestCredId -> guestId for comparison against authentication.principal.guestId.
    // Restricted to admin-only for now; wiring guest self-service password change
    // is a follow-up (see Documentation.md).
    @PreAuthorize("hasAnyRole('System Administrator')")
    @GetMapping
    public List<GuestCredentials> getAllCredentials() {
        return guestCredentialsService.getAllCredentials();
    }

    @PreAuthorize("hasAnyRole('System Administrator')")
    @GetMapping("/{guestCredId}")
    public ResponseEntity<GuestCredentials> getCredentialsById(@PathVariable int guestCredId) {
        return guestCredentialsService.getCredentialsById(guestCredId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PreAuthorize("hasAnyRole('System Administrator') or #guestId == authentication.principal.guestId")
    @GetMapping("/guest/{guestId}")
    public ResponseEntity<GuestCredentials> getCredentialsByGuestId(@PathVariable int guestId) {
        return guestCredentialsService.getCredentialsByGuestId(guestId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PreAuthorize("hasAnyRole('System Administrator')")
    @PostMapping
    public ResponseEntity<String> createCredentials(@RequestBody GuestCredentials credentials) {
        boolean isCreated = guestCredentialsService.createCredentials(credentials);
        if (isCreated) {
            return ResponseEntity.status(201).body("Credentials created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create credentials.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator')")
    @PutMapping("/{guestCredId}/password")
    public ResponseEntity<String> updatePassword(@PathVariable int guestCredId, @RequestBody String newPasswordHash) {
        boolean isUpdated = guestCredentialsService.updatePassword(guestCredId, newPasswordHash);
        if (isUpdated) {
            return ResponseEntity.ok("Password updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update password.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator')")
    @PutMapping("/{guestCredId}/login")
    public ResponseEntity<String> recordLogin(@PathVariable int guestCredId) {
        boolean isUpdated = guestCredentialsService.updateLastLogin(guestCredId, LocalDateTime.now());
        if (isUpdated) {
            return ResponseEntity.ok("Login time recorded successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to record login time.");
        }
    }
}
